import importlib.machinery
import importlib.util
from pathlib import Path
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
        with mock.patch.object(self.installer, 'list_disks', return_value=[]):
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


if __name__ == '__main__':
    unittest.main()
