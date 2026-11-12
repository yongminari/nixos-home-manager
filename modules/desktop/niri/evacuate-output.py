"""Move populated workspaces before disabling an output, preserving their layout."""

import json
import os
import socket
import sys


def request(message):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(5)
        connection.connect(os.environ["NIRI_SOCKET"])
        connection.sendall((json.dumps(message) + "\n").encode())
        with connection.makefile("r") as stream:
            reply = json.loads(stream.readline())
    if "Err" in reply:
        raise RuntimeError(reply["Err"])
    return reply["Ok"]


def populated_workspaces(output):
    workspaces = request("Workspaces")["Workspaces"]
    occupied = {window["workspace_id"] for window in request("Windows")["Windows"]}
    return sorted(
        (workspace for workspace in workspaces
         if workspace["output"] == output and workspace["id"] in occupied),
        key=lambda workspace: workspace["idx"],
    )


def evacuate(source, destination):
    workspaces = populated_workspaces(source)
    active = next((workspace["id"] for workspace in workspaces if workspace["is_active"]), None)
    # IPC supports stable IDs, while CLI numeric references are changing indices.
    for workspace in workspaces:
        request({"Action": {"MoveWorkspaceToMonitor": {
            "output": destination, "reference": {"Id": workspace["id"]},
        }}})

    remaining = populated_workspaces(source)
    current = {workspace["id"]: workspace["output"]
               for workspace in request("Workspaces")["Workspaces"]}
    if remaining or any(current.get(workspace["id"]) != destination for workspace in workspaces):
        raise RuntimeError("Workspace migration was incomplete; keeping the output enabled")
    if active is not None:
        request({"Action": {"FocusWorkspace": {"reference": {"Id": active}}}})


if __name__ == "__main__":
    try:
        evacuate(*sys.argv[1:])
    except (OSError, ValueError, KeyError, RuntimeError) as error:
        print(f"Could not evacuate output: {error}", file=sys.stderr)
        sys.exit(1)
