#!/usr/bin/env python3
"""Read supported power profiles and apply only explicitly requested modes."""
import json
import sys

PROFILES = ('power-saver', 'balanced', 'performance')


class Service:
    def __init__(self):
        from gi.repository import Gio, GLib
        self.Gio, self.GLib = Gio, GLib
        self.bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        self.name = ''

    def read(self):
        for name, path in [('org.freedesktop.UPower.PowerProfiles', '/org/freedesktop/UPower/PowerProfiles'),
                           ('net.hadess.PowerProfiles', '/net/hadess/PowerProfiles')]:
            try:
                properties = self.bus.call_sync(name, path, 'org.freedesktop.DBus.Properties', 'GetAll',
                    self.GLib.Variant('(s)', (name,)), None, self.Gio.DBusCallFlags.NONE, 1500, None).unpack()[0]
                profiles = [p['Profile'] for p in properties.get('Profiles', []) if p.get('Profile') in PROFILES]
                active = properties.get('ActiveProfile', '')
                self.name, self.path = name, path
                return {'available': bool(profiles) and active in profiles, 'profiles': profiles, 'active': active,
                        'degraded': properties.get('PerformanceDegraded', ''), 'error': ''}
            except Exception:
                continue
        raise RuntimeError('Power profile service unavailable')

    def set(self, profile):
        self.bus.call_sync(self.name, self.path, 'org.freedesktop.DBus.Properties', 'Set',
            self.GLib.Variant('(ssv)', (self.name, 'ActiveProfile', self.GLib.Variant('s', profile))),
            None, self.Gio.DBusCallFlags.NONE, 5000, None)


def handle(action='status', factory=Service):
    state = {'available': False, 'profiles': [], 'active': '', 'degraded': '', 'error': ''}
    try:
        if action not in ('status', *PROFILES):
            raise ValueError('Unknown power profile')
        service = factory()
        state = service.read()
        if action != 'status':
            if not state['available'] or action not in state['profiles']:
                raise ValueError('Profile not supported')
            service.set(action)
            state = service.read()
    except Exception:
        if action != 'status':
            state['error'] = 'Could not change power mode. Check service support and authorization.'
    return state


if __name__ == '__main__':
    print(json.dumps(handle(sys.argv[1] if len(sys.argv) == 2 else 'status')))
