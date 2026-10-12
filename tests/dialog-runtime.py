"""Check both Linux wrapper environments without running an app or a desktop."""

import subprocess
import sys
import tempfile
from pathlib import Path

library_dir, zenity, package, name = sys.argv[1:]
with tempfile.TemporaryDirectory(prefix="craft-dialog-runtime-") as directory:
    root = Path(directory)
    probe = root / "probe.py"
    probe.write_text(
        "import ctypes, os, shutil\n"
        f"assert {library_dir!r} in os.environ['LD_LIBRARY_PATH'].split(':')\n"
        "ctypes.CDLL('libdbus-1.so')\n"
        f"assert shutil.which('zenity') == {zenity!r}\n"
        "print('PASS D-Bus client and Zenity resolved through actual wrapper')\n"
    )
    # Bash wrappers terminate with exec. Intercept only that call, preserving
    # their real environment setup; never start the app during install checks.
    hook = root / "bash-env"
    hook.write_text(f"exec() {{ '{sys.executable}' '{probe}'; }}\n")
    env = {"HOME": str(root), "PATH": "", "BASH_ENV": str(hook)}
    for command in [name, f"{name}-cli"]:
        wrapper = Path(package) / "bin" / command
        assert wrapper.is_file(), command
        result = subprocess.run(
            [str(wrapper)],
            env=env,
            capture_output=True,
            text=True,
            timeout=20,
            check=False,
        )
        assert result.returncode == 0, f"{command}: {result.stderr}"
        assert "PASS D-Bus client and Zenity" in result.stdout, command
        print(f"PASS {command}: D-Bus library and Zenity wrapper environment")
