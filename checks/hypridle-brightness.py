"""Exercise the real helper with a fake backlight, never the physical display."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

script = str(Path(sys.argv[1]).resolve())
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    device = root / "value"
    state = root / "hypridle-brightness"
    mock = root / "brightnessctl"
    mock.write_text("#!" + sys.executable + "\n" + """import os, pathlib, sys
r = pathlib.Path(os.environ['XDG_RUNTIME_DIR'])
p = r / 'value'
args = sys.argv[1:]
if (r / 'unavailable').exists(): sys.exit(1)
if 'info' in args: print('intel_backlight,backlight,' + p.read_text() + ',70%,400')
elif 'get' in args: print(p.read_text())
elif 'set' in args:
    if (r / 'fail').exists(): sys.exit(1)
    p.write_text(args[-1])
else: sys.exit(2)
""")
    mock.chmod(0o755)
    env = dict(os.environ, XDG_RUNTIME_DIR=directory,
               PATH=directory + os.pathsep + os.environ['PATH'])

    def run(action):
        subprocess.run(['bash', script, action], env=env, check=True)

    device.write_text('280')
    run('restore')  # No record: leave brightness alone.
    assert device.read_text() == '280'
    run('dim')
    assert device.read_text() == '40'
    original = state.read_text()
    run('dim')  # A new process must not overwrite the original value.
    assert state.read_text() == original
    run('restore')  # Also represents ExecStartPre after service restart.
    assert device.read_text() == '280' and not state.exists()

    run('dim')
    (root / 'fail').touch()
    run('restore')
    assert state.read_text() == original and device.read_text() == '40'
    (root / 'fail').unlink()
    run('restore')
    assert device.read_text() == '280' and not state.exists()

    run('dim')
    (root / 'unavailable').touch()
    run('restore')
    assert state.exists()
    (root / 'unavailable').unlink()
    run('restore')
    assert device.read_text() == '280' and not state.exists()

    run('dim')
    device.write_text('160')  # Respect a manual adjustment.
    run('restore')
    assert device.read_text() == '160' and not state.exists()

    device.write_text('20')  # Already below the dim threshold.
    run('dim')
    assert device.read_text() == '20' and not state.exists()

    device.write_text('40')
    state.write_text('280\n')  # Upgrade old-format state.
    run('restore')
    assert device.read_text() == '280' and not state.exists()

    run('dim')
    processes = [subprocess.Popen(['bash', script, 'restore'], env=env)
                 for _ in range(3)]
    assert all(p.wait() == 0 for p in processes)
    assert device.read_text() == '280' and not state.exists()
print('brightness recovery checks passed')
