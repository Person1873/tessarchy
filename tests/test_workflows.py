"""Observable install safety and profile assembly; no GUI or privileged tests."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Workflows(unittest.TestCase):
    def test_site_builder_refuses_existing_output_and_bundles_originals(self):
        import sys
        import zipfile
        destination = self.home / 'site'
        command = [sys.executable, str(ROOT / 'scripts/build-site.py'),
                   '--output', str(destination)]
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        with zipfile.ZipFile(destination / 'assets/screenshots.zip') as archive:
            self.assertEqual(archive.read('phone-switcher.png'),
                             (ROOT / 'assets/screenshots/phone-switcher.png').read_bytes())
        sentinel = destination / 'keep.txt'
        sentinel.write_text('unrelated content')
        result = subprocess.run(command, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(sentinel.read_text(), 'unrelated content')

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

    def test_uninstall_uses_install_manifest_and_preserves_unknown_extras(self):
        self.run_script('install-dev.sh')
        data = self.home / 'data/tessarchy'
        manifest = data / '.tessarchy-dev-files'
        listed = manifest.read_text().splitlines()
        self.assertIn('shell/shell.qml', listed)
        self.assertIn('session/hyprland.lua', listed)
        self.assertIn('.tessarchy-dev-install', listed)
        for entry in (data / 'shell').rglob('*'):
            if entry.is_file():
                self.assertIn(entry.relative_to(data).as_posix(), listed)
        extra = data / 'shell/components/untracked-extra.qml'
        extra.write_text('keep')
        self.run_script('uninstall-dev.sh')
        self.assertEqual(extra.read_text(), 'keep')
        self.assertFalse((data / 'shell/shell.qml').exists())
        self.assertFalse((data / 'session/hyprland.lua').exists())
        self.assertFalse((data / '.tessarchy-dev-install').exists())
        self.assertFalse((data / '.tessarchy-dev-files').exists())

    def test_uninstall_rejects_unsafe_manifest_before_removing_files(self):
        self.run_script('install-dev.sh')
        data = self.home / 'data/tessarchy'
        manifest = data / '.tessarchy-dev-files'
        original = manifest.read_text()
        outside = self.home / 'outside'
        outside.mkdir()
        sentinel = outside / 'keep'
        sentinel.write_text('keep')
        (data / 'redirect').symlink_to(outside, target_is_directory=True)
        for entry in ('../../outside/keep', '/outside/keep', 'redirect/keep', ''):
            with self.subTest(entry=entry):
                manifest.write_text(original + entry + '\n')
                self.run_script('uninstall-dev.sh', expected=1)
                self.assertEqual(sentinel.read_text(), 'keep')
                self.assertTrue((self.home / '.local/bin/tessera-shell').exists())
                self.assertTrue((data / 'shell/shell.qml').exists())

    def test_uninstall_legacy_marker_uses_fixed_v1_set(self):
        data = self.home / 'data/tessarchy'
        for relative in ('shell/shell.qml', 'shell/components/TouchButton.qml',
                         'session/hyprland.lua'):
            target = data / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text('installed')
        marker = data / '.tessarchy-dev-install'
        marker.write_text('tessarchy-dev-v1')
        kept = data / 'shell/components/kept-extra.txt'
        kept.write_text('keep')
        self.run_script('uninstall-dev.sh')
        self.assertFalse((data / 'shell/shell.qml').exists())
        self.assertFalse((data / 'shell/components/TouchButton.qml').exists())
        self.assertFalse((data / 'session/hyprland.lua').exists())
        self.assertFalse((data / '.tessarchy-dev-install').exists())
        self.assertEqual(kept.read_text(), 'keep')
        # The untracked extra survives; everything installed under v1 goes.
        self.assertTrue(kept.exists())
        self.assertFalse((data / 'shell/shell.qml').exists())

    def copy_repo(self, destination, directories):
        import shutil
        for directory in directories:
            shutil.copytree(ROOT / directory, destination / directory)
        for name in ('README.md', 'AGENTS.md', 'LICENSE'):
            shutil.copy2(ROOT / name, destination / name)

    def test_vm_plan_prints_command_refuses_missing_disk_and_bad_usage(self):
        # plan mode only prints the command; qemu is not required to test refusals.
        repo = self.home / 'source'
        self.copy_repo(repo, ('scripts',))
        command = [str(repo / 'scripts/vm.sh')]
        disk = self.home / 'source/vm/tessarchy.qcow2'
        result = subprocess.run(command + ['plan'], env=self.env,
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('init first', result.stderr)
        disk.parent.mkdir(parents=True, exist_ok=True)
        disk.write_text('disk')
        result = subprocess.run(command + ['plan'], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(str(disk), result.stdout)
        self.assertIn('virtio-vga', result.stdout)
        result = subprocess.run(command + ['wat'], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        env = dict(self.env, VM_SSH_PORT='80')
        result = subprocess.run(command + ['plan'], env=env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('VM_SSH_PORT', result.stderr)

    FAKE_CURL = ('#!/bin/bash\n'
                 'out=""\n'
                 'prev=""\n'
                 'for a in "$@"; do\n'
                 '    if [[ $prev == "-o" ]]; then out=$a; fi\n'
                 '    prev=$a\n'
                 'done\n'
                 'case "$*" in\n'
                 '    *sha256sums.txt*) cat "$TESSARCHY_FIXTURE_MANIFEST" > "$out";;\n'
                 '    *) exit %s;;\n'
                 'esac\n'
                 'exit 0\n')

    def stub_fetch_tools(self, fakebin, manifest, other_exit):
        import shutil
        manifest.parent.mkdir(parents=True, exist_ok=True)
        manifest.write_text('1234567890abcdef' * 4 + ' *archlinux-2026.10.01-x86_64.iso\n')
        (fakebin / 'test-keyring.gpg').write_bytes(b'fixture: verification is never reached')
        fakecurl = fakebin / 'curl'
        fakecurl.write_text(self.FAKE_CURL % other_exit)
        fakecurl.chmod(0o755)
        shutil.copy2('/usr/bin/gpgv', fakebin / 'gpgv')
        shutil.copy2('/usr/bin/sha256sum', fakebin / 'sha256sum')

    def test_fetch_iso_never_overwrites_existing_download(self):
        repo = self.home / 'source'
        self.copy_repo(repo, ('scripts',))
        (repo / 'vm').mkdir()
        existing = repo / 'vm/archlinux-2026.10.01-x86_64.iso'
        existing.write_bytes(b'existing download')
        fakebin = self.home / 'bin'
        fakebin.mkdir()
        self.stub_fetch_tools(fakebin, fakebin / 'manifest-fixtures/sha256sums.txt', 0)
        env = dict(self.env, PATH=str(fakebin) + ':' + os.environ['PATH'],
                   TESSARCHY_FIXTURE_MANIFEST=str(fakebin / 'manifest-fixtures/sha256sums.txt'),
                   ARCH_ISO_KEYRING=str(fakebin / 'test-keyring.gpg'))
        result = subprocess.run([str(repo / 'scripts/fetch-arch-iso.sh')], env=env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn('already exists', result.stderr)
        self.assertEqual(existing.read_bytes(), b'existing download')
        self.assertFalse(list((repo / 'vm').glob('.download*')))

    def test_fetch_iso_download_failure_leaves_no_partial_iso(self):
        repo = self.home / 'source'
        self.copy_repo(repo, ('scripts',))
        (repo / 'vm').mkdir()
        fakebin = self.home / 'bin'
        fakebin.mkdir()
        self.stub_fetch_tools(fakebin, fakebin / 'manifest-fixtures/sha256sums.txt', 22)
        env = dict(self.env, PATH=str(fakebin) + ':' + os.environ['PATH'],
                   TESSARCHY_FIXTURE_MANIFEST=str(fakebin / 'manifest-fixtures/sha256sums.txt'),
                   ARCH_ISO_KEYRING=str(fakebin / 'test-keyring.gpg'))
        result = subprocess.run([str(repo / 'scripts/fetch-arch-iso.sh')], env=env,
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(list((repo / 'vm').glob('archlinux-*.iso')))
        self.assertFalse(list((repo / 'vm').glob('.download*')))

    def test_build_iso_requires_explicit_archiso_install(self):
        self.run_script('build-iso.sh', expected=1)

    def test_export_vm_source_keeps_existing_snapshot_idempotent(self):
        repo = self.home / 'source'
        self.copy_repo(repo, ('shell', 'session', 'scripts', 'packaging', 'iso',
                              'docs', 'tests', 'assets'))
        share = repo / 'build/vm-share/tessarchy'
        def run():
            return subprocess.run([str(repo / 'scripts/export-vm-source.sh')], env=self.env,
                                  capture_output=True, text=True)
        self.assertEqual(run().returncode, 0)
        self.assertEqual((share / 'scripts/install-dev.sh').read_bytes(),
                         (ROOT / 'scripts/install-dev.sh').read_bytes())
        marker = share / 'README.md'
        first = marker.read_bytes()
        self.assertEqual(run().returncode, 0)
        self.assertIn('Keeping existing snapshot', run().stdout)
        self.assertEqual(marker.read_bytes(), first)

    def test_basic_vm_launcher_refuses_missing_guest_disk(self):
        repo = self.home / 'source'
        self.copy_repo(repo, ('scripts', 'session'))
        result = subprocess.run([str(repo / 'scripts/run-basic-vm.sh')], env=self.env,
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn('Missing basic Arch VM disk', result.stderr)

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
        script = r'''local callbacks, actions, binds = {}, {}, {}
hl = {
    monitor = function() end, config = function() end,
    bind = function(keys, dispatcher, flags) binds[keys] = { dispatcher = dispatcher, flags = flags } end,
    layer_rule = function() end,
    on = function(name, callback) callbacks[name] = callback end,
    dispatch = function(action) table.insert(actions, action) end,
    dsp = { exec_cmd = function(command) return { exec = command } end, exit = function() end,
            focus = function(target) return target end,
            window = { fullscreen = function(action) return action end,
                       close = function() return {} end,
                       cycle_next = function() return {} end,
                       move = function(target) return target end,
                       drag = function() return {} end,
                       resize = function() return {} end } }
}
dofile(arg[1])
-- Desktop bindings stay present and are built from fixed keys and dispatchers.
for i = 1, 5 do
    assert(binds["SUPER + " .. i], "missing workspace bind " .. i)
    assert(binds["SUPER + " .. i].dispatcher.workspace == i, "workspace bind targets wrong workspace")
    assert(binds["SUPER + SHIFT + " .. i], "missing move-to-workspace bind " .. i)
    assert(binds["SUPER + SHIFT + " .. i].dispatcher.workspace == i, "move bind targets wrong workspace")
end
for _, name in ipairs({ "SUPER + Q", "SUPER + Tab", "SUPER + left", "SUPER + right",
    "SUPER + up", "SUPER + down", "SUPER + SHIFT + left", "SUPER + SHIFT + right",
    "SUPER + SHIFT + up", "SUPER + SHIFT + down" }) do
    assert(binds[name], "missing desktop bind: " .. name)
end
assert(binds["SUPER + mouse:272"].flags.mouse == true, "drag bind must be a mouse bind")
assert(binds["SUPER + mouse:273"].flags.mouse == true, "resize bind must be a mouse bind")
assert(binds["XF86AudioMute"].flags.locked == true and binds["XF86AudioMute"].flags.repeating == true,
    "volume keys must work on the lock screen and repeat")
assert(binds["SUPER + Q"].dispatcher.exec == "tessera-shell ipc call actions closeWindow")
assert(binds["SUPER + SHIFT + E"].dispatcher.exec == "tessera-shell ipc call actions endSession")
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
        for directory in ('shell', 'session', 'iso'):
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
        self.assertIn('u tess 1000 "Tessarchy live user" /home/tess /usr/bin/fish',
                      (profile / 'airootfs/etc/sysusers.d/tessarchy.conf').read_text())
        self.assertIn('fish', (profile / 'packages.x86_64').read_text().splitlines())
        self.assertTrue((profile / 'airootfs/home/tess/.config/fish/config.fish').is_file())
        self.assertIn('/home/tess/.config/fish/config.fish', (profile / 'profiledef.sh').read_text())
        result = subprocess.run(command, env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main()
