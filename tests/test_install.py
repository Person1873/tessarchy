import importlib.machinery
import importlib.util
from pathlib import Path
import contextlib
import io
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT / 'session' / 'tessarchy-install'


def load_installer():
    """The installer is an executable script, not an importable module."""
    loader = importlib.machinery.SourceFileLoader('tessarchy_install', str(INSTALLER))
    spec = importlib.util.spec_from_loader('tessarchy_install', loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class PartitionPlan(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.installer = load_installer()

    def test_uefi_layout_is_esp_then_root(self):
        plan = self.installer.plan_partitions('uefi')
        self.assertEqual([p['role'] for p in plan], ['esp', 'root'])
        esp, root = plan
        self.assertEqual((esp['start'], esp['end']), (1, 1 + self.installer.ESP_MIB))
        self.assertEqual(root['start'], esp['end'])
        self.assertEqual(root['end'], '-1')

    def test_bios_layout_adds_a_bios_boot_partition_first(self):
        plan = self.installer.plan_partitions('bios')
        self.assertEqual([p['role'] for p in plan], ['bios', 'esp', 'root'])
        self.assertEqual(plan[0]['end'], 1 + self.installer.BIOS_BOOT_MIB)
        self.assertEqual(plan[1]['start'], plan[0]['end'])

    def test_filesystem_labels_fit_their_limits(self):
        # mkfs.fat fails outright above 11 characters: the live run hit this.
        self.assertLessEqual(len(self.installer.ESP_LABEL), 11)
        self.assertLessEqual(len(self.installer.ROOT_LABEL), 16)

    def test_partitions_are_contiguous_and_ordered(self):
        for firmware in ('uefi', 'bios'):
            plan = self.installer.plan_partitions(firmware)
            self.assertEqual([p['number'] for p in plan], list(range(1, len(plan) + 1)))
            for earlier, later in zip(plan, plan[1:]):
                self.assertEqual(earlier['end'], later['start'])


class PartPath(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.installer = load_installer()

    def test_sata_disks_take_a_bare_number(self):
        self.assertEqual(self.installer.part_path('/dev/sda', 2), '/dev/sda2')

    def test_nvme_and_mmc_disks_take_a_p_suffix(self):
        self.assertEqual(self.installer.part_path('/dev/nvme0n1', 1), '/dev/nvme0n1p1')
        self.assertEqual(self.installer.part_path('/dev/mmcblk0', 3), '/dev/mmcblk0p3')


class DiskSelection(unittest.TestCase):
    def setUp(self):
        self.installer = load_installer()

    def fake_lsblk(self, devices):
        return mock.patch.object(
            self.installer, 'run',
            side_effect=lambda cmd, **kw: __import__('json').dumps({'blockdevices': devices}))

    def test_loop_zram_and_optical_devices_are_not_targets(self):
        devices = [
            {'name': 'sda', 'size': '100G', 'model': 'SSD', 'tran': 'sata', 'type': 'disk'},
            {'name': 'zram0', 'size': '4G', 'model': '', 'tran': None, 'type': 'disk'},
            {'name': 'loop0', 'size': '1G', 'model': '', 'tran': 'loop', 'type': 'disk'},
            {'name': 'sr0', 'size': '1G', 'model': 'DVD', 'tran': 'sata', 'type': 'disk'},
            {'name': 'sda1', 'size': '100G', 'model': '', 'tran': 'sata', 'type': 'part'},
        ]
        with self.fake_lsblk(devices), \
                mock.patch.object(self.installer, 'live_medium_device', return_value=None):
            paths = [d['path'] for d in self.installer.list_disks()]
        self.assertEqual(paths, ['/dev/sda'])

    def test_the_live_medium_is_marked_and_refused(self):
        devices = [{'name': 'sda', 'size': '100G', 'model': 'SSD', 'tran': 'usb', 'type': 'disk'}]
        with self.fake_lsblk(devices), \
                mock.patch.object(self.installer, 'live_medium_device', return_value='sda'):
            disks = self.installer.list_disks()
            self.assertTrue(disks[0]['live'])
            with self.assertRaises(self.installer.InstallerError):
                self.installer.validate_target('/dev/sda')

    def test_unknown_disk_is_refused(self):
        with mock.patch.object(self.installer, 'live_medium_device', return_value='sr0'), \
                mock.patch.object(self.installer, 'list_disks', return_value=[]):
            with self.assertRaises(self.installer.InstallerError):
                self.installer.validate_target('/dev/nope')


class Safety(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.installer = load_installer()

    def test_kernel_and_live_paths_are_excluded_from_the_copy(self):
        for required in ('/proc/*', '/sys/*', '/dev/*', '/run/*'):
            self.assertIn(required, self.installer.EXCLUDES)

    def test_requires_root(self):
        with mock.patch.object(self.installer.os, 'geteuid', return_value=1000):
            with self.assertRaises(self.installer.InstallerError):
                self.installer.require_root()


class KernelStaging(unittest.TestCase):
    """The target gets its kernel from the live medium, not from /.

    archiso strips the boot files out of the airootfs, so the running live
    root's /boot is empty; without this step mkinitcpio has nothing to build an
    initramfs around and the install dies before the bootloader is written.
    """

    @classmethod
    def setUpClass(cls):
        cls.installer = load_installer()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.target = Path(self.tmp.name)

    def test_the_kernel_is_copied_into_the_target_boot(self):
        source = self.target / 'medium-vmlinuz'
        source.write_bytes(b'kernel-image')
        with mock.patch.object(self.installer, 'medium_kernel', return_value=source):
            staged = self.installer.stage_kernel(self.target)
        self.assertEqual(staged, self.target / 'boot' / self.installer.KERNEL_NAME)
        self.assertEqual(staged.read_bytes(), b'kernel-image')

    def test_a_medium_without_a_kernel_fails_loudly(self):
        missing = self.target / 'nowhere'
        with mock.patch.object(self.installer, 'MEDIUM_KERNEL_PATHS', (missing,)):
            with self.assertRaises(self.installer.InstallerError):
                self.installer.medium_kernel()

    def test_the_medium_kernel_paths_live_outside_the_airootfs(self):
        for path in self.installer.MEDIUM_KERNEL_PATHS:
            self.assertTrue(str(path).startswith(str(self.installer.LIVE_MOUNT)))


class InstallOrder(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.installer = load_installer()

    def test_the_kernel_is_staged_before_the_initramfs_is_built(self):
        installer = self.installer
        calls = []
        with tempfile.TemporaryDirectory() as tmp:
            (Path(tmp) / 'etc').mkdir()
            with mock.patch.object(installer, 'MOUNT', Path(tmp)), \
                    mock.patch.object(installer, 'run', return_value=''), \
                    mock.patch.object(installer, 'stage_kernel',
                                      side_effect=lambda: calls.append('kernel')), \
                    mock.patch.object(installer, 'unit_exists', return_value=True), \
                    mock.patch.object(installer, 'in_target',
                                      side_effect=lambda *a, **k: calls.append(a[0]) or ''):
                installer.configure_target('bios', '/dev/vda', 'UUID', 'tessarchy')
        self.assertIn('kernel', calls)
        self.assertIn('mkinitcpio', calls)
        self.assertLess(calls.index('kernel'), calls.index('mkinitcpio'))


class MediumPackages(unittest.TestCase):
    """The copy of the running system has to end up owned by pacman."""

    @classmethod
    def setUpClass(cls):
        cls.installer = load_installer()

    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        self.packages = self.root / 'usr/share/tessarchy/pkgs'
        self.packages.mkdir(parents=True)
        (self.packages / 'tessera-shell-0.1.0-2-any.pkg.tar.zst').write_bytes(b'x')
        (self.packages / 'tessarchy-session-0.1.0-2-any.pkg.tar.zst').write_bytes(b'x')

    def fake_status(self, returncode):
        class Result:
            def __init__(self):
                self.returncode = returncode
                self.stdout = 'tessera-shell 0.1.0-2\ntessarchy-session 0.1.0-2\n'
                self.stderr = 'error: something went wrong' if returncode else ''
        return Result()

    def test_the_medium_packages_are_installed_into_the_target(self):
        installer = self.installer
        calls = []

        def record(*args, **kwargs):
            calls.append(args)
            return self.fake_status(0)

        with mock.patch.object(installer, 'MOUNT', self.root), \
                mock.patch.object(installer, 'archive_paths',
                                  side_effect=lambda package: [
                                      '/usr/bin/' + package.name.split('.pkg')[0],
                                      '/usr/share/tessarchy/shell/shell.qml']), \
                mock.patch.object(installer, 'in_target_status', side_effect=record), \
                mock.patch.object(installer, 'in_target', return_value='') as in_target:
            installer.adopt_medium_packages()

        command = calls[0]
        # Each package may replace the files it carries — the copies the
        # installer just made are otherwise "conflicting files" pacman refuses.
        self.assertEqual(command[:4], ('pacman', '-U', '--needed', '--noconfirm'))
        first_package = command.index(
            '/usr/share/tessarchy/pkgs/tessarchy-session-0.1.0-2-any.pkg.tar.zst')
        self.assertEqual(list(command[4:first_package]),
                         # Each package's own paths, in order, without repeats.
                         ['--overwrite', '/usr/bin/tessarchy-session-0.1.0-2-any',
                          '--overwrite', '/usr/share/tessarchy/shell/shell.qml',
                          '--overwrite', '/usr/bin/tessera-shell-0.1.0-2-any'])
        self.assertEqual(sorted(command[first_package:]),
                         ['/usr/share/tessarchy/pkgs/tessarchy-session-0.1.0-2-any.pkg.tar.zst',
                          '/usr/share/tessarchy/pkgs/tessera-shell-0.1.0-2-any.pkg.tar.zst'])
        self.assertEqual(in_target.call_args[0][0], 'pacman')

    def test_the_permission_covers_only_what_the_packages_carry(self):
        # The narrow list comes from the archives themselves.
        installer = self.installer
        listing = 'usr/\n.PKGINFO\nusr/bin/tessarchy-update\nusr/share/tessarchy/\n'
        with mock.patch.object(installer.subprocess, 'run',
                               return_value=type('R', (), {'returncode': 0,
                                                           'stdout': listing})()):
            paths = installer.archive_paths(Path('tessera-shell-0.1.0-2-any.pkg.tar.zst'))
        self.assertEqual(paths, ['/usr/bin/tessarchy-update'])

    def test_a_failed_package_step_shows_the_reason_not_the_warnings(self):
        installer = self.installer
        noise = '\n'.join([f"warning: database file for 'x' does not exist" for _ in range(8)]
                          + ['error: failed to commit transaction (conflicting files)',
                             'tessarchy-bootsplash: /usr/share/plymouth/logo-0.png exists in filesystem'])
        result = type('R', (), {'returncode': 1, 'stdout': '', 'stderr': noise})()
        printed = []
        with mock.patch.object(installer, 'MOUNT', self.root), \
                mock.patch.object(installer, 'archive_paths', return_value=['*']), \
                mock.patch.object(installer, 'in_target_status', return_value=result), \
                mock.patch.object(installer, 'in_target'), \
                mock.patch('builtins.print', side_effect=lambda *a, **k: printed.append(str(a[0]))):
            installer.adopt_medium_packages()
        self.assertTrue(any('conflicting files' in line for line in printed))
        self.assertTrue(any('logo-0.png' in line for line in printed))

    def test_the_medium_copy_is_not_kept_once_pacman_has_them(self):
        installer = self.installer
        with mock.patch.object(installer, 'MOUNT', self.root), \
                mock.patch.object(installer, 'in_target_status',
                                  return_value=self.fake_status(0)), \
                mock.patch.object(installer, 'in_target', return_value=''):
            installer.adopt_medium_packages()
        self.assertFalse(self.packages.exists())

    def test_a_medium_without_packages_says_so_and_keeps_going(self):
        installer = self.installer
        for archive in self.packages.iterdir():
            archive.unlink()
        with mock.patch.object(installer, 'MOUNT', self.root), \
                mock.patch.object(installer, 'in_target_status') as status, \
                mock.patch.object(installer, 'in_target'):
            installer.adopt_medium_packages()
        status.assert_not_called()

    def test_a_failed_install_warns_without_abandoning_the_install(self):
        installer = self.installer
        output = io.StringIO()
        with mock.patch.object(installer, 'MOUNT', self.root), \
                mock.patch.object(installer, 'archive_paths', return_value=['*']), \
                mock.patch.object(installer, 'in_target_status',
                                  return_value=self.fake_status(4)), \
                mock.patch.object(installer, 'in_target'), \
                contextlib.redirect_stdout(output):
            installer.adopt_medium_packages()
        self.assertIn('Warning', output.getvalue())
        self.assertIn('something went wrong', output.getvalue())
        # The packages are left in place: they are the only copy on the machine.
        self.assertTrue(self.packages.exists())

    def test_packages_are_adopted_before_the_initramfs_is_built(self):
        installer = self.installer
        calls = []
        with tempfile.TemporaryDirectory() as tmp:
            (Path(tmp) / 'etc').mkdir()
            with mock.patch.object(installer, 'MOUNT', Path(tmp)), \
                    mock.patch.object(installer, 'run', return_value=''), \
                    mock.patch.object(installer, 'stage_kernel',
                                      side_effect=lambda: calls.append('kernel')), \
                    mock.patch.object(installer, 'adopt_medium_packages',
                                      side_effect=lambda: calls.append('packages')), \
                    mock.patch.object(installer, 'unit_exists', return_value=True), \
                    mock.patch.object(installer, 'in_target',
                                      side_effect=lambda *a, **k: calls.append(a[0]) or ''):
                installer.configure_target('bios', '/dev/vda', 'UUID', 'tessarchy')
        self.assertLess(calls.index('packages'), calls.index('mkinitcpio'))


class LiveOnlyFiles(unittest.TestCase):
    """The live medium's own text and hooks must not survive the copy."""

    @classmethod
    def setUpClass(cls):
        cls.installer = load_installer()

    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        (self.root / 'etc/mkinitcpio.conf.d').mkdir(parents=True)

    def test_the_archiso_hook_and_the_live_motd_are_removed(self):
        (self.root / 'etc/mkinitcpio.conf.d/archiso.conf').write_text('HOOKS=(archiso)\n')
        (self.root / 'etc/motd').write_text('Tessarchy live image. Nothing is saved.\n')
        with mock.patch.object(self.installer, 'MOUNT', self.root):
            self.installer.drop_live_only_files()
        self.assertFalse((self.root / 'etc/mkinitcpio.conf.d/archiso.conf').exists())
        self.assertFalse((self.root / 'etc/motd').exists())

    def test_an_unrelated_motd_is_kept(self):
        (self.root / 'etc/motd').write_text('Welcome to the build server.\n')
        with mock.patch.object(self.installer, 'MOUNT', self.root):
            self.installer.drop_live_only_files()
        self.assertTrue((self.root / 'etc/motd').exists())


class UnitEnablement(unittest.TestCase):
    """Only claim to enable services the target actually carries."""

    @classmethod
    def setUpClass(cls):
        cls.installer = load_installer()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        units = self.root / 'usr/lib/systemd/system'
        units.mkdir(parents=True)
        for unit in ('NetworkManager', 'bluetooth'):
            (units / f'{unit}.service').write_text('')

    def test_a_unit_file_in_the_target_is_found(self):
        with mock.patch.object(self.installer, 'MOUNT', self.root):
            self.assertTrue(self.installer.unit_exists('NetworkManager'))
            self.assertFalse(self.installer.unit_exists('greetd'))

    def test_the_image_does_not_enable_a_unit_it_does_not_ship(self):
        installer = self.installer
        enabled = []
        (self.root / 'etc').mkdir()
        with mock.patch.object(installer, 'MOUNT', self.root), \
                mock.patch.object(installer, 'run', return_value=''), \
                mock.patch.object(installer, 'stage_kernel'), \
                mock.patch.object(installer, 'in_target',
                                  side_effect=lambda *a, **k: (
                                      enabled.append(a[2]) if a[:2] == ('systemctl', 'enable') else None) or ''):
            installer.configure_target('bios', '/dev/vda', 'UUID', 'tessarchy')
        self.assertIn('NetworkManager', enabled)
        self.assertIn('bluetooth', enabled)
        self.assertNotIn('greetd', enabled)



class DestructivePreflight(unittest.TestCase):
    def setUp(self):
        self.installer = load_installer()

    def test_whole_disk_live_media_and_optical_sources_are_identified(self):
        import json
        for source, kind, expected in (('/dev/sdb', 'disk', 'sdb'), ('/dev/sr0', 'rom', 'sr0')):
            def probe(cmd, **kwargs):
                return source if cmd[0] == 'findmnt' else json.dumps({
                    'blockdevices': [{'name': source, 'type': kind}]})
            with self.subTest(source=source), mock.patch.object(self.installer, 'run', side_effect=probe):
                self.assertEqual(self.installer.live_medium_device(), expected)

    def test_partition_and_mapper_sources_resolve_to_the_backing_disk(self):
        import json
        data = {'blockdevices': [{'name': '/dev/mapper/live', 'type': 'dm', 'children': [
            {'name': '/dev/sdb1', 'type': 'part', 'children': [{'name': '/dev/sdb', 'type': 'disk'}]}]}]}
        with mock.patch.object(self.installer, 'run', side_effect=[
                '/dev/mapper/live', json.dumps(data)]):
            self.assertEqual(self.installer.live_medium_device(), 'sdb')

    def test_unidentified_live_medium_stops_install_even_with_yes(self):
        installer = self.installer
        with mock.patch.object(installer, 'require_root'), \
                mock.patch.object(installer, 'require_tools'), \
                mock.patch.object(installer, 'live_medium_device', return_value=None), \
                mock.patch.object(installer, 'list_disks', return_value=[
                    {'path': '/dev/vda', 'live': False, 'size': '40G', 'model': 'fixture'}]), \
                mock.patch.object(installer, 'run', side_effect=AssertionError('Reached a disk command')):
            with self.assertRaises(installer.InstallerError):
                installer.install('/dev/vda', True)

    def test_mounted_partitions_swap_and_mapped_children_are_refused(self):
        import json
        installer = self.installer
        for mount in ('/', '/home', '[SWAP]'):
            data = {'blockdevices': [{'name': '/dev/vda', 'type': 'disk', 'mountpoints': [None],
                    'children': [{'name': '/dev/mapper/data', 'type': 'crypt', 'mountpoints': [mount]}]}]}
            with self.subTest(mount=mount), \
                    mock.patch.object(installer, 'live_medium_device', return_value='sr0'), \
                    mock.patch.object(installer, 'list_disks', return_value=[{'path': '/dev/vda', 'live': False}]), \
                    mock.patch.object(installer, 'run', return_value=json.dumps(data)):
                with self.assertRaises(installer.InstallerError):
                    installer.validate_target('/dev/vda')

    def test_unmounted_target_is_accepted_after_complete_probe(self):
        import json
        installer = self.installer
        info = {'path': '/dev/vda', 'live': False}
        data = {'blockdevices': [{'name': '/dev/vda', 'type': 'disk', 'mountpoints': [None],
                'children': [{'name': '/dev/vda1', 'type': 'part', 'mountpoints': []}]}]}
        with mock.patch.object(installer, 'live_medium_device', return_value='sr0'), \
                mock.patch.object(installer, 'list_disks', return_value=[info]), \
                mock.patch.object(installer, 'run', return_value=json.dumps(data)):
            self.assertEqual(installer.validate_target('/dev/vda'), info)

    def test_unknown_mount_state_is_refused(self):
        import json
        installer = self.installer
        with mock.patch.object(installer, 'live_medium_device', return_value='sr0'), \
                mock.patch.object(installer, 'list_disks', return_value=[{'path': '/dev/vda', 'live': False}]), \
                mock.patch.object(installer, 'run', return_value=json.dumps({
                    'blockdevices': [{'name': '/dev/vda', 'type': 'disk'}]})):
            with self.assertRaises(installer.InstallerError):
                installer.validate_target('/dev/vda')

    def test_ambiguous_backing_disks_are_not_treated_as_a_known_live_source(self):
        import json
        data = {'blockdevices': [{'name': '/dev/sda', 'type': 'disk'},
                                 {'name': '/dev/sdb', 'type': 'disk'}]}
        with mock.patch.object(self.installer, 'run', side_effect=[
                '/dev/mapper/live', json.dumps(data)]):
            self.assertIsNone(self.installer.live_medium_device())

    def test_existing_installation_mount_stops_before_partitioning(self):
        installer = self.installer
        with mock.patch.object(installer, 'require_root'), \
                mock.patch.object(installer, 'require_tools'), \
                mock.patch.object(installer, 'validate_target', return_value={'size': '40G', 'model': 'fixture'}), \
                mock.patch.object(installer, 'firmware_mode', return_value='uefi'), \
                mock.patch.object(installer, 'medium_kernel'), \
                mock.patch.object(installer, 'MOUNT') as mount, \
                mock.patch.object(installer, 'run', side_effect=AssertionError('Reached a disk command')):
            mount.is_mount.return_value = True
            with self.assertRaises(installer.InstallerError):
                installer.install('/dev/vda', True)

    def test_missing_kernel_stops_before_partitioning(self):
        installer = self.installer
        with mock.patch.object(installer, 'require_root'), \
                mock.patch.object(installer, 'require_tools'), \
                mock.patch.object(installer, 'validate_target', return_value={'size': '40G', 'model': 'fixture'}), \
                mock.patch.object(installer, 'firmware_mode', return_value='uefi'), \
                mock.patch.object(installer, 'medium_kernel', side_effect=installer.InstallerError('Missing kernel')), \
                mock.patch.object(installer, 'run', side_effect=AssertionError('Reached a disk command')):
            with self.assertRaises(installer.InstallerError):
                installer.install('/dev/vda', True)

if __name__ == '__main__':
    unittest.main()
