import importlib.machinery
import importlib.util
from pathlib import Path
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


if __name__ == '__main__':
    unittest.main()
