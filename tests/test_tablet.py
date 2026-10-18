"""Tablet package/service preflight and shared desktop-session lifecycle."""
import importlib.machinery
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('tablet_readiness', str(ROOT / 'session/tessarchy-readiness'))
spec = importlib.util.spec_from_loader(loader.name, loader)
readiness = importlib.util.module_from_spec(spec)
loader.exec_module(readiness)


class TabletReadiness(unittest.TestCase):
    def run_fixture(self, packages, active):
        def run(args):
            if args == ['pacman', '-Qq']:
                return SimpleNamespace(returncode=0, stdout='\n'.join(packages))
            self.assertEqual(args[:2], ['systemctl', 'is-active'])
            return SimpleNamespace(returncode=0 if args[2] in active else 3, stdout='')
        return readiness.inspect(run, 'x86_64')

    def test_complete_package_profile_and_single_manager(self):
        result = self.run_fixture(readiness.PACKAGES, {'NetworkManager.service', 'bluetooth.service'})
        self.assertEqual(result['missingPackages'], [])
        self.assertFalse(result['networkManagerConflict'])
        self.assertTrue(result['supportedArchitecture'])

    def test_missing_packages_and_competing_network_managers_are_reported(self):
        result = self.run_fixture([], {'NetworkManager.service', 'systemd-networkd.service'})
        self.assertIn('pipewire-audio', result['missingPackages'])
        self.assertTrue(result['networkManagerConflict'])

    def test_missing_tools_do_not_produce_a_successful_preflight(self):
        result = readiness.inspect(lambda _: None, 'aarch64')
        self.assertFalse(result['supportedArchitecture'])
        self.assertTrue(result['missingPackages'])
        self.assertFalse(result['services']['NetworkManager'])

    def test_live_image_and_installed_profile_include_desktop_basics(self):
        image = set((ROOT / 'iso/packages.x86_64').read_text().splitlines())
        recipe = (ROOT / 'packaging/tessarchy-tablet/PKGBUILD').read_text()
        for package in readiness.PACKAGES:
            if package == 'tessarchy-session':
                continue
            self.assertIn(package, image)
            self.assertIn("'" + package + "'", recipe)
