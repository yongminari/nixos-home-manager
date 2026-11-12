import importlib.util
import sys
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("evacuate", sys.argv.pop(1))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class EvacuateTest(unittest.TestCase):
    def setUp(self):
        self.workspaces = [
            {"id": 7, "idx": 1, "output": "source", "is_active": False},
            {"id": 9, "idx": 2, "output": "source", "is_active": True},
            {"id": 10, "idx": 3, "output": "source", "is_active": False},
            {"id": 20, "idx": 1, "output": "destination", "is_active": True},
        ]
        self.windows = [{"workspace_id": 7, "is_floating": False},
                        {"workspace_id": 9, "is_floating": True}]
        self.actions = []

    def request(self, message):
        if message == "Workspaces":
            return {"Workspaces": self.workspaces}
        if message == "Windows":
            return {"Windows": self.windows}
        action = message["Action"]
        self.actions.append(action)
        if "MoveWorkspaceToMonitor" in action:
            move = action["MoveWorkspaceToMonitor"]
            for workspace in self.workspaces:
                if workspace["id"] == move["reference"]["Id"]:
                    workspace["output"] = move["output"]
                # Simulate changing indices after each migration.
                workspace["idx"] += 1
        return "Handled"

    def test_moves_tiled_and_floating_workspaces_by_id_and_focuses_active(self):
        with patch.object(module, "request", side_effect=self.request):
            module.evacuate("source", "destination")
        moved = [action["MoveWorkspaceToMonitor"]["reference"]["Id"]
                 for action in self.actions if "MoveWorkspaceToMonitor" in action]
        self.assertEqual(moved, [7, 9])
        self.assertEqual(self.actions[-1], {"FocusWorkspace": {"reference": {"Id": 9}}})
        self.assertEqual(self.workspaces[2]["output"], "source")

    def test_empty_output_does_not_change_workspace_focus(self):
        self.windows = []
        with patch.object(module, "request", side_effect=self.request):
            module.evacuate("source", "destination")
        self.assertEqual(self.actions, [])

    def test_unmoved_windows_abort(self):
        def ignored_action(message):
            return self.request(message) if isinstance(message, str) else "Handled"
        with patch.object(module, "request", side_effect=ignored_action):
            with self.assertRaises(RuntimeError):
                module.evacuate("source", "destination")


unittest.main()
