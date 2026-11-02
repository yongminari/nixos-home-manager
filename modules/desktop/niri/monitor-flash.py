"""Niri 모니터 전환 효과. --demo로 효과를 비교할 수 있습니다."""

from io import BytesIO
import json
import os
from pathlib import Path
import subprocess
import sys
import threading

import cairo
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, Gio, GLib, Gtk, Gtk4LayerShell as LayerShell
from OpenGL import GL
from OpenGL.GL.shaders import compileProgram, compileShader
from PIL import Image, ImageOps


DURATION_US = 1_000_000
EFFECTS = ("screen-ripple", "splatter", "fire", "aurora")
SHADER_DIR = Path(__file__).with_name("monitor-effects")

VERTEX_SHADER = """#version 300 es
void main() {
    vec2 p = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
}
"""


class EffectArea(Gtk.GLArea):
    """A transparent, short-lived GPU effect; no frame loop remains when idle."""

    def __init__(self, effect, on_error):
        super().__init__()
        self.effect = effect
        self.on_error = on_error
        self.progress = 0.0
        self.program = None
        self.vao = None
        # GTK uses GLES on NVIDIA too; sharing a desktop GL context can fail.
        self.set_allowed_apis(Gdk.GLAPI.GLES)
        self.set_required_version(3, 0)
        self.set_auto_render(False)
        self.set_can_target(False)
        self.connect("realize", self.setup)
        self.connect("unrealize", self.cleanup)
        self.connect("render", self.render_effect)

    def setup(self, _area):
        self.make_current()
        if self.get_error() is not None:
            self.on_error(self.get_error())
            return
        try:
            source = (SHADER_DIR / "common.glsl").read_text() + "\n"
            source += (SHADER_DIR / f"{self.effect}.glsl").read_text()
            self.vao = GL.glGenVertexArrays(1)
            GL.glBindVertexArray(self.vao)
            self.program = compileProgram(
                compileShader(VERTEX_SHADER, GL.GL_VERTEX_SHADER),
                compileShader(source, GL.GL_FRAGMENT_SHADER),
            )
            self.resolution_location = GL.glGetUniformLocation(self.program, "resolution")
            self.progress_location = GL.glGetUniformLocation(self.program, "progress")
        except Exception as error:
            self.on_error(error)
        finally:
            GL.glBindVertexArray(0)

    def cleanup(self, _area):
        self.make_current()
        if self.get_error() is None:
            if self.program is not None:
                GL.glDeleteProgram(self.program)
            if self.vao is not None:
                GL.glDeleteVertexArrays(1, [self.vao])
        self.program = self.vao = None

    def render_effect(self, _area, _context):
        if self.program is None:
            return True
        try:
            # GTK owns the framebuffer and viewport, including fractional scaling.
            viewport = GL.glGetIntegerv(GL.GL_VIEWPORT)
            GL.glDisable(GL.GL_DEPTH_TEST)
            GL.glDisable(GL.GL_BLEND)
            GL.glClearColor(0, 0, 0, 0)
            GL.glClear(GL.GL_COLOR_BUFFER_BIT)
            GL.glUseProgram(self.program)
            GL.glUniform2f(self.resolution_location, float(viewport[2]), float(viewport[3]))
            GL.glUniform1f(self.progress_location, self.progress)
            GL.glBindVertexArray(self.vao)
            GL.glDrawArrays(GL.GL_TRIANGLES, 0, 3)
            GL.glBindVertexArray(0)
            GL.glUseProgram(0)
        except Exception as error:
            self.on_error(error)
        return True


