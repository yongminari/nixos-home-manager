"""워크스페이스·활성 열 전환 시 배경을 휘고, 모니터 포커스 전환 시 파문을 표시합니다."""

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import threading

import cairo
from monitor_flash import (
    ImageEffectArea, FocusTracker, MonitorFlash, Gdk, Gio, GLib, Gtk, LayerShell,
)

DURATION_US = 950_000
RIPPLE_DURATION_US = 1_400_000


class WorkspaceTracker:
    """출력별 활성 워크스페이스를 추적하며 초기 상태/재배열은 무시합니다."""

    def __init__(self):
        self.workspaces = {}
        self.active = {}
        self.windows = {}
        self.new_windows = set()
        self.overview = False

    def update(self, event):
        if "WorkspacesChanged" in event:
            workspaces = event["WorkspacesChanged"]["workspaces"]
            self.workspaces = {w["id"]: w for w in workspaces}
            self.active = {w["output"]: w["id"] for w in workspaces
                           if w.get("output") and w["is_active"]}
            return None
        if "OverviewOpenedOrClosed" in event:
            self.overview = event["OverviewOpenedOrClosed"]["is_open"]
        if "WindowsChanged" in event:
            self.windows = {w["id"]: w for w in event["WindowsChanged"]["windows"]}
            self.new_windows.clear()
        if "WindowOpenedOrChanged" in event:
            window = event["WindowOpenedOrChanged"]["window"]
            if (window["id"] not in self.windows
                    and not any(w.get("active_window_id") == window["id"]
                                for w in self.workspaces.values())):
                self.new_windows.add(window["id"])
            self.windows[window["id"]] = window
        if "WindowClosed" in event:
            window_id = event["WindowClosed"]["id"]
            self.windows.pop(window_id, None)
            self.new_windows.discard(window_id)
        if "WindowLayoutsChanged" in event:
            for window_id, layout in event["WindowLayoutsChanged"]["changes"]:
                if window_id in self.windows:
                    self.windows[window_id]["layout"] = layout
        if "WorkspaceActiveWindowChanged" in event:
            change = event["WorkspaceActiveWindowChanged"]
            workspace = self.workspaces.get(change["workspace_id"])
            if workspace is None:
                return None
            previous = self.windows.get(workspace.get("active_window_id"))
            current_id = change["active_window_id"]
            current = self.windows.get(current_id)
            workspace["active_window_id"] = current_id
            is_new = current_id in self.new_windows
            self.new_windows.discard(current_id)
            output = workspace.get("output")
            if (self.overview or is_new or not previous or not current
                    or self.active.get(output) != workspace["id"]):
                return None
            # 같은 열의 상하 포커스·플로팅 창·다른 워크스페이스는 제외합니다.
            if any(w.get("is_floating") or w.get("workspace_id") != workspace["id"]
                   for w in (previous, current)):
                return None
            old_pos = previous.get("layout", {}).get("pos_in_scrolling_layout")
            new_pos = current.get("layout", {}).get("pos_in_scrolling_layout")
            if old_pos and new_pos and old_pos[0] != new_pos[0]:
                return output, (-1, 0) if new_pos[0] > old_pos[0] else (1, 0)
            return None
        activation = event.get("WorkspaceActivated")
        if activation is None:
            return None
        current = self.workspaces.get(activation["id"])
        if current is None or not current.get("output"):
            return None
        output = current["output"]
        previous = self.workspaces.get(self.active.get(output))
        self.active[output] = current["id"]
        if previous is None or previous["idx"] == current["idx"]:
            return None
        # 다음(아래) 워크스페이스 진입 시 화면 내용은 위로 이동합니다.
        return output, (0, -1) if current["idx"] > previous["idx"] else (0, 1)


