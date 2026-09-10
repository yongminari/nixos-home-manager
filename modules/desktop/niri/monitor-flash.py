"""Niri 모니터 포커스가 바뀔 때 입력을 가로채지 않는 테두리 빛을 표시합니다."""

import json
import math
import subprocess
import sys
import threading

import cairo
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, Gio, GLib, Gtk, Gtk4LayerShell as LayerShell


DURATION_US = 1_000_000
EDGE_WIDTH = 360
COLOR = (0.38, 0.85, 1.0)
PEAK_ALPHA = 0.48


class FocusTracker:
    """초기 상태는 기억만 하고 실제 출력 변경에만 반응합니다."""

    def __init__(self):
        self.workspaces = {}
        self.output = None

    def update(self, event):
        output = None
        if "WorkspacesChanged" in event:
            workspaces = event["WorkspacesChanged"]["workspaces"]
            self.workspaces = {w["id"]: w.get("output") for w in workspaces}
            output = next((w.get("output") for w in workspaces if w["is_focused"]), None)
        elif "WorkspaceActivated" in event:
            activation = event["WorkspaceActivated"]
            if activation["focused"]:
                output = self.workspaces.get(activation["id"])
        if output is None:
            return None
        previous, self.output = self.output, output
        return output if previous is not None and previous != output else None


class MonitorFlash(Gtk.Application):
    def __init__(self, preview=None):
        super().__init__(application_id="local.niri.MonitorFlash", flags=Gio.ApplicationFlags.NON_UNIQUE)
        self.tracker = FocusTracker()
        self.window = None
        self.reader = None
        self.failed = False
        self.preview = preview
        self.connect("activate", self.activate_flash)
        self.connect("shutdown", self.stop_reader)

    def activate_flash(self, _app):
        self.hold()
        css = Gtk.CssProvider()
        css.load_from_data(b"window.monitor-flash { background: transparent; box-shadow: none; }")
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        if self.preview is not None:
            self.flash(self.preview)
            GLib.timeout_add(DURATION_US // 1000 + 300, lambda: (self.quit(), GLib.SOURCE_REMOVE)[1])
            return
        self.reader = subprocess.Popen(
            ["niri", "msg", "--json", "event-stream"], stdout=subprocess.PIPE, text=True
        )
        threading.Thread(target=self.read_events, daemon=True).start()

    def read_events(self):
        try:
            for line in self.reader.stdout:
                GLib.idle_add(self.handle_event, json.loads(line))
        except (ValueError, OSError) as error:
            print(f"monitor-flash: {error}", file=sys.stderr)
        GLib.idle_add(self.stream_closed)

    def stream_closed(self):
        self.failed = True
        self.quit()
        return GLib.SOURCE_REMOVE

    def stop_reader(self, _app):
        if self.reader is not None:
            self.reader.terminate()
            self.reader.wait(timeout=2)

    def handle_event(self, event):
        output = self.tracker.update(event)
        if output is not None:
            self.flash(output)
        return GLib.SOURCE_REMOVE

    def flash(self, output):
        monitors = Gdk.Display.get_default().get_monitors()
        monitor = next(
            (m for i in range(monitors.get_n_items())
             if (m := monitors.get_item(i)).get_connector() == output), None
        )
        if monitor is None:
            return
        if self.window is not None:
            self.window.destroy()

        window = Gtk.Window(application=self)
        self.window = window
        window.add_css_class("monitor-flash")
        window.set_can_focus(False)
        LayerShell.init_for_window(window)
        LayerShell.set_namespace(window, "niri-monitor-flash")
        LayerShell.set_monitor(window, monitor)
        LayerShell.set_layer(window, LayerShell.Layer.OVERLAY)
        LayerShell.set_keyboard_mode(window, LayerShell.KeyboardMode.NONE)
        LayerShell.set_exclusive_zone(window, -1)
        for edge in (LayerShell.Edge.TOP, LayerShell.Edge.BOTTOM, LayerShell.Edge.LEFT, LayerShell.Edge.RIGHT):
            LayerShell.set_anchor(window, edge, True)
        # 입력 영역을 비워 뒤쪽 창으로 마우스 입력이 그대로 전달되게 합니다.
        window.connect("realize", lambda w: w.get_surface().set_input_region(cairo.Region()))
        area = Gtk.DrawingArea()
        area.set_can_target(False)
        window.set_child(area)
        state = {"start": None, "alpha": 0.0}

        def draw(_area, cr, width, height):
            # 이전 프레임을 지워 반투명한 빛이 누적되지 않게 합니다.
            cr.save()
            cr.set_operator(cairo.OPERATOR_CLEAR)
            cr.paint()
            cr.restore()
            # 단색 선 없이 가장자리에서 안쪽으로 부드럽게 빛을 퍼뜨립니다.
            for x0, y0, x1, y1, rect in (
                (0, 0, EDGE_WIDTH, 0, (0, 0, EDGE_WIDTH, height)),
                (width, 0, width - EDGE_WIDTH, 0, (width - EDGE_WIDTH, 0, EDGE_WIDTH, height)),
                (0, 0, 0, EDGE_WIDTH, (0, 0, width, EDGE_WIDTH)),
                (0, height, 0, height - EDGE_WIDTH, (0, height - EDGE_WIDTH, width, EDGE_WIDTH)),
            ):
                gradient = cairo.LinearGradient(x0, y0, x1, y1)
                for offset, strength in ((0, 1), (0.2, 0.65), (0.5, 0.2), (0.8, 0.025), (1, 0)):
                    gradient.add_color_stop_rgba(offset, *COLOR, state["alpha"] * strength)
                cr.set_source(gradient)
                cr.rectangle(*rect)
                cr.fill()

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
            state["alpha"] = PEAK_ALPHA * math.sin(math.pi * progress) ** 2
            area.queue_draw()
            return GLib.SOURCE_CONTINUE

        area.set_draw_func(draw)
        area.add_tick_callback(tick)
        window.present()


if __name__ == "__main__":
    # 수동 확인: niri-monitor-flash --preview DP-1
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--preview", metavar="OUTPUT", help="선택한 출력에 효과를 한 번 표시")
    args = parser.parse_args()
    app = MonitorFlash(args.preview)
    status = app.run([sys.argv[0]])
    sys.exit(1 if app.failed else status)
