#!/usr/bin/env python3
"""Verify pixel-exact provenance of the 21 currently-used prototype sprites.

Authoritative evidence: RGBA equality with a rectangle in the supplied source
PNG, not a reconstruction of original animation tables or game logic.
"""
import csv
import re
from pathlib import Path
from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parent.parent
CSV=ROOT/'docs/ATLAS_SPRITES_VERIFICADOS.csv'
LUA=ROOT/'src/atlas_catalog.lua'
ATLAS=ROOT/'assets/original'
SPRITES=ROOT/'assets/sprites'
NAME=re.compile(r'^[A-Za-z0-9_-]+\.png$')
LUA_LINE=re.compile(r"\s*([a-z0-9_]+)=\{atlas='([a-zA-Z0-9_-]+\.png)',x=(\d+),y=(\d+),w=(\d+),h=(\d+)\},")


def verify(csv_file=CSV, lua_file=LUA, source_dir=ATLAS, sprites_dir=SPRITES):
    with csv_file.open(encoding='utf-8',newline='') as f:
        reader=csv.DictReader(f)
        expected=['sprite','atlas','x','y','width','height','verification']
        if reader.fieldnames!=expected:
            raise ValueError('Cabecalho CSV incorreto')
        rows=list(reader)
    records={}
    for line,row in enumerate(rows,2):
        sprite=row['sprite'];atlas=row['atlas']
        if not re.fullmatch(r'[a-z0-9_]+',sprite) or not NAME.fullmatch(atlas) or sprite in records:
            raise ValueError(f'Linha {line}: nome invalido ou duplicado')
        if row['verification']!='pixel-exact':
            raise ValueError(f'Linha {line}: verificacao desconhecida')
        try:
            coords=tuple(int(row[key]) for key in ('x','y','width','height'))
        except (ValueError,TypeError) as err:
            raise ValueError(f'Linha {line}: coordenadas invalidas') from err
        x,y,w,h=coords
        if x<0 or y<0 or w<=0 or h<=0:
            raise ValueError(f'Linha {line}: retangulo invalido')
        atlas_path=source_dir/atlas
        sprite_path=sprites_dir/(sprite+'.png')
        with Image.open(atlas_path) as src, Image.open(sprite_path) as dst:
            if x+w>src.width or y+h>src.height or (w,h)!=dst.size:
                raise ValueError(f'Linha {line}: imagem fora do atlas ou dimensao divergente')
            src_crop=src.convert('RGBA').crop((x,y,x+w,y+h))
            actual=dst.convert('RGBA')
            if ImageChops.difference(src_crop,actual).getbbox():
                raise ValueError(f'Linha {line}: pixel RGBA divergente: {sprite}')
        records[sprite]=(atlas,x,y,w,h)
    lua_records={}
    for line in lua_file.read_text(encoding='utf8').splitlines():
        m=LUA_LINE.fullmatch(line)
        if m:
            name,atlas,x,y,w,h=m.groups()
            if name in lua_records:
                raise ValueError(f'Catalogo Lua com sprite duplicado: {name}')
            lua_records[name]=(atlas,int(x),int(y),int(w),int(h))
    if not records or records!=lua_records:
        raise ValueError('Catalogo Lua e CSV nao coincidem')
    if set(records)!={f.stem for f in sprites_dir.glob('*.png')}:
        raise ValueError('Catalogo nao cobre todos os sprites do prototipo')
    return len(records),len(set(a for a,*_ in records.values()))


if __name__=='__main__':
    count,atlases=verify()
    print(f'PIXEL-EXACT ATLAS PROVENANCE VERIFIED: {count} sprites, {atlases} original PNGs')
