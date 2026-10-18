"""Verify that the QMP gesture driver releases touch contacts."""
import json
from pathlib import Path
import socket
import subprocess
import tempfile
import threading
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/vm-touch.py'


class VmTouch(unittest.TestCase):
    def test_swipe_sends_both_axes_and_releases_contact(self):
        with tempfile.TemporaryDirectory() as temp:
            path = str(Path(temp) / 'qmp')
            received = []
            with socket.socket(socket.AF_UNIX) as server:
                server.bind(path)
                server.listen(1)
                server.settimeout(5)

                def serve():
                    with server.accept()[0] as connection:
                        stream = connection.makefile('rwb', buffering=0)
                        stream.write(b'{"QMP": {}}\n')
                        for line in stream:
                            request = json.loads(line)
                            received.append(request)
                            stream.write(b'{"return": {}}\n')

                thread = threading.Thread(target=serve, daemon=True)
                thread.start()
                result = subprocess.run(['python3', str(SCRIPT), path, '400', '800',
                                         'swipe', '0', '0', '399', '799', '32'],
                                        capture_output=True, text=True, timeout=5)
                thread.join(5)
            self.assertEqual(result.returncode, 0, result.stderr)
            batches = [r['arguments']['events'] for r in received if r['execute'] == 'input-send-event']
            self.assertEqual(batches[0][-1]['data'], {'button': 'touch', 'down': True})
            coordinates = [e['data'] for e in batches[-2] if e['type'] == 'mtt' and e['data']['type'] == 'data']
            self.assertEqual([(e['axis'], e['value']) for e in coordinates], [('x', 32767), ('y', 32767)])
            self.assertEqual(batches[-1][0]['data']['tracking-id'], -1)
            self.assertFalse(batches[-1][-1]['data']['down'])

    def test_invalid_coordinates_do_not_connect(self):
        result = subprocess.run(['python3', str(SCRIPT), '/missing', '400', '800',
                                 'tap', '400', '0'], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('inside the framebuffer', result.stderr)
