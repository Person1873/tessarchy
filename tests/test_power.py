"""Power service availability and write guards; never changes host profiles."""
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('power_profiles', ROOT / 'shell/helpers/power_profiles.py')
power = importlib.util.module_from_spec(spec)
spec.loader.exec_module(power)


class FakeService:
    available = True
    active = 'balanced'
    writes = []
    fail = False

    def read(self):
        return {'available': self.available, 'profiles': ['power-saver', 'balanced'],
                'active': self.active, 'degraded': '', 'error': ''}

    def set(self, profile):
        if self.fail:
            raise PermissionError('Synthetic denial')
        self.writes.append(profile)
        self.active = profile


class PowerProfiles(unittest.TestCase):
    def setUp(self):
        self.service = FakeService()
        self.service.writes = []

    def request(self, action):
        return power.handle(action, lambda: self.service)

    def test_supported_mode_is_read_back_after_write(self):
        self.assertEqual(self.request('power-saver')['active'], 'power-saver')
        self.assertEqual(self.service.writes, ['power-saver'])

    def test_missing_service_has_no_default_active_profile(self):
        def missing():
            raise OSError('Synthetic unavailable service')
        state = power.handle('status', missing)
        self.assertFalse(state['available'])
        self.assertEqual(state['active'], '')
        self.assertEqual(state['profiles'], [])

    def test_unavailable_and_unsupported_modes_never_write(self):
        self.assertTrue(self.request('performance')['error'])
        self.service.available = False
        self.assertTrue(self.request('balanced')['error'])
        self.assertEqual(self.service.writes, [])

    def test_failed_write_keeps_reported_active_mode(self):
        self.service.fail = True
        state = self.request('power-saver')
        self.assertTrue(state['error'])
        self.assertEqual(state['active'], 'balanced')
        self.assertEqual(self.service.writes, [])

    def test_unknown_action_does_not_reach_service(self):
        called = []
        result = power.handle('--shell', lambda: called.append(True))
        self.assertTrue(result['error'])
        self.assertEqual(called, [])
