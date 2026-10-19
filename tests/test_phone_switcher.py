"""Exercise the actual Recents component in Quickshell's offscreen runtime."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("qs"), "Quickshell unavailable")
class PhoneSwitcher(unittest.TestCase):
    def test_stack_selection_and_disappearing_windows(self):
        with tempfile.TemporaryDirectory() as directory:
            scratch = Path(directory)
            stage = scratch / "shell"
            shutil.copytree(ROOT / "shell", stage)
            harness = (ROOT / "tests/quickshell/phone-switcher.qml").read_text()
            (stage / "shell.qml").write_text(harness.replace("../../shell/components", "components"))
            runtime = scratch / "runtime"
            runtime.mkdir(mode=0o700)
            env = dict(os.environ, QT_QPA_PLATFORM="offscreen", XDG_RUNTIME_DIR=str(runtime),
                       XDG_CONFIG_HOME=str(scratch / "config"), QT_QPA_PLATFORMTHEME="basic", QT_QUICK_BACKEND="software")
            for name in ("WAYLAND_DISPLAY", "DISPLAY", "DBUS_SESSION_BUS_ADDRESS"):
                env.pop(name, None)
            try:
                result = subprocess.run(["qs", "-p", str(stage / "shell.qml")], env=env,
                                        capture_output=True, text=True, timeout=20)
            except subprocess.TimeoutExpired as error:
                self.fail(f"Quickshell timed out: {error.stdout!r} {error.stderr!r}")
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertIn("PHONE_SWITCHER_TEST_PASS", output)
            self.assertNotIn("PHONE_SWITCHER_TEST_FAIL", output)
