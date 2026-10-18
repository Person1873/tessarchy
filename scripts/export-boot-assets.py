#!/usr/bin/env python3
"""Convert the supplied eight-second power-on video into bounded Plymouth frames."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
FPS, FRAMES, SIZE = 20, 160, 480


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--source', type=Path, default=ROOT / 'session/boot/power-on.mp4')
    args = parser.parse_args()
    output = args.output.absolute()
    if output.exists() or output.is_symlink():
        parser.error('Choose a new output directory')
    if not args.source.is_file():
        parser.error('Power-on video is missing')
    for tool in ('ffmpeg', 'ffprobe'):
        if not shutil.which(tool):
            parser.error(tool + ' is required')
    probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_format',
                       '-show_streams', '-of', 'json', str(args.source)]))
    video = next((s for s in probe['streams'] if s['codec_type'] == 'video'), None)
    if not video or video['width'] != video['height'] or abs(float(probe['format']['duration']) - 8) > .1:
        parser.error('Expected the supplied eight-second square animation')
    output.mkdir(parents=True)
    subprocess.run(['ffmpeg', '-v', 'error', '-nostdin', '-i', str(args.source), '-an',
                    '-vf', f'fps={FPS},scale={SIZE}:{SIZE}:flags=lanczos', '-frames:v', str(FRAMES),
                    '-start_number', '0', '-threads', '1', str(output / 'logo-%d.png')], check=True)
    if len(list(output.glob('logo-*.png'))) != FRAMES:
        raise RuntimeError('Incomplete animation export')
    metadata = {'source_sha256': hashlib.sha256(args.source.read_bytes()).hexdigest(),
                'frames': FRAMES, 'fps': FPS, 'width': SIZE, 'height': SIZE, 'duration': 8}
    (output / 'animation.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print(f'Exported {FRAMES} video frames at {FPS} fps, {SIZE}x{SIZE}')


if __name__ == '__main__':
    main()
