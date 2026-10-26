#!/usr/bin/env python3
"""Export developer-marked, UNVERIFIED rectangles without rescaling source PNGs.

Usage: python tools/export_atlas_regions.py /path/to/atlas_regions.csv
Outputs are derived resources, NOT verified original sprites.
"""
import argparse
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ATLAS_DIR = ROOT / 'assets' / 'original'
DEFAULT_OUT = ROOT / 'assets' / 'derived' / 'manual'
NAME = re.compile(r'^[A-Za-z0-9_-]+\.png$')
FIELDS = ('atlas', 'x', 'y', 'width', 'height', 'verification')


def export_regions(csv_path: Path, atlas_dir: Path, output_dir: Path, *, dry_run=False):
    from PIL import Image
    output = []
    with csv_path.open(encoding='utf-8-sig', newline='') as fp:
        reader = csv.DictReader(fp)
        if tuple(reader.fieldnames or ()) != FIELDS:
            raise ValueError('CSV invalido: cabecalho esperado '+','.join(FIELDS))
        for line, row in enumerate(reader, 2):
            name = row['atlas']
            if not NAME.fullmatch(name):
                raise ValueError(f'Linha {line}: nome de atlas invalido')
            if row['verification'] != 'unverified':
                raise ValueError(f'Linha {line}: estado de verificacao inesperado')
            try:
                x, y, w, h = (int(row[k]) for k in ('x', 'y', 'width', 'height'))
            except (ValueError, TypeError) as exc:
                raise ValueError(f'Linha {line}: coordenadas invalidas') from exc
            if min(x, y) < 0 or min(w, h) <= 0:
                raise ValueError(f'Linha {line}: recorte de dimensoes invalidas')
            source = atlas_dir / name
            with Image.open(source) as image:
                if x+w > image.width or y+h > image.height:
                    raise ValueError(f'Linha {line}: recorte fora dos limites de {name}')
                target = output_dir / f'{Path(name).stem}_x{x}_y{y}_{w}x{h}.png'
                if target.exists():
                    raise FileExistsError(f'Linha {line}: destino existente: {target}')
                if not dry_run:
                    output_dir.mkdir(parents=True, exist_ok=True)
                    image.crop((x, y, x+w, y+h)).save(target)
                output.append(target)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('csv', type=Path, help='atlas_regions.csv gerado no save LÖVE')
    parser.add_argument('--atlas-dir', type=Path, default=ATLAS_DIR)
    parser.add_argument('--out', type=Path, default=DEFAULT_OUT)
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    for path in export_regions(args.csv, args.atlas_dir, args.out, dry_run=args.dry_run):
        print(('VALIDADO ' if args.dry_run else 'EXPORTADO ') + str(path))


if __name__ == '__main__':
    main()
