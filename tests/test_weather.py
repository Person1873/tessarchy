"""Weather: location resolution, code mapping and the offline cache."""
from pathlib import Path
import json
import tempfile
import types
import unittest

ROOT = Path(__file__).resolve().parents[1]
weather = types.ModuleType('test_weather_helper')
exec(compile((ROOT / 'shell/helpers/weather.py').read_text(), 'weather.py', 'exec'), weather.__dict__)


def fake_fetch(geocode=None, forecast=None, ip=None):
    """URL-dispatching stub: each callable receives the parsed query dict."""
    calls = []

    def fetch(url, timeout=8):
        calls.append(url)
        if 'geocoding-api' in url:
            if geocode is None:
                raise OSError('no geocoder')
            return geocode
        if 'ipapi' in url or 'ipwho' in url:
            if ip is None:
                raise OSError('no geolocator')
            return ip
        if forecast is None:
            raise OSError('no forecast')
        return forecast
    fetch.calls = calls
    return fetch


GEO = {'results': [{'name': 'Miami', 'admin1': 'Florida', 'latitude': 25.77, 'longitude': -80.19}]}
IP = {'city': 'Miami', 'region': 'Florida', 'latitude': 25.77, 'longitude': -80.19}
FORECAST = {'current': {'temperature_2m': 26.5, 'weather_code': 3, 'is_day': 1}}


class WeatherHelper(unittest.TestCase):
    def cache(self):
        handle = tempfile.NamedTemporaryFile(suffix='.json', delete=False)
        handle.close()
        return Path(handle.name)

    def test_weather_codes_map_to_descriptions_and_icons(self):
        self.assertEqual(weather.describe(0, True), ('Clear sky', 'weather-sun'))
        self.assertEqual(weather.describe(0, False), ('Clear sky', 'weather-moon'))
        self.assertEqual(weather.describe(1)[1], 'weather-partly')
        self.assertEqual(weather.describe(3), ('Overcast', 'weather-cloud'))
        self.assertEqual(weather.describe(45)[1], 'weather-fog')
        self.assertEqual(weather.describe(61)[1], 'weather-rain')
        self.assertEqual(weather.describe(80)[1], 'weather-rain')
        self.assertEqual(weather.describe(71)[1], 'weather-snow')
        self.assertEqual(weather.describe(95), ('Thunderstorm', 'weather-storm'))
        self.assertEqual(weather.describe(1234), ('Unknown', 'weather-rain'))

    def test_settings_default_to_auto_and_parse_the_shell_ini(self):
        self.assertEqual(weather.read_config('/nonexistent/shell.ini'), {'place': 'auto', 'units': 'metric'})
        path = Path(tempfile.mkdtemp()) / 'shell.ini'
        path.write_text('[Shell]\nlayoutMode=desktop\nweatherPlace=Berlin\nweatherUnits=imperial\n[Other]\nweatherPlace=Ignored\n')
        self.assertEqual(weather.read_config(str(path)), {'place': 'Berlin', 'units': 'imperial'})
        path.write_text('[Shell]\nweatherUnits=nonsense\n')
        self.assertEqual(weather.read_config(str(path))['units'], 'metric')

    def test_named_place_geocodes_and_reports_conditions(self):
        cache = self.cache()
        fetch = fake_fetch(geocode=GEO, forecast=FORECAST)
        state = weather.summarize({'place': 'Miami', 'units': 'metric'}, fetch, cache, now=1000)
        self.assertTrue(state['ok'])
        self.assertEqual(state['place'], 'Miami, Florida')
        self.assertEqual(state['unit'], '°C')
        self.assertEqual(state['description'], 'Overcast')
        self.assertEqual(state['icon'], 'weather-cloud')
        self.assertFalse(state['stale'])
        self.assertTrue(any('temperature_unit=celsius' in url for url in fetch.calls))
        self.assertTrue(json.loads(cache.read_text())['observation']['ok'])

    def test_imperial_units_and_auto_location_by_ip(self):
        cache = self.cache()
        fetch = fake_fetch(ip=IP, forecast={'current': {'temperature_2m': 79.7, 'weather_code': 0, 'is_day': 0}})
        state = weather.summarize({'place': 'auto', 'units': 'imperial'}, fetch, cache, now=1000)
        self.assertEqual(state['unit'], '°F')
        self.assertEqual(state['icon'], 'weather-moon')
        self.assertEqual(state['place'], 'Miami, Florida')
        self.assertTrue(any('temperature_unit=fahrenheit' in url for url in fetch.calls))

    def test_auto_location_is_cached_so_a_flaky_geolocator_is_not_re_resolved(self):
        cache = self.cache()
        first = fake_fetch(ip=IP, forecast=FORECAST)
        weather.summarize({'place': 'auto', 'units': 'metric'}, first, cache, now=1000)
        second = fake_fetch(ip=None, forecast=FORECAST)  # geolocator now broken
        state = weather.summarize({'place': 'auto', 'units': 'metric'}, second, cache, now=1000)
        self.assertTrue(state['ok'])
        self.assertFalse(any('ipapi' in url or 'ipwho' in url for url in second.calls))

    def test_offline_serves_the_last_observation_then_reports_failure(self):
        cache = self.cache()
        weather.summarize({'place': 'auto', 'units': 'metric'}, fake_fetch(ip=IP, forecast=FORECAST), cache, now=1000)
        offline = fake_fetch(ip=IP, forecast=None)
        state = weather.summarize({'place': 'auto', 'units': 'metric'}, offline, cache, now=2000)
        self.assertTrue(state['ok'])
        self.assertTrue(state['stale'])
        self.assertEqual(state['description'], 'Overcast')
        empty = self.cache()
        empty.unlink()
        state = weather.summarize({'place': 'auto', 'units': 'metric'}, fake_fetch(ip=None, forecast=None), empty, now=2000)
        self.assertFalse(state['ok'])
        self.assertTrue(state['error'])

    def test_unreadable_cache_is_ignored(self):
        cache = self.cache()
        cache.write_text('{not json')
        fetch = fake_fetch(ip=IP, forecast=FORECAST)
        state = weather.summarize({'place': 'auto', 'units': 'metric'}, fetch, cache, now=1000)
        self.assertTrue(state['ok'])
        self.assertFalse(state['stale'])


if __name__ == '__main__':
    unittest.main()
