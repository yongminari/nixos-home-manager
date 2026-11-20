import importlib.util
import json
import os
from pathlib import Path
import sys
import tempfile
import threading
from concurrent.futures import ThreadPoolExecutor
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("adaptive_close", sys.argv.pop(1))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PrepareCloseTest(unittest.TestCase):
    def setUp(self):
        self.target = {"id": 7, "is_floating": False,
                       "layout": {"window_size": [1000, 800]}}
        self.floating = {"id": 7, "is_floating": True, "is_focused": True, "workspace_id": 1,
                         "layout": {"window_size": [900, 720]}}
        self.actions = []
        self.snapshots = []

    def niri(self, *args):
        if args == ("windows",):
            return json.dumps(self.snapshots.pop(0))
        self.actions.append(args)
        return "null"

    def prepare(self):
        with patch.object(module, "niri", side_effect=self.niri), \
                patch.object(module.time, "sleep"):
            return module.prepare_close(self.target)

    def test_focus_change_does_not_redirect_actions(self):
        other = {"id": 99, "is_focused": True}
        self.snapshots = [[other, self.floating]]
        self.assertTrue(self.prepare())
        self.assertTrue(all(action[2:4] == ("--id", "7") for action in self.actions))

    def test_disappearing_window_aborts_before_centering(self):
        self.snapshots = [[]]
        self.assertFalse(self.prepare())
        self.assertFalse(any(action[1] == "center-window" for action in self.actions))

    def test_disappearing_window_during_animation_aborts_close(self):
        self.snapshots = [[]]
        with patch.object(module, "niri", side_effect=self.niri):
            module.hand_off_focus(self.target)
        self.assertEqual(self.actions, [])

    def test_focus_handoff_only_when_a_tile_is_available(self):
        for focused, workspace, handoff in [(True, 1, True), (True, 2, False), (False, 1, False)]:
            self.floating["is_focused"] = focused
            self.snapshots = [[self.floating, {"id": 8, "is_floating": False, "workspace_id": workspace}]]
            self.actions.clear()
            with patch.object(module, "niri", side_effect=self.niri):
                module.hand_off_focus(self.target)
            expected = [("action", "focus-tiling")] if handoff else []
            self.assertEqual(self.actions, expected)

    def test_existing_floating_window_is_not_toggled_or_shrunk_again(self):
        self.target = self.floating
        self.assertTrue(self.prepare())
        self.assertEqual(self.actions, [])

    def test_minimum_size_does_not_wait_forever(self):
        self.floating["layout"]["window_size"] = [1000, 800]
        self.snapshots = [[self.floating]]
        with patch.object(module.time, "monotonic", side_effect=[0, 0.13]):
            self.assertTrue(self.prepare())
        self.assertEqual(self.actions[-1][1], "center-window")

    def test_ready_window_hands_off_without_waiting_for_preview(self):
        self.snapshots = [[self.floating]]
        with patch.object(module, "niri", side_effect=self.niri), \
                patch.object(module.time, "sleep") as sleep:
            self.assertTrue(module.prepare_close(self.target))
        sleep.assert_not_called()


class OverlappingCloseTest(unittest.TestCase):
    def test_second_close_runs_before_first_animation_finishes(self):
        windows = [
            {"id": i, "workspace_id": 1, "is_focused": i == 1, "is_floating": False}
            for i in (1, 2)
        ]
        closed = []
        first_animating = threading.Event()
        finish_animation = threading.Event()

        def ipc(*args):
            if args == ("windows",):
                return json.dumps(windows)
            if args == ("action", "focus-tiling"):
                for w in windows:
                    w["is_focused"] = not w["is_floating"]
            else:
                self.assertEqual(args[:3], ("action", "close-window", "--id"))
                window_id = int(args[3])
                closed.append(window_id)
                windows.remove(next(w for w in windows if w["id"] == window_id))

        def prepare(target):
            next(w for w in windows if w["id"] == target["id"])["is_floating"] = True
            return True

        def sleep(seconds):
            if seconds == 0.65 and not first_animating.is_set():
                first_animating.set()
                self.assertTrue(finish_animation.wait(5))

        with tempfile.TemporaryDirectory() as tmp:
            template = Path(tmp) / "template"
            template.write_text("@SIDE@")
            with patch.dict(os.environ, XDG_RUNTIME_DIR=tmp, XDG_CONFIG_HOME=tmp), \
                    patch.object(sys, "argv", ["close", str(template)]), \
                    patch.object(module, "niri", side_effect=ipc), \
                    patch.object(module, "prepare_close", side_effect=prepare), \
                    patch.object(module.time, "sleep", side_effect=sleep), \
                    patch.object(module, "load_shader") as shader, ThreadPoolExecutor(2) as pool:
                first = pool.submit(module.main)
                try:
                    self.assertTrue(first_animating.wait(3))
                    pool.submit(module.main).result(timeout=3)
                    self.assertEqual(closed, [1, 2])
                    self.assertEqual(shader.call_count, 1)
                finally:
                    finish_animation.set()
                first.result(timeout=3)
                self.assertEqual(shader.call_count, 2)


unittest.main()
