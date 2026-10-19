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
# The clip runs: assemble the mark (0..70), hold it with the wordmark (70..145),
# fade out (145..159). Hold the settled middle, not the end.
REST_FRACTION = 0.75


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
    rest = rest_frame(args.source)
    subprocess.run(['ffmpeg', '-v', 'error', '-nostdin', '-i', str(args.source), '-an',
                    '-vf', f'fps={FPS},select=eq(n\\,{rest}),scale={SIZE}:{SIZE}:flags=lanczos',
                    '-frames:v', '1', '-threads', '1', '-y', str(output / 'logo-rest.png')],
                   check=True)
    metadata = {'source_sha256': hashlib.sha256(args.source.read_bytes()).hexdigest(),
                'frames': FRAMES, 'rest_frame': rest, 'fps': FPS,
                'width': SIZE, 'height': SIZE, 'duration': 8}
    (output / 'animation.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print(f'Exported {FRAMES} video frames at {FPS} fps, {SIZE}x{SIZE}; rest frame {rest}')


def frame_lumas(source: Path) -> list[int]:
    """Mean luma of each sampled frame (scaling to 1x1 averages the frame)."""
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-nostdin', '-i', str(source),
                                   '-an', '-vf', f'fps={FPS},scale=1:1', '-frames:v', str(FRAMES),
                                   '-f', 'rawvideo', '-pix_fmt', 'gray', '-'], stdin=subprocess.DEVNULL)
    if len(raw) != FRAMES:
        raise RuntimeError(f'Expected {FRAMES} sampled frames, got {len(raw)}')
    return list(raw)


def rest_frame(source: Path) -> int:
    """The clip's settled frame: mark and wordmark drawn, fade-out not started.

    Chosen as a fraction of the clip rather than by peak brightness — the
    brightest frames are the assembled mark BEFORE its wordmark appears, and
    the user-facing resting image needs both. The brightness guard below is the
    safety net: if the clip is re-cut so that this frame lands in the fade-out
    or before the wordmark, the export fails loudly instead of shipping a
    Plymouth theme that settles on an empty screen.
    """
    index = round(FRAMES * REST_FRACTION)
    lumas = frame_lumas(source)
    if lumas[index] < 0.8 * max(lumas):
        raise RuntimeError(
            f'Frame {index} (luma {lumas[index]}) is not a settled frame of this clip '
            f'(peak {max(lumas)}); re-cut the clip or move REST_FRACTION')
    return index


if __name__ == '__main__':
    main()
