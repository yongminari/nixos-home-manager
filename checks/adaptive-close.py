import importlib.util
import json
import sys
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("adaptive_close", sys.argv.pop(1))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PrepareCloseTest(unittest.TestCase):
    def setUp(self):
        self.target = {"id": 7, "is_floating": False,
                       "layout": {"window_size": [1000, 800]}}
        self.floating = {"id": 7, "is_floating": True,
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
        self.snapshots = [[other, self.floating], [other, self.floating]]
        self.assertTrue(self.prepare())
        self.assertTrue(all(action[2:4] == ("--id", "7") for action in self.actions))

    def test_disappearing_window_aborts_before_centering(self):
        self.snapshots = [[]]
        self.assertFalse(self.prepare())
        self.assertFalse(any(action[1] == "center-window" for action in self.actions))

    def test_disappearing_window_during_animation_aborts_close(self):
        self.snapshots = [[self.floating], []]
        self.assertFalse(self.prepare())

    def test_existing_floating_window_is_not_toggled_or_shrunk_again(self):
        self.target = self.floating
        self.assertTrue(self.prepare())
        self.assertEqual(self.actions, [])

    def test_minimum_size_does_not_wait_forever(self):
        self.floating["layout"]["window_size"] = [1000, 800]
        self.snapshots = [[self.floating], [self.floating]]
        with patch.object(module.time, "monotonic", side_effect=[0, 0.13]):
            self.assertTrue(self.prepare())
        self.assertEqual(self.actions[-1][1], "center-window")

    def test_ready_window_has_no_animation_delay(self):
        self.snapshots = [[self.floating], [self.floating]]
        with patch.object(module, "niri", side_effect=self.niri), \
                patch.object(module.time, "sleep") as sleep:
            self.assertTrue(module.prepare_close(self.target))
        sleep.assert_not_called()


unittest.main()
