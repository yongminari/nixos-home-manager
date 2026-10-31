"""워크스페이스·활성 열 전환 시 Noctalia 배경을 짧게 휘었다가 복원합니다."""

import argparse
import json
from pathlib import Path
import subprocess
import sys

import cairo
from PIL import Image, ImageOps
from monitor_flash import (
    EffectArea, MonitorFlash, VERTEX_SHADER, Gdk, Gio, GLib, Gtk, LayerShell,
    GL, compileProgram, compileShader,
)

DURATION_US = 950_000


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


class WarpArea(EffectArea):
    def __init__(self, wallpaper, direction, on_error):
        super().__init__("warp", on_error)
        self.wallpaper = wallpaper
        self.direction = direction
        self.texture = None

    def setup(self, _area):
        self.make_current()
        if self.get_error() is not None:
            self.on_error(self.get_error())
            return
        try:
            self.vao = GL.glGenVertexArrays(1)
            GL.glBindVertexArray(self.vao)
            self.program = compileProgram(
                compileShader(VERTEX_SHADER, GL.GL_VERTEX_SHADER),
                compileShader(Path(__file__).with_name("workspace-warp.glsl").read_text(),
                              GL.GL_FRAGMENT_SHADER),
            )
            self.resolution_location = GL.glGetUniformLocation(self.program, "resolution")
            self.progress_location = GL.glGetUniformLocation(self.program, "progress")
            with Image.open(self.wallpaper) as source:
                picture = ImageOps.exif_transpose(source).convert("RGBA")
                limit = min(4096, int(GL.glGetIntegerv(GL.GL_MAX_TEXTURE_SIZE)))
                picture.thumbnail((limit, limit))
                width, height = picture.size
                pixels = picture.tobytes()
            self.texture = GL.glGenTextures(1)
            GL.glActiveTexture(GL.GL_TEXTURE0)
            GL.glBindTexture(GL.GL_TEXTURE_2D, self.texture)
            for setting in (GL.GL_TEXTURE_MIN_FILTER, GL.GL_TEXTURE_MAG_FILTER):
                GL.glTexParameteri(GL.GL_TEXTURE_2D, setting, GL.GL_LINEAR)
            for setting in (GL.GL_TEXTURE_WRAP_S, GL.GL_TEXTURE_WRAP_T):
                GL.glTexParameteri(GL.GL_TEXTURE_2D, setting, GL.GL_CLAMP_TO_EDGE)
            GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, GL.GL_RGBA, width, height,
                            0, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, pixels)
            GL.glUseProgram(self.program)
            GL.glUniform1i(GL.glGetUniformLocation(self.program, "wallpaper"), 0)
            GL.glUniform2f(GL.glGetUniformLocation(self.program, "image_size"), width, height)
            GL.glUniform2f(GL.glGetUniformLocation(self.program, "direction"), *self.direction)
            GL.glUseProgram(0)
        except Exception as error:
            self.on_error(error)
        finally:
            GL.glBindVertexArray(0)

    def render_effect(self, area, context):
        if self.texture is not None:
            GL.glActiveTexture(GL.GL_TEXTURE0)
            GL.glBindTexture(GL.GL_TEXTURE_2D, self.texture)
        return super().render_effect(area, context)

    def cleanup(self, area):
        self.make_current()
        if self.get_error() is None and self.texture is not None:
            GL.glDeleteTextures([self.texture])
        self.texture = None
        super().cleanup(area)


class WorkspaceWarp(MonitorFlash):
    def __init__(self, preview=None, direction=(0, -1)):
        super().__init__("warp", preview=preview)
        self.set_application_id("local.niri.WorkspaceWarp")
        self.tracker = WorkspaceTracker()
        self.direction = direction

    def handle_event(self, event):
        transition = self.tracker.update(event)
        if transition is not None:
            output, self.direction = transition
            self.flash(output)
        return GLib.SOURCE_REMOVE

    def flash(self, output, effect=None):
        monitors = Gdk.Display.get_default().get_monitors()
        monitor = next((m for m in monitors if m.get_connector() == output), None)
        if monitor is None:
            return
        try:
            wallpaper = subprocess.check_output(
                ["noctalia", "msg", "wallpaper-get", output], text=True, timeout=1
            ).strip()
            if not Path(wallpaper).is_file():
                raise ValueError("Noctalia did not return a wallpaper file")
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"workspace-warp: skipping transition: {error}", file=sys.stderr)
            return
        if self.window is not None:
            self.window.destroy()
        window = Gtk.Window(application=self)
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
        area = WarpArea(wallpaper, self.direction, self.render_failed)
        window.set_child(area)
        state = {"start": None}

        def tick(_area, clock):
            now = clock.get_frame_time()
            if state["start"] is None:
                state["start"] = now
            progress = (now - state["start"]) / DURATION_US
            if progress >= 1:
                window.destroy()
                if self.window is window:
                    self.window = None
                return GLib.SOURCE_REMOVE
            area.progress = progress
            area.queue_render()
            return GLib.SOURCE_CONTINUE

        area.add_tick_callback(tick)
        window.present()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", action="store_true", help="현재 모니터에서 한 번 재생")
    parser.add_argument("--direction", choices=("up", "down", "left", "right"), default="up",
                        help="배경이 끌려가는 방향")
    args = parser.parse_args()
    output = None
    if args.preview:
        output = json.loads(subprocess.check_output(
            ["niri", "msg", "--json", "focused-output"], text=True))["name"]
    directions = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
    app = WorkspaceWarp(output, directions[args.direction])
    status = app.run([sys.argv[0]])
    sys.exit(1 if app.failed else status)
