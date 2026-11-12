import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("sync", sys.argv.pop(1))
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


def outputs(*names):
    return {"WorkspacesChanged": {"workspaces": [{"output": name} for name in names]}}


class WallpaperSyncTest(unittest.TestCase):
    def test_reconnect_and_workspace_changes(self):
        with patch.object(sync, "sync_output") as apply:
            active = sync.handle_event(outputs("DP-1", "DP-1", None), set())
            apply.assert_called_once_with("DP-1")
            apply.reset_mock()
            active = sync.handle_event(outputs("DP-1", "DP-1"), active)
            active = sync.handle_event({"WorkspaceActivated": {}}, active)
            apply.assert_not_called()
            active = sync.handle_event(outputs("DP-1", "HDMI-A-2"), active)
            apply.assert_called_once_with("HDMI-A-2")
            apply.reset_mock()
            active = sync.handle_event(outputs("DP-1"), active)
            sync.handle_event(outputs("DP-1", "HDMI-A-2"), active)
            apply.assert_called_once_with("HDMI-A-2")

    def test_current_default_replaces_stale_monitor_path(self):
        with tempfile.TemporaryDirectory() as directory:
            wallpaper = Path(directory) / "current wallpaper.jpg"
            wallpaper.touch()
            with patch.object(sync, "noctalia", side_effect=[str(wallpaper), "/missing.jpg", "ok"]) as ipc:
                sync.sync_output("HDMI-A-2")
                self.assertEqual(ipc.call_args.args, ("wallpaper-set", "HDMI-A-2", str(wallpaper)))

    def test_waits_for_noctalia_and_skips_matching_wallpaper(self):
        with tempfile.NamedTemporaryFile() as wallpaper:
            with patch.object(sync, "noctalia", side_effect=[RuntimeError("not ready"), wallpaper.name, wallpaper.name]) as ipc:
                with patch.object(sync.time, "sleep"):
                    sync.sync_output("HDMI-A-2")
                self.assertFalse(any(c.args[0] == "wallpaper-set" for c in ipc.call_args_list))

    def test_missing_default_is_never_applied(self):
        with patch.object(sync, "noctalia", return_value="/nonexistent-wallpaper") as ipc:
            with patch.object(sync.time, "sleep"):
                with self.assertRaises(RuntimeError):
                    sync.sync_output("HDMI-A-2")
            self.assertTrue(all(c.args == ("wallpaper-get",) for c in ipc.call_args_list))


unittest.main()
