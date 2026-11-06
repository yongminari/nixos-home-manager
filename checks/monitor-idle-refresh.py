"""Exercise DPMS ordering and restoration without touching real displays."""

import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


source = Path(sys.argv.pop(1))
spec = importlib.util.spec_from_file_location("idle_refresh", source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class RefreshTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.modes = [dict(width=5120, height=2160, refresh_rate=r)
                      for r in (60000, 100000, 120000)]
        self.current = 2
        self.calls = []
        self.fail_mode = False
        self.controller = module.IdleRefresh(
            self.temporary.name, "session-A", "DP-10", "unused", wake_delay=0)
        self.controller.msg = self.msg

    def msg(self, *args):
        if args == ("--json", "outputs"):
            return json.dumps({"DP-10": dict(name="DP-10", modes=self.modes,
                                            current_mode=self.current)})
        self.calls.append(args)
        if args[0] == "output":
            if self.fail_mode:
                raise RuntimeError("mode rejected")
            mode = args[-1]
            self.current = next(i for i, m in enumerate(self.modes)
                                if self.controller.mode_name(m) == mode)
        return ""

    def test_activity_before_off_restores_original_without_dpms(self):
        self.current = 1
        self.controller.prepare()
        self.controller.prepare()  # Must not overwrite the saved 100 Hz mode.
        self.controller.resume()
        self.controller.off()  # A delayed timeout after activity is ignored.
        self.assertEqual(self.current, 1)
        self.assertFalse(any(c[0] == "action" for c in self.calls))
        self.assertFalse(self.controller.state_path.exists())

    def test_wake_before_restore_and_duplicate_resume(self):
        self.controller.prepare()
        self.controller.off()
        self.controller.resume()
        self.controller.resume()
        self.assertEqual(self.calls, [
            ("output", "DP-10", "mode", "5120x2160@60.000"),
            ("action", "power-off-monitors"),
            ("action", "power-on-monitors"),
            ("output", "DP-10", "mode", "5120x2160@120.000"),
        ])

    def test_off_is_ignored_while_waking(self):
        self.controller.prepare()
        self.controller.off()
        self.controller.wake_delay = 6
        with patch.object(module.time, "sleep", side_effect=lambda _: self.controller.off()) as sleep:
            self.controller.resume()
        self.assertGreater(sleep.call_args.args[0], 5)
        self.assertEqual(self.calls.count(("action", "power-off-monitors")), 1)

    def test_mode_failure_prevents_power_off(self):
        self.fail_mode = True
        with self.assertRaises(RuntimeError):
            self.controller.prepare()
        with self.assertRaises(RuntimeError):
            self.controller.off()
        self.assertNotIn(("action", "power-off-monitors"), self.calls)

    def test_user_mode_change_is_preserved(self):
        self.controller.prepare()
        self.current = 1
        self.controller.resume()
        self.assertEqual(self.current, 1)

    def test_stale_session_state_is_discarded(self):
        self.controller.prepare()
        self.controller.session = "session-B"
        self.controller.resume()
        self.assertEqual(self.current, 0)
        self.assertFalse(self.controller.state_path.exists())

    def test_missing_low_mode_does_not_enable_dpms(self):
        self.modes = self.modes[1:]
        self.current = 1
        with self.assertRaises(RuntimeError):
            self.controller.prepare()
        self.controller.off()
        self.assertEqual(self.calls, [])

    def test_already_low_refresh_stays_low(self):
        self.current = 0
        self.controller.prepare()
        self.controller.off()
        self.controller.resume()
        self.assertEqual(self.current, 0)
        self.assertFalse(any(c[0] == "output" for c in self.calls))


unittest.main()