class ImageEffectArea(EffectArea):
    def __init__(self, picture, shader, on_error, direction=(0, 0), texture_limit=4096):
        super().__init__("image", on_error)
        self.picture = picture
        self.shader = shader
        self.texture_limit = texture_limit
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
                compileShader(self.shader.read_text(),
                              GL.GL_FRAGMENT_SHADER),
            )
            self.resolution_location = GL.glGetUniformLocation(self.program, "resolution")
            self.progress_location = GL.glGetUniformLocation(self.program, "progress")
            with Image.open(self.picture) as source:
                picture = ImageOps.exif_transpose(source).convert("RGBA")
                limit = min(self.texture_limit, int(GL.glGetIntegerv(GL.GL_MAX_TEXTURE_SIZE)))
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
    duration_us = DURATION_US

    def __init__(self, effect, preview=None, demo=False):
        super().__init__(application_id="local.niri.MonitorFlash", flags=Gio.ApplicationFlags.NON_UNIQUE)
        self.tracker = FocusTracker()
        self.window = None
        self.reader = None
        self.failed = False
        self.preview = preview
        self.effect = effect
        self.demo = demo
        self.capture_sequence = 0
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
            self.preview_effects = iter(EFFECTS if self.demo else (self.effect,))
            self.next_preview()
            return
        self.reader = subprocess.Popen(
            ["niri", "msg", "--json", "event-stream"], stdout=subprocess.PIPE, text=True
        )
        threading.Thread(target=self.read_events, daemon=True).start()

    def next_preview(self):
        effect = next(self.preview_effects, None)
        if effect is None or self.failed:
            self.quit()
        else:
            print(f"Preview: {effect}", flush=True)
            self.flash(self.preview, effect)
            # Capture is asynchronous; its preview timer starts after it arrives.
            if effect != "screen-ripple":
                GLib.timeout_add(self.duration_us // 1000 + 650, self.next_preview)
        return GLib.SOURCE_REMOVE

    def render_failed(self, error):
        if not self.failed:
            print(f"monitor-flash: rendering failed: {error}", file=sys.stderr)
        self.failed = True
        # Destroy outside GLArea's realize/render signal.
        GLib.idle_add(self.quit)

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
        self.capture_sequence += 1
        if self.window is not None:
            self.window.destroy()
            self.window = None
        if self.reader is not None:
            self.reader.terminate()
            self.reader.wait(timeout=2)

    def handle_event(self, event):
        output = self.tracker.update(event)
        if output is not None:
            self.flash(output)
        return GLib.SOURCE_REMOVE

    def flash(self, output, effect=None):
        effect = effect or self.effect
        self.capture_sequence += 1
        sequence = self.capture_sequence
        if self.window is not None:
            self.window.destroy()
            self.window = None
        self.duration_us = 1_400_000 if effect == "screen-ripple" else DURATION_US
        if effect == "screen-ripple":
            # Let the compositor remove our old overlay before taking a new image.
            GLib.timeout_add(50, self.capture_screen, output, sequence)
        else:
            self.show_effect(output, effect)

    def capture_screen(self, output, sequence):
        if sequence != self.capture_sequence:
            return GLib.SOURCE_REMOVE

        def capture():
            try:
                # PPM avoids PNG compression latency. No file or cursor is captured.
                picture = subprocess.check_output(
                    ["grim", "-t", "ppm", "-o", output, "-"],
                    stderr=subprocess.PIPE, timeout=2,
                )
                GLib.idle_add(self.capture_ready, output, sequence, picture, None)
            except (OSError, subprocess.SubprocessError) as error:
                GLib.idle_add(self.capture_ready, output, sequence, None, str(error))

        threading.Thread(target=capture, daemon=True).start()
        return GLib.SOURCE_REMOVE

    def capture_ready(self, output, sequence, picture, error):
        # A newer focus change wins even if an older capture finishes last.
        if sequence != self.capture_sequence:
            return GLib.SOURCE_REMOVE
        if error is not None:
            if self.preview is not None:
                self.render_failed(error)
            else:
                print(f"monitor-flash: skipping screen capture: {error}", file=sys.stderr)
            return GLib.SOURCE_REMOVE
        self.show_effect(output, "screen-ripple", BytesIO(picture))
        if self.preview is not None:
            GLib.timeout_add(self.duration_us // 1000 + 650, self.next_preview)
        return GLib.SOURCE_REMOVE

    def show_effect(self, output, effect, picture=None):
        monitors = Gdk.Display.get_default().get_monitors()
        monitor = next(
            (m for i in range(monitors.get_n_items())
             if (m := monitors.get_item(i)).get_connector() == output), None
        )
        if monitor is None:
            if self.preview is not None:
                self.render_failed(f"output not found: {output}")
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
        # Anchor all four sides so the shader covers the newly focused monitor.
        for edge in (LayerShell.Edge.TOP, LayerShell.Edge.BOTTOM, LayerShell.Edge.LEFT, LayerShell.Edge.RIGHT):
            LayerShell.set_anchor(window, edge, True)
        # 입력 영역을 비워 뒤쪽 창으로 마우스 입력이 그대로 전달되게 합니다.
        window.connect("realize", lambda w: w.get_surface().set_input_region(cairo.Region()))
        if effect == "screen-ripple":
            area = ImageEffectArea(picture, Path(__file__).with_name("wallpaper-ripple.glsl"),
                                   self.render_failed, texture_limit=16384)
        else:
            area = EffectArea(effect, self.render_failed)
        window.set_child(area)
        state = {"start": None}
        duration_us = self.duration_us

        def tick(_area, clock):
            now = clock.get_frame_time()
            if state["start"] is None:
                state["start"] = now
            progress = (now - state["start"]) / duration_us
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
    # 현재 화면에서 비교: niri-monitor-flash --demo
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--effect", choices=EFFECTS,
                        default=os.environ.get("NIRI_MONITOR_EFFECT", "screen-ripple"))
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--preview", nargs="?", const="", metavar="OUTPUT",
                      help="효과를 한 번 표시 (출력 생략 시 현재 모니터)")
    mode.add_argument("--demo", action="store_true", help="현재 모니터에서 모든 효과를 순서대로 표시")
    args = parser.parse_args()
    if args.demo or args.preview == "":
        try:
            output = json.loads(subprocess.check_output(
                ["niri", "msg", "--json", "focused-output"], text=True
            ))
            args.preview = output["name"]
        except (subprocess.CalledProcessError, ValueError, KeyError, TypeError) as error:
            parser.exit(1, f"현재 모니터를 확인할 수 없습니다: {error}\n")
    app = MonitorFlash(args.effect, args.preview, args.demo)
    status = app.run([sys.argv[0]])
    sys.exit(1 if app.failed else status)
