#!/usr/bin/env python3
"""Render NON-CANONICAL sprite sequence candidates from exported F2 CSV.

Always use original source atlas pixels; do not alter originals, assert a J2ME
frame order, or activate candidates in the playable game.
"""
from __future__ import annotations
import argparse
import csv
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HEADER = ['sequence', 'frame', 'atlas', 'x', 'y', 'width', 'height', 'fps', 'verification']
NAME = re.compile(r'^[A-Za-z0-9_-]{1,64}$')
ATLAS = re.compile(r'^[A-Za-z0-9_-]+\.png$')


def load_candidates(source: Path, original_dir: Path):
    try:
        from PIL import Image
    except ImportError as exc:
        raise RuntimeError('Pillow required: python -m pip install Pillow') from exc
    groups = defaultdict(list)
    with source.open(newline='', encoding='utf-8-sig') as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames != HEADER:
            raise ValueError('Incorrect sequence CSV header')
        for row in reader:
            name = row['sequence']
            atlas = row['atlas']
            if not NAME.fullmatch(name or '') or not ATLAS.fullmatch(atlas or ''):
                raise ValueError('Unsafe sequence or atlas name')
            if row['verification'] != 'unverified':
                raise ValueError('Candidates must remain marked unverified')
            try:
                idx = int(row['frame'])
                x, y, w, h = (int(row[k]) for k in ('x', 'y', 'width', 'height'))
                fps = int(row['fps'])
            except (TypeError, ValueError) as exc:
                raise ValueError('Invalid frame coordinates or FPS') from exc
            if not (1 <= idx <= 64 and 1 <= fps <= 30 and x >= 0 and y >= 0 and w > 0 and h > 0):
                raise ValueError('Invalid frame rectangle, number, or FPS')
            path = original_dir / atlas
            if not path.is_file():
                raise ValueError(f'Original atlas not found: {atlas}')
            with Image.open(path) as atlas_image:
                if x + w > atlas_image.width or y + h > atlas_image.height:
                    raise ValueError(f'Frame {name}:{idx} exceeds {atlas}')
            groups[name].append({'index': idx, 'atlas': atlas, 'rect': (x, y, x+w, y+h), 'fps': fps})
    if not groups:
        raise ValueError('No candidate frames')
    for name, frames in groups.items():
        frames.sort(key=lambda fr: fr['index'])
        if len(frames) > 64 or [fr['index'] for fr in frames] != list(range(1, len(frames)+1)):
            raise ValueError(f'Nonconsecutive or repeated frame numbers in {name}')
        if len({fr['fps'] for fr in frames}) > 1:
            raise ValueError(f'Inconsistent FPS in {name}')
    return groups


def render_candidates(groups, original_dir: Path, target_dir: Path, force: bool = False):
    from PIL import Image, ImageDraw
    target_dir.mkdir(parents=True, exist_ok=True)
    outpaths = []
    for name, frames in sorted(groups.items()):
        path = target_dir / f'{name}.png'
        if path.exists() and not force:
            raise FileExistsError(f'Preview exists: {path}; use --force to overwrite')
        cell_w, cell_h = 104, 130
        image = Image.new('RGB', (len(frames)*cell_w, cell_h), (31, 35, 43))
        draw = ImageDraw.Draw(image)
        for n, frame in enumerate(frames):
            with Image.open(original_dir / frame['atlas']) as atlas:
                crop = atlas.convert('RGBA').crop(frame['rect'])
            scale = min(96/crop.width, 96/crop.height)
            w, h = max(1, int(crop.width*scale)), max(1, int(crop.height*scale))
            sprite = crop.resize((w, h), resample=Image.Resampling.NEAREST)
            x = n*cell_w+(cell_w-w)//2
            y = (96-h)//2+22
            for cy in range(0, 96, 8):
                for cx in range(0, 96, 8):
                    c = (54, 58, 66) if (cx//8+cy//8)%2==0 else (73, 78, 86)
                    draw.rectangle((n*cell_w+4+cx,22+cy,n*cell_w+11+cx,29+cy),fill=c)
            image.paste(sprite, (x,y), sprite)
            draw.text((n*cell_w+6, 5), f'Frame {n+1}', fill=(230,239,241))
            draw.text((n*cell_w+6,118), f'{frame["fps"]}fps  UNVERIFIED', fill=(243,180,125))
        image.save(path)
        outpaths.append(path)
    return outpaths


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('csv_file', type=Path, help='F2 export: atlas_sequences_candidates.csv')
    parser.add_argument('--dry-run', action='store_true', help='Only validate; do not create previews')
    parser.add_argument('--force', action='store_true', help='Overwrite previously generated preview PNGs')
    parser.add_argument('--output-dir', type=Path, default=ROOT/'assets/derived/sequence_previews')
    args = parser.parse_args()
    groups = load_candidates(args.csv_file, ROOT/'assets/original')
    for name, frames in sorted(groups.items()):
        print(f'{name}: {len(frames)} frames, {frames[0]["fps"]} fps, unverified')
    if not args.dry_run:
        for path in render_candidates(groups, ROOT/'assets/original', args.output_dir, args.force):
            print(f'Preview: {path}')


if __name__ == '__main__':
    main()
