#!/usr/bin/env python3
"""Send genuine multitouch gestures through a QEMU QMP socket (VM_TOUCH=1)."""
import argparse
import json
import socket
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('socket', help='VM_QMP Unix socket')
    parser.add_argument('width', type=int)
    parser.add_argument('height', type=int)
    parser.add_argument('gesture', choices=['tap', 'swipe'])
    parser.add_argument('coordinates', type=int, nargs='+', help='X Y or X1 Y1 X2 Y2 milliseconds')
    args = parser.parse_args()
    points = args.coordinates
    if args.width < 2 or args.height < 2 or len(points) != (2 if args.gesture == 'tap' else 5):
        parser.error('Supply valid dimensions and coordinates for the gesture')
    for x, y in zip(points[:4:2], points[1:4:2]):
        if not 0 <= x < args.width or not 0 <= y < args.height:
            parser.error('Coordinates must be inside the framebuffer')
    if args.gesture == 'swipe' and not 16 <= points[4] <= 10000:
        parser.error('Swipe duration must be between 16 and 10000 milliseconds')
    with socket.socket(socket.AF_UNIX) as connection:
        connection.settimeout(5)
        connection.connect(args.socket)
        stream = connection.makefile('rwb', buffering=0)
        stream.readline()

        def call(command, arguments):
            stream.write((json.dumps({'execute': command, 'arguments': arguments}) + '\n').encode())
            while True:
                result = json.loads(stream.readline())
                if 'error' in result:
                    raise RuntimeError(result['error']['desc'])
                if 'return' in result:
                    return result['return']

        call('qmp_capabilities', {})

        def event(kind, x, y):
            events = [{'type': 'mtt', 'data': {'type': kind, 'slot': 0,
                'tracking-id': -1 if kind == 'end' else 1, 'axis': 'x', 'value': 0}}]
            if kind != 'end':
                for axis, value, size in [('x', x, args.width), ('y', y, args.height)]:
                    events.append({'type': 'mtt', 'data': {'type': 'data',
                        'slot': 0, 'tracking-id': 1, 'axis': axis, 'value': round(value * 32767 / (size - 1))}})
            if kind in ('begin', 'end'):
                events.append({'type': 'btn', 'data': {'button': 'touch', 'down': kind == 'begin'}})
            call('input-send-event', {'events': events})

        event('begin', *points[:2])
        try:
            if args.gesture == 'swipe':
                x1, y1, x2, y2, duration = points
                steps = max(2, duration // 16)
                for step in range(1, steps + 1):
                    time.sleep(duration / steps / 1000)
                    event('update', x1 + (x2 - x1) * step / steps, y1 + (y2 - y1) * step / steps)
            else:
                time.sleep(.08)
        finally:
            event('end', *(points[2:4] if args.gesture == 'swipe' else points[:2]))
        time.sleep(.15)


if __name__ == '__main__':
    main()
