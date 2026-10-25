#!/usr/bin/env python3
"""Inventario reproduzivel dos PNGs extraidos (somente stdlib).

Uso: python tools/inventory_atlas.py --write
     python tools/inventory_atlas.py --verify
As dimensoes sao lidas do cabecalho PNG sem carregar/alterar pixels.
"""
import argparse
import csv
import hashlib
import io
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/original'
CATALOG = ROOT / 'docs/ATLAS_INVENTARIO.csv'
COLS = ['arquivo', 'largura', 'altura', 'bytes', 'sha256']


def inventory():
    rows = []
    for p in sorted(SOURCE.glob('*.png')):
        blob = p.read_bytes()
        if len(blob) < 24 or blob[:8] != b'\x89PNG\r\n\x1a\n' or blob[12:16] != b'IHDR':
            raise ValueError(f'PNG original invalido: {p.name}')
        w, h = struct.unpack('>II', blob[16:24])
        rows.append({'arquivo': p.name, 'largura': str(w), 'altura': str(h),
                     'bytes': str(len(blob)), 'sha256': hashlib.sha256(blob).hexdigest()})
    return rows


def csv_string(rows):
    b = io.StringIO(newline='')
    writer = csv.DictWriter(b, fieldnames=COLS, lineterminator='\n')
    writer.writeheader()
    writer.writerows(rows)
    return b.getvalue()


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument('--write', action='store_true')
    g.add_argument('--verify', action='store_true')
    args = ap.parse_args()
    rows = inventory()
    if not rows:
        raise SystemExit('Nao ha arquivos PNG no diretorio original')
    contents = csv_string(rows)
    if args.write:
        CATALOG.write_text(contents, encoding='utf-8')
        print(f'Inventario gerado: {len(rows)} atlas em {CATALOG.relative_to(ROOT)}')
    else:
        if not CATALOG.is_file() or CATALOG.read_text(encoding='utf-8') != contents:
            raise SystemExit('Inventario desatualizado ou arquivos modificados: execute --write')
        print(f'ATLAS OK: {len(rows)} arquivos, tamanhos e SHA-256 conferidos')


if __name__ == '__main__':
    main()
