import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DisplayControls(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix='tessarchy-display-')
        self.addCleanup(self.scratch.cleanup)
        self.home = Path(self.scratch.name)
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        for tool in ('bash', 'cat'):
            (self.bin / tool).symlink_to(shutil.which(tool))
        self.env = dict(os.environ, HOME=str(self.home), PATH=str(self.bin),
                        XDG_RUNTIME_DIR=str(self.home), DISPLAY_STATE=str(self.home / 'state'),
                        DISPLAY_LOG=str(self.home / 'log'))

    def stub(self, name, body):
        path = self.bin / name
        path.write_text('#!/usr/bin/env bash\nset -eu\n' + body + '\n')
        path.chmod(0o755)

    def run_helper(self, name, *args, code=0):
        result = subprocess.run([str(ROOT / 'session' / name), *args],
                                env=self.env, capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, code, result.stdout + result.stderr)
        return result.stdout.strip()

    def night_stubs(self):
        self.stub('hyprsunset', 'exit 0')
        self.stub('systemctl', '''
case "$*" in
    '--user show-environment') exit "${NO_MANAGER:-0}" ;;
    '--user is-active --quiet tessera-nightlight.service') [[ -f $DISPLAY_STATE ]] ;;
    '--user show tessera-nightlight.service --property=LoadState --value')
        if [[ -f $DISPLAY_STATE ]]; then echo loaded; else echo not-found; fi ;;
    '--user stop tessera-nightlight.service')
        echo stop >> "$DISPLAY_LOG"
        /usr/bin/rm -f "$DISPLAY_STATE" ;;
    *) exit 99 ;;
esac''')
        self.stub('systemd-run', '''
printf '%s\\n' "$*" >> "$DISPLAY_LOG"
[[ ${FAIL_START:-0} == 0 ]] || exit 1
: > "$DISPLAY_STATE"''')

    def test_night_light_owns_service_and_ignores_stale_pid(self):
        self.night_stubs()
        sleeper = subprocess.Popen(['sleep', '30'])
        def stop_sleeper():
            if sleeper.poll() is None:
                sleeper.terminate()
            sleeper.wait(timeout=5)
        self.addCleanup(stop_sleeper)
        (self.home / 'tessera-nightlight.pid').write_text(str(sleeper.pid))
        self.assertEqual(self.run_helper('tessera-nightlight', 'status', code=1), 'off')
        self.run_helper('tessera-nightlight', 'off')
        self.assertIsNone(sleeper.poll())
        self.run_helper('tessera-nightlight', 'on')
        self.run_helper('tessera-nightlight', 'on')
        self.assertEqual(self.run_helper('tessera-nightlight', 'status'), 'on')
        log = (self.home / 'log').read_text()
        self.assertEqual(len(log.splitlines()), 1)
        self.assertIn('--unit=tessera-nightlight.service --service-type=exec', log)
        self.assertIn('hyprsunset -t 4000', log)
        self.run_helper('tessera-nightlight', 'off')
        self.assertEqual(self.run_helper('tessera-nightlight', 'status', code=1), 'off')
        self.assertIsNone(sleeper.poll())

    def test_night_light_backend_manager_and_start_failure(self):
        self.night_stubs()
        self.env['NO_MANAGER'] = '1'
        self.run_helper('tessera-nightlight', 'on', code=3)
        self.env['NO_MANAGER'] = '0'
        self.env['FAIL_START'] = '1'
        self.run_helper('tessera-nightlight', 'on', code=1)
        self.assertEqual(self.run_helper('tessera-nightlight', 'status', code=1), 'off')
        (self.bin / 'hyprsunset').unlink()
        self.run_helper('tessera-nightlight', 'status', code=3)
        self.run_helper('tessera-nightlight', 'off')

    def test_invalid_actions_fail_before_any_backend_call(self):
        self.stub('systemctl', 'echo called >> "$DISPLAY_LOG"; exit 99')
        for name, cases in {
            'tessera-nightlight': [(), ('on', 'extra'), ('status', 'extra'), ('bad',)],
            'tessera-brightness': [(), ('up', 'extra'), ('down', 'extra'),
                                   ('get', 'extra'), ('set', '0'), ('set', '101'),
                                   ('set', '1;touch x'), ('set', '999999999999999999')]
        }.items():
            for args in cases:
                self.run_helper(name, *args, code=64)
        self.assertFalse((self.home / 'log').exists())

    def test_brightness_roundtrip_steps_device_selection_and_failure(self):
        backlight = self.home / 'backlight/panel'
        backlight.mkdir(parents=True)
        (backlight / 'max_brightness').write_text('200')
        (backlight / 'brightness').write_text('80')
        helper = self.home / 'brightness'
        helper.write_text((ROOT / 'session/tessera-brightness').read_text()
                          .replace('/sys/class/backlight', str(backlight.parent)))
        helper.chmod(0o755)

        def call(*args, code=0):
            result = subprocess.run([str(helper), *args], env=self.env,
                                    capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, code, result.stderr)
            return result.stdout.strip()

        self.assertEqual(call('get'), '40')
        call('set', '008')
        self.assertEqual(call('get'), '8')
        call('up')
        self.assertEqual(call('get'), '18')
        call('set', '1')
        call('down')
        self.assertEqual(call('get'), '1')
        (backlight / 'brightness').write_text('0')
        self.assertEqual(call('get'), '0')
        self.stub('brightnessctl', 'printf "%s\\n" "$*" > "$DISPLAY_LOG"; exit 1')
        call('set', '50', code=1)
        self.assertIn('--class=backlight --device=panel --quiet set 50%',
                      (self.home / 'log').read_text())
        (backlight / 'max_brightness').write_text('0')
        call('get', code=3)
        shutil.rmtree(backlight)
        call('get', code=3)
        call('set', '50', code=3)
