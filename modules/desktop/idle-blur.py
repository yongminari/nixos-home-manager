"""Click-through live blur; the service restores normal blur on every exit."""
import json
import os
import signal
import subprocess
from pathlib import Path

import cairo
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, GLib, Gtk, GtkLayerShell


def main():
    config_file = os.environ["NIRI_IDLE_BLUR_CONFIG"]
    target = os.environ["NIRI_IDLE_BLUR_TARGET"]
    outputs = json.loads(subprocess.check_output(
        ["niri", "msg", "--json", "outputs"], text=True, timeout=5))
    connector = next(o["name"] for o in outputs.values()
                     if target in (o["name"], " ".join(str(o.get(k) or "Unknown")
                                   for k in ("make", "model", "serial")))
                     and o["current_mode"] is not None)
    display = Gdk.Display.get_default()
    screen = Gdk.Screen.get_default()
    monitor = next(display.get_monitor(i) for i in range(display.get_n_monitors())
                   if screen.get_monitor_plug_name(i) == connector)
    window = Gtk.Window()
    GtkLayerShell.init_for_window(window)
    GtkLayerShell.set_monitor(window, monitor)
    GtkLayerShell.set_namespace(window, "niri-idle-blur")
    GtkLayerShell.set_layer(window, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_keyboard_mode(window, GtkLayerShell.KeyboardMode.NONE)
    GtkLayerShell.set_exclusive_zone(window, 0)
    for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM,
                 GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
        GtkLayerShell.set_anchor(window, edge, True)
    window.set_visual(screen.get_rgba_visual())
    css = Gtk.CssProvider()
    css.load_from_data(b"window { background-color: rgba(0,0,0,0.03); }")
    window.get_style_context().add_provider(css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def mapped(*_):
        window.get_window().input_shape_combine_region(cairo.Region(), 0, 0)
        print("idle-blur: visible", flush=True)

    window.connect("map-event", mapped)
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM,
                         lambda: (Gtk.main_quit(), False)[1])
    path = Path(config_file)
    temporary = path.with_suffix(".tmp")
    temporary.write_text("blur {\n    passes 1\n    offset 0.25\n}\n")
    temporary.replace(path)
    window.show_all()
    Gtk.main()
    window.destroy()


if __name__ == "__main__":
    main()