class WorkspaceWarp(MonitorFlash):
    def __init__(self, preview=None, direction=(0, -1), effect="warp"):
        super().__init__(effect, preview=preview)
        self.set_application_id("local.niri.WorkspaceWarp")
        self.tracker = WorkspaceTracker()
        self.focus_tracker = FocusTracker()
        self.warp_enabled = os.environ.get("NIRI_WORKSPACE_WARP", "1") == "1"
        self.ripple_enabled = os.environ.get("NIRI_WALLPAPER_RIPPLE", "1") == "1"
        self.direction = direction
        self.horizontal_surfaces = {}
        self.wallpapers = {}
        self.refreshing = False
        self.refresh_again = False
        self.stopping = False
        self.refresh_timer = None
        self.settings_monitor = None

    def activate_flash(self, app):
        super().activate_flash(app)
        if self.preview is not None or not self.warp_enabled:
            return
        # Noctalia는 배경 변경을 settings.toml에 저장합니다. 디렉터리를 감시해
        # 원자적 파일 교체도 감지하고, 파일 덮어쓰기/알림 누락은 주기적으로 확인합니다.
        state_dir = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
        directory = Gio.File.new_for_path(str(state_dir / "noctalia"))
        try:
            self.settings_monitor = directory.monitor_directory(Gio.FileMonitorFlags.NONE, None)
            self.settings_monitor.connect("changed", self.settings_changed)
        except GLib.Error as error:
            print(f"workspace-warp: settings monitor unavailable: {error}", file=sys.stderr)
        self.refresh_timer = GLib.timeout_add_seconds(2, self.refresh_wallpapers)

    def settings_changed(self, _monitor, file, other, _event):
        if any(f is not None and f.get_basename() == "settings.toml" for f in (file, other)):
            self.refresh_wallpapers()

    def refresh_wallpapers(self):
        if self.stopping:
            return GLib.SOURCE_REMOVE
        if self.refreshing:
            self.refresh_again = True
            return GLib.SOURCE_CONTINUE
        self.refreshing = True
        outputs = tuple(self.tracker.active)

        def read():
            wallpapers = {}
            for output in outputs:
                try:
                    path = self.wallpaper_path(output)
                    stamp = Path(path).stat()
                    wallpapers[output] = (path, stamp.st_mtime_ns, stamp.st_size)
                except (OSError, ValueError, subprocess.SubprocessError):
                    wallpapers[output] = None
            GLib.idle_add(self.prepare_wallpapers, wallpapers)

        threading.Thread(target=read, daemon=True).start()
        return GLib.SOURCE_CONTINUE

    @staticmethod
    def wallpaper_path(output):
        path = subprocess.check_output(
            ["noctalia", "msg", "wallpaper-get", output], text=True, timeout=1
        ).strip()
        if not Path(path).is_file():
            raise ValueError("Noctalia did not return a wallpaper file")
        return path

    def prepare_wallpapers(self, wallpapers):
        self.refreshing = False
        if self.stopping:
            return GLib.SOURCE_REMOVE
        active = set(self.tracker.active)
        for key in list(self.horizontal_surfaces):
            if key[0] not in active or wallpapers.get(key[0]) != key[1:4]:
                self.horizontal_surfaces.pop(key)[0].destroy()
        for output in list(self.wallpapers):
            if output not in active or wallpapers.get(output) is None:
                del self.wallpapers[output]
        direction = self.direction
        for output, identity in wallpapers.items():
            if output not in active or identity is None:
                continue
            if self.wallpapers.get(output) != identity:
                self.wallpapers[output] = identity
                for self.direction in ((-1, 0), (1, 0)):
                    self.flash(output, "warp", prepare=True)
        self.direction = direction
        if self.refresh_again:
            self.refresh_again = False
            self.refresh_wallpapers()
        return GLib.SOURCE_REMOVE

    def handle_event(self, event):
        output = self.focus_tracker.update(event)
        transition = self.tracker.update(event)
        if "WorkspacesChanged" in event and self.warp_enabled:
            self.refresh_wallpapers()
        if output is not None and self.ripple_enabled and not self.tracker.overview:
            self.flash(output, "ripple")
        elif transition is not None and self.warp_enabled:
            output, self.direction = transition
            self.flash(output, "warp")
        return GLib.SOURCE_REMOVE

    def flash(self, output, effect=None, prepare=False):
        effect = effect or self.effect
        duration_us = RIPPLE_DURATION_US if effect == "ripple" else DURATION_US
        self.duration_us = duration_us
        monitors = Gdk.Display.get_default().get_monitors()
        monitor = next((m for m in monitors if m.get_connector() == output), None)
        if monitor is None:
            return
        horizontal = effect == "warp" and self.direction[0] != 0
        try:
            if horizontal and self.preview is None:
                identity = self.wallpapers.get(output)
                if identity is None:
                    self.refresh_wallpapers()
                    return
                wallpaper = identity[0]
            else:
                wallpaper = self.wallpaper_path(output)
                stamp = Path(wallpaper).stat()
                identity = (wallpaper, stamp.st_mtime_ns, stamp.st_size)
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"workspace-warp: skipping transition: {error}", file=sys.stderr)
            return
        cache_key = (output, *identity, self.direction)
        cached = self.horizontal_surfaces.get(cache_key) if horizontal else None
        if not prepare and self.window is not None:
            self.window.destroy()
            self.window = None
        # 준비된 좌우 효과는 투명한 상태로 보관해 이미지/GL 초기화를 반복하지 않습니다.
        for key, (saved_window, saved_area, saved_state) in list(self.horizontal_surfaces.items()):
            if prepare:
                continue
            saved_state["start"] = None
            saved_area.progress = 1.0
            saved_area.queue_render()
            if key[0] == output and key[1:4] != cache_key[1:4]:
                saved_window.destroy()
                del self.horizontal_surfaces[key]
        if cached is not None:
            window, area, state = cached
            state["start"] = None
            area.progress = 0.0
            if not state["running"]:
                state["running"] = True
                area.add_tick_callback(state["tick"])
            return
        window = Gtk.Window(application=self)
        if not horizontal:
            self.window = window
        window.add_css_class("monitor-flash")
        window.set_can_focus(False)
        LayerShell.init_for_window(window)
        LayerShell.set_namespace(window, "niri-workspace-warp")
        LayerShell.set_monitor(window, monitor)
        # Noctalia 배경 위, 일반 창과 패널 아래에만 그립니다.
        LayerShell.set_layer(window, LayerShell.Layer.BOTTOM)
        LayerShell.set_keyboard_mode(window, LayerShell.KeyboardMode.NONE)
        LayerShell.set_exclusive_zone(window, -1)
        for edge in (LayerShell.Edge.TOP, LayerShell.Edge.BOTTOM,
                     LayerShell.Edge.LEFT, LayerShell.Edge.RIGHT):
            LayerShell.set_anchor(window, edge, True)
        window.connect("realize", lambda w: w.get_surface().set_input_region(cairo.Region()))
        shader = "wallpaper-ripple.glsl" if effect == "ripple" else "workspace-warp.glsl"
        area = ImageEffectArea(wallpaper, Path(__file__).with_name(shader),
                               self.render_failed, self.direction)
        window.set_child(area)
        state = {"start": None, "running": not prepare}

        def tick(_area, clock):
            if area.progress >= 1.0:
                state["running"] = False
                return GLib.SOURCE_REMOVE
            now = clock.get_frame_time()
            if state["start"] is None:
                state["start"] = now
            progress = (now - state["start"]) / duration_us
            if progress >= 1:
                if horizontal:
                    area.progress = 1.0
                    area.queue_render()
                else:
                    window.destroy()
                state["running"] = False
                if self.window is window:
                    self.window = None
                return GLib.SOURCE_REMOVE
            area.progress = progress
            area.queue_render()
            return GLib.SOURCE_CONTINUE

        state["tick"] = tick
        if horizontal:
            self.horizontal_surfaces[cache_key] = (window, area, state)
        if prepare:
            area.progress = 1.0
        else:
            area.add_tick_callback(tick)
        window.present()

    def stop_reader(self, app):
        self.stopping = True
        if self.refresh_timer is not None:
            GLib.source_remove(self.refresh_timer)
        if self.settings_monitor is not None:
            self.settings_monitor.cancel()
        for window, _area, _state in self.horizontal_surfaces.values():
            window.destroy()
        self.horizontal_surfaces.clear()
        super().stop_reader(app)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", action="store_true", help="현재 모니터에서 한 번 재생")
    parser.add_argument("--effect", choices=("warp", "ripple"), default="warp",
                        help="미리 볼 배경 효과")
    parser.add_argument("--direction", choices=("up", "down", "left", "right"), default="up",
                        help="배경이 끌려가는 방향")
    args = parser.parse_args()
    output = None
    if args.preview:
        output = json.loads(subprocess.check_output(
            ["niri", "msg", "--json", "focused-output"], text=True))["name"]
    directions = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
    app = WorkspaceWarp(output, directions[args.direction], args.effect)
    status = app.run([sys.argv[0]])
    sys.exit(1 if app.failed else status)
