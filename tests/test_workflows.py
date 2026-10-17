"""Observable install safety and profile assembly; no GUI or privileged tests."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Workflows(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix='tessarchy-test-')
        self.addCleanup(self.scratch.cleanup)
        self.home = Path(self.scratch.name)
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_DATA_HOME=str(self.home / 'data'),
                        XDG_CONFIG_HOME=str(self.home / 'config'))
        for variable in ('DISPLAY', 'WAYLAND_DISPLAY', 'TESSARCHY_DATA_DIR'):
            self.env.pop(variable, None)

    def run_script(self, name, expected=0, env=None):
        result = subprocess.run([str(ROOT / 'scripts' / name)], env=env or self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def test_install_uninstall_preserves_preferences_and_other_configs(self):
        sentinel = self.home / 'config/hypr/hyprland.conf'
        sentinel.parent.mkdir(parents=True)
        sentinel.write_text('existing config')
        preferences = self.home / 'config/tessarchy/preferences.lua'
        preferences.parent.mkdir(parents=True)
        preferences.write_text('-- mine')
        shell_settings = preferences.with_name('shell.ini')
        shell_settings.write_text('[Shell]\nlayoutMode=tablet\n')
        self.run_script('install-dev.sh')
        data = self.home / 'data/tessarchy'
        self.assertEqual((data / 'shell/shell.qml').read_bytes(),
                         (ROOT / 'shell/shell.qml').read_bytes())
        self.run_script('install-dev.sh', expected=1)
        self.run_script('uninstall-dev.sh')
        self.assertFalse(data.exists())
        self.assertEqual(sentinel.read_text(), 'existing config')
        self.assertEqual(preferences.read_text(), '-- mine')
        self.assertEqual(shell_settings.read_text(), '[Shell]\nlayoutMode=tablet\n')
        self.assertFalse((self.home / '.local/bin/tessarchy-osk').exists())

    def osk(self, *args, path_tools=(), env=None):
        """Run tessarchy-osk with PATH limited to bash, mkdir and the given stubs."""
        import shutil
        stubs = self.home / 'stubs'
        stubs.mkdir(exist_ok=True)
        for real in ('bash', 'mkdir'):
            if not (stubs / real).exists():
                (stubs / real).symlink_to(shutil.which(real) or f'/usr/bin/{real}')
        for name, body in path_tools:
            tool = stubs / name
            tool.write_text('#!/bin/bash\n' + body)
            tool.chmod(0o755)
        run_env = dict(env or self.env, PATH=str(stubs),
                       XDG_STATE_HOME=str(self.home / 'state'))
        return subprocess.run([str(ROOT / 'session/tessarchy-osk'), *args], env=run_env,
                              capture_output=True, text=True)

    def test_osk_is_optional_and_keeps_gnome_settings_private(self):
        missing = self.osk('start')
        self.assertEqual(missing.returncode, 0, missing.stderr)
        self.assertIn('squeekboard not installed', missing.stderr)
        self.assertEqual(self.osk().returncode, 2)
        self.assertEqual(self.osk('bogus').returncode, 2)
        fake = ('squeekboard', 'printf "%s|%s\\n" "$GSETTINGS_BACKEND" "$XDG_CONFIG_HOME"\n')
        self.assertEqual(self.osk('start', path_tools=[fake]).returncode, 1)
        env = dict(self.env, WAYLAND_DISPLAY='wayland-test')
        result = self.osk('start', path_tools=[fake], env=env)
        self.assertEqual(result.returncode, 0, result.stderr)
        state = self.home / 'state/tessarchy/osk'
        self.assertEqual(result.stdout.strip(), f'keyfile|{state}')
        keyfile = state / 'glib-2.0/settings/keyfile'
        self.assertIn('screen-keyboard-enabled=true', keyfile.read_text())
        keyfile.write_text('[org/gnome/desktop/a11y/applications]\nscreen-keyboard-enabled=false\n')
        self.osk('start', path_tools=[fake], env=env)
        self.assertIn('=false', keyfile.read_text())
        self.assertFalse((self.home / 'config/glib-2.0').exists())

    def test_osk_toggle_flips_visibility(self):
        log = self.home / 'busctl.log'
        for current, expected in (('true', 'false'), ('false', 'true')):
            busctl = ('busctl', f'echo "$*" >> {log}\n'
                      f'[[ $2 == get-property ]] && echo "b {current}"\nexit 0\n')
            result = self.osk('toggle', path_tools=[busctl])
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(log.read_text().splitlines()[-1].endswith(f'SetVisible b {expected}'))
        self.osk('show', path_tools=[busctl])
        self.assertTrue(log.read_text().splitlines()[-1].endswith('SetVisible b true'))

    def theme(self, *args, env=None):
        run_env = dict(env or self.env, TESSARCHY_DATA_DIR=str(ROOT),
                       XDG_STATE_HOME=str(self.home / 'state'))
        return subprocess.run([str(ROOT / 'session/tessarchy-theme'), *args], env=run_env,
                              capture_output=True, text=True)

    def test_theme_renders_shell_keyboard_and_terminal_from_one_palette(self):
        state = self.home / 'state/tessarchy'
        self.assertEqual(self.theme('current').stdout.strip(), 'tessera')
        self.assertEqual(self.theme('apply').returncode, 0)
        self.assertEqual((state / 'theme/name').read_text().strip(), 'tessera')
        self.assertIn('accent = "#a9e8d5"', (state / 'theme/colors.toml').read_text())
        result = self.theme('set', 'tessera-light')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((state / 'theme/mode').read_text().strip(), 'light')
        css = (state / 'osk/gtk-3.0/gtk.css').read_text()
        self.assertIn('#Return { background: #1f8a72', css)
        self.assertIn('sq_view { background-color: #cfd9e4', css)
        self.assertIn('background=eef3f8', (state / 'theme/foot.ini').read_text())
        for bad in ('../tessera', 'missing', '.hidden'):
            self.assertEqual(self.theme('set', bad).returncode, 1, bad)
        self.assertEqual(self.theme('current').stdout.strip(), 'tessera-light')
        self.assertEqual(self.theme().returncode, 2)
        # An Omarchy theme directory works as-is: palette, luminance-derived
        # mode, wallpaper, and the user's own foot config kept underneath.
        mine = self.home / 'config/tessarchy/themes/paper'
        (mine / 'backgrounds').mkdir(parents=True)
        (mine / 'colors.toml').write_text('background = "#FAFAFA"\nforeground = "#202020"\nblue = "#3366cc"\n')
        (mine / 'backgrounds/1.png').write_bytes(b'png')
        user_foot = self.home / 'config/foot/foot.ini'
        user_foot.parent.mkdir(parents=True)
        user_foot.write_text('font=monospace:size=14\n')
        self.assertIn('paper\tlight\t#fafafa\t#202020\t#3366cc', self.theme('list').stdout)
        self.assertEqual(self.theme('set', 'paper').returncode, 0)
        self.assertEqual((state / 'theme/mode').read_text().strip(), 'light')
        self.assertEqual((state / 'theme/wallpaper').read_text().strip(), str(mine / 'backgrounds/1.png'))
        foot = (state / 'theme/foot.ini').read_text()
        self.assertTrue(foot.startswith(f'include={user_foot}\n'), foot)
        self.assertEqual(user_foot.read_text(), 'font=monospace:size=14\n')
        self.theme('set', 'tessera')
        self.assertEqual((state / 'theme/wallpaper').read_text().strip(), '')

    def test_run_launches_apps_in_theme_mode(self):
        stubs = self.home / 'bin'
        stubs.mkdir()
        for name in ('foot', 'firefox'):
            (stubs / name).write_text('#!/bin/bash\necho "$GTK_THEME|$*"\n')
            (stubs / name).chmod(0o755)
        env = dict(self.env, PATH=f'{stubs}:{os.environ["PATH"]}', XDG_STATE_HOME=str(self.home / 'state'))
        run = lambda *a: subprocess.run([str(ROOT / 'session/tessarchy-run'), *a], env=env,
                                        capture_output=True, text=True).stdout.strip()
        self.assertEqual(run('firefox', 'about:blank'), 'Adwaita:dark|about:blank')
        self.theme('set', 'tessera-light')
        config = self.home / 'state/tessarchy/theme/foot.ini'
        self.assertEqual(run('foot', '-e', 'ls'), f'Adwaita|--config={config} -e ls')
        self.assertEqual(run('firefox'), 'Adwaita|')

    def test_portal_asks_shell_and_falls_back_to_gtk_in_desktop(self):
        import shutil
        need = ('cc', 'make', 'pkg-config', 'gdbus', 'dbus-run-session')
        if not all(shutil.which(tool) for tool in need):
            self.skipTest('portal build/D-Bus tools unavailable')
        out = self.home / 'portal-build'
        build = subprocess.run(['make', '-s', '-C', str(ROOT / 'portal'), f'O={out}'],
                               capture_output=True, text=True)
        self.assertEqual(build.returncode, 0, build.stderr)
        stubs = self.home / 'bin'
        stubs.mkdir()
        log = self.home / 'asked'
        # Stand-in shell: logs the request, answers per $SHELL_ANSWER.
        (stubs / 'tessera-shell').write_text(f'''#!/bin/bash
printf '%s\\n' "$*" >> {log}
[[ $3 == picker && $4 == pick ]] || exit 0
case $SHELL_ANSWER in
  pick) printf '%s\\n' "$8/$9" "" > "$5"; echo ok ;;
  cancel) echo > "$5"; echo ok ;;
  *) echo desktop ;;
esac
''')
        (stubs / 'tessera-shell').chmod(0o755)
        env = dict(self.env, PATH=f'{stubs}:{os.environ["PATH"]}', XDG_RUNTIME_DIR=str(self.home))

        def call(answer, method, options):
            # One private bus per case: the stub reads SHELL_ANSWER from the portal's environment.
            script = (f'{out}/tessarchy-portal & sleep 0.5; gdbus call --session '
                      '--dest org.freedesktop.impl.portal.desktop.tessarchy '
                      '--object-path /org/freedesktop/portal/desktop '
                      f'--method org.freedesktop.impl.portal.FileChooser.{method} '
                      '/org/freedesktop/portal/desktop/request/1_1/t1 app "" Title "$0"')
            result = subprocess.run(['dbus-run-session', '--', 'bash', '-c', script, options],
                                    env=dict(env, SHELL_ANSWER=answer), capture_output=True, text=True, timeout=30)
            return result.stdout.strip()

        # NUL-terminated, as xdg-desktop-portal sends it (gdbus's b'' text form is not).
        folder = '<@ay [' + ', '.join(f'0x{c:02x}' for c in b'/srv/x\0') + ']>'
        self.assertEqual(call('pick', 'SaveFile', "{'current_name': <'a b.txt'>, 'current_folder': " + folder + "}"),
                         "(uint32 0, {'uris': <['file:///srv/x/a%20b.txt']>})")
        self.assertEqual(call('cancel', 'OpenFile', "{'filters': <[('Images', [(uint32 0, '*.png'), (uint32 0, '*.jpg')])]>}"),
                         '(uint32 1, @a{sv} {})')
        # Desktop mode: forwarded to xdg-desktop-portal-gtk, absent on this bus.
        self.assertEqual(call('desktop', 'OpenFile', "{'directory': <true>}"), '(uint32 2, @a{sv} {})')
        asked = log.read_text()
        self.assertIn('ipc call picker pick ', asked)
        self.assertIn(' save 0 /srv/x a b.txt Title \n', asked)
        self.assertIn(' open 0 ' + str(self.home), asked)
        self.assertIn(' *.png;*.jpg\n', asked)
        self.assertIn(' folder 0 ', asked)
        self.assertEqual(list((self.home / 'tessarchy-portal').iterdir()), [])  # FIFOs removed

    def test_session_start_launches_shell_and_optional_keyboard(self):
        import shutil
        if not shutil.which('lua'):
            self.skipTest('Lua interpreter unavailable')
        script = r'''local callbacks, commands = {}, {}
hl = {
    monitor = function() end, config = function() end, bind = function() end,
    on = function(name, callback) callbacks[name] = callback end,
    exec_cmd = function(command) table.insert(commands, command) end,
    dsp = { exec_cmd = function() end, exit = function() end,
            window = { fullscreen = function(action) return action end } }
}
dofile(arg[1])
callbacks["hyprland.start"]()
assert(commands[1] == "tessera-shell" and commands[2] == "tessarchy-osk start",
       table.concat(commands, ","))
'''
        result = subprocess.run(['lua', '-', str(ROOT / 'session/hyprland.lua')],
                                input=script, text=True, capture_output=True, env=self.env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_existing_launcher_refused_before_installing_data(self):
        launcher = self.home / '.local/bin/start-tessarchy'
        launcher.parent.mkdir(parents=True)
        launcher.write_text('unrelated')
        self.run_script('install-dev.sh', expected=1)
        self.assertEqual(launcher.read_text(), 'unrelated')
        self.assertFalse((self.home / 'data/tessarchy').exists())

    def test_modified_launcher_blocks_uninstall(self):
        self.run_script('install-dev.sh')
        launcher = self.home / '.local/bin/start-tessarchy'
        launcher.write_text('modified')
        self.run_script('uninstall-dev.sh', expected=1)
        self.assertEqual(launcher.read_text(), 'modified')
        self.assertTrue((self.home / 'data/tessarchy/.tessarchy-dev-install').exists())

    def test_uninstall_requires_marker_and_preserves_extra_files(self):
        self.run_script('uninstall-dev.sh', expected=1)
        self.run_script('install-dev.sh')
        extra = self.home / 'data/tessarchy/keep.txt'
        extra.write_text('keep')
        self.run_script('uninstall-dev.sh')
        self.assertEqual(extra.read_text(), 'keep')

    def test_session_refuses_nested_graphical_launch(self):
        env = dict(self.env, WAYLAND_DISPLAY='wayland-test')
        result = subprocess.run([str(ROOT / 'session/start-tessarchy')], env=env,
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('local TTY', result.stderr)

    def test_login_startup_roundtrip_preserves_profile_and_is_idempotent(self):
        self.run_script('install-dev.sh')
        profile = self.home / '.bash_profile'
        original = b'# existing setup\nexport KEEP_ME=yes\n'
        profile.write_bytes(original)
        command = [str(ROOT / 'scripts/login-session.sh')]
        def change(operation):
            return subprocess.run(command + [operation], env=self.env,
                                  capture_output=True, text=True)
        self.assertEqual(change('enable').returncode, 0)
        enabled = profile.read_bytes()
        self.assertTrue(enabled.startswith(original))
        self.assertIn(b'/dev/tty1', enabled)
        self.assertEqual(change('enable').returncode, 0)
        self.assertEqual(profile.read_bytes(), enabled)
        self.assertEqual(change('disable').returncode, 0)
        self.assertEqual(profile.read_bytes(), original)
        self.assertEqual(change('disable').returncode, 0)
        self.assertTrue(list(self.home.glob('.bash_profile.tessarchy-backup-*')))

    def test_login_startup_preserves_symlinks_and_modified_blocks(self):
        self.run_script('install-dev.sh')
        profile = self.home / '.bash_profile'
        target = self.home / 'real-profile'
        target.write_text('keep')
        profile.symlink_to(target)
        command = [str(ROOT / 'scripts/login-session.sh'), 'enable']
        result = subprocess.run(command, env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_text(), 'keep')
        profile.unlink()
        original = '# BEGIN TESSARCHY LOGIN\nmodified\n# END TESSARCHY LOGIN\n'
        profile.write_text(original)
        result = subprocess.run(command, env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(profile.read_text(), original)

    def test_basic_vm_uses_downloaded_disk_and_readonly_fresh_share(self):
        # Stub QEMU rather than open a window or touch a running guest disk.
        fakebin = self.home / 'bin'
        fakebin.mkdir()
        fakeqemu = fakebin / 'qemu-system-x86_64'
        fakeqemu.write_text('#!/bin/bash\nprintf "%s\\n" "$@"\n'
                            'test -f "$VM_SOURCE_SHARE/tessarchy/scripts/setup-guest.sh"\n')
        fakeqemu.chmod(0o755)
        import shutil
        source = self.home / 'source'
        for directory in ('scripts', 'shell', 'session', 'packaging', 'iso', 'docs', 'tests', 'assets'):
            shutil.copytree(ROOT / directory, source / directory)
        for name in ('README.md', 'AGENTS.md', 'LICENSE'):
            shutil.copy2(ROOT / name, source / name)
        (source / 'vm').mkdir()
        disk = source / 'vm/Arch-Linux-x86_64-basic.qcow2'
        disk.write_bytes(b'keep running guest image')
        env = dict(self.env, PATH=str(fakebin) + ':' + os.environ['PATH'])
        result = subprocess.run([str(source / 'scripts/run-basic-vm.sh')], env=env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(str(disk), result.stdout)
        self.assertIn('readonly=on', result.stdout)
        self.assertEqual(disk.read_bytes(), b'keep running guest image')
        self.assertFalse(list((source / 'build').glob('source-share.*')))

    def test_new_windows_follow_saved_mode_without_touching_dialogs(self):
        import shutil
        if not shutil.which('lua'):
            self.skipTest('Lua interpreter unavailable')
        folder = self.home / 'config/tessarchy'
        folder.mkdir(parents=True)
        script = r'''local callbacks, actions = {}, {}
hl = {
    monitor = function() end, config = function() end, bind = function() end,
    on = function(name, callback) callbacks[name] = callback end,
    dispatch = function(action) table.insert(actions, action) end,
    dsp = { exec_cmd = function() end, exit = function() end,
            window = { fullscreen = function(action) return action end } }
}
dofile(arg[1])
local function check(mode, width, height, scale, transform, floating, fullscreen, expected)
    local f = assert(io.open(os.getenv("XDG_CONFIG_HOME") .. "/tessarchy/shell.ini", "w"))
    f:write("[Other]\nlayoutMode=desktop\n[Shell]\nlayoutMode=" .. mode .. "\n")
    f:close()
    actions = {}
    local window = { floating = floating, fullscreen = fullscreen,
        monitor = {width=width, height=height, scale=scale, transform=transform} }
    callbacks["window.open"](window)
    assert(#actions == expected, mode .. ": unexpected app startup policy")
    if expected == 1 then
        assert(actions[1].window == window and actions[1].mode == "maximized")
    end
end
check("auto", 400, 800, 1, 0, false, 0, 1)
check("auto", 800, 1280, 1, 0, false, 0, 1)
check("auto", 1280, 800, 1, 0, false, 0, 0)
check("auto", 1280, 800, 2, 0, false, 0, 1)
check("auto", 1280, 800, 1, 1, false, 0, 1)
check("desktop", 400, 800, 1, 0, false, 0, 0)
check("phone", 1280, 800, 1, 0, false, 0, 1)
check("invalid", 400, 800, 1, 0, false, 0, 1)
check("phone", 400, 800, 1, 0, true, 0, 0)
check("phone", 400, 800, 1, 0, false, 2, 0)
'''
        result = subprocess.run(['lua', '-', str(ROOT / 'session/hyprland.lua')],
                                input=script, text=True, capture_output=True, env=self.env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_iso_staging_preserves_boot_assets_and_account_databases(self):
        # Minimal fixture exercises our assembly, not upstream archiso validity.
        repo = self.home / 'source'
        (repo / 'scripts').mkdir(parents=True)
        import shutil
        for directory in ('shell', 'session', 'iso', 'themes', 'portal'):
            shutil.copytree(ROOT / directory, repo / directory)
        shutil.copy2(ROOT / 'scripts/stage-iso.sh', repo / 'scripts')
        base = self.home / 'releng'
        (base / 'airootfs/etc/systemd/system/multi-user.target.wants').mkdir(parents=True)
        (base / 'profiledef.sh').write_text('file_permissions=(["/etc/shadow"]="0:0:400")\n')
        (base / 'packages.x86_64').write_text('base\nlinux\nunused-rescue-tool\n')
        (base / 'airootfs/etc/passwd').write_text('root:x:0:0:root:/root:/usr/bin/zsh\n')
        boot = base / 'efiboot/loader/entries'
        boot.mkdir(parents=True)
        (boot / 'arch.conf').write_text('retained boot asset')
        ssh_link = base / 'airootfs/etc/systemd/system/multi-user.target.wants/sshd.service'
        ssh_link.symlink_to('/usr/lib/systemd/system/sshd.service')
        env = dict(self.env, ARCHISO_RELENG=str(base))
        command = [str(repo / 'scripts/stage-iso.sh')]
        result = subprocess.run(command, env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        profile = repo / 'build/iso-profile'
        self.assertEqual((profile / 'efiboot/loader/entries/arch.conf').read_text(),
                         'retained boot asset')
        self.assertEqual((profile / 'airootfs/etc/passwd').read_text(),
                         'root:x:0:0:root:/root:/usr/bin/bash\n')
        self.assertIn('/usr/bin/zsh', (base / 'airootfs/etc/passwd').read_text())
        self.assertFalse((profile / 'airootfs/etc/group').exists())
        self.assertFalse((profile / 'airootfs/etc/systemd/system/multi-user.target.wants/sshd.service').is_symlink())
        self.assertTrue(ssh_link.is_symlink())
        self.assertIn('quickshell', (profile / 'packages.x86_64').read_text())
        self.assertNotIn('unused-rescue-tool', (profile / 'packages.x86_64').read_text())
        self.assertNotIn('linux-firmware', (profile / 'packages.x86_64').read_text())
        self.assertTrue((profile / 'airootfs/etc/systemd/system/multi-user.target.wants/systemd-networkd.service').is_symlink())
        self.assertTrue((profile / 'airootfs/usr/bin/start-tessarchy').stat().st_mode & 0o111)
        self.assertTrue((profile / 'airootfs/usr/bin/tessarchy-theme').stat().st_mode & 0o111)
        self.assertTrue((profile / 'airootfs/usr/share/tessarchy/themes/tessera/colors.toml').is_file())
        self.assertIn('u tess 1000', (profile / 'airootfs/etc/sysusers.d/tessarchy.conf').read_text())
        result = subprocess.run(command, env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main()
