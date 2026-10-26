#!/usr/bin/env python3
"""Build deterministic visual-review pages of UNVERIFIED alpha candidates.

Never crops sprites into gameplay assets, never decides the source animation
order, and never changes source PNGs. Each tile is a nearest-neighbor preview
of its exact atlas rectangle. Output is only an engineering aid.
"""
import argparse
import csv
import io
from pathlib import Path
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
INDEX=ROOT/'docs/ATLAS_CANDIDATOS.csv'
SOURCE=ROOT/'assets/original'
OUTPUT=ROOT/'docs/review_gallery'
COLS,ROWS=3,4
CELL_W,CELL_H=268,205
PAGE_W,PAGE_H=COLS*CELL_W,ROWS*CELL_H
BG=(20,29,42,255)
CHECK_A=(53,65,76,255)
CHECK_B=(72,82,90,255)

def candidates(path=INDEX):
    with path.open(encoding='utf-8',newline='') as f:
        rows=list(csv.DictReader(f))
    selected=[]
    for i,row in enumerate(rows):
        if row['review_priority']!='review':
            continue
        if row['verification']!='unverified':
            raise ValueError('Cannot turn candidate evidence into a verified sprite')
        name=row['atlas']
        if not name.endswith('.png') or '/' in name or '\\' in name or '..' in name:
            raise ValueError('Invalid source atlas path')
        x,y,w,h=(int(row[key]) for key in ('x','y','width','height'))
        if x<0 or y<0 or w<=0 or h<=0:
            raise ValueError('Invalid rectangle')
        selected.append((i+2,name,x,y,w,h))
    return selected

def checkerboard(width,height,tile=10):
    board=Image.new('RGBA',(width,height),CHECK_A)
    d=ImageDraw.Draw(board)
    for yy in range(0,height,tile):
        for xx in range(0,width,tile):
            if (xx//tile+yy//tile)%2:
                d.rectangle((xx,yy,min(xx+tile-1,width-1),min(yy+tile-1,height-1)),fill=CHECK_B)
    return board

def render(rows,atlas_path=SOURCE):
    """Returns list of RGBA pages and an index CSV; all source coords are exact."""
    pages=[]
    output=io.StringIO(newline='')
    writer=csv.writer(output,lineterminator='\n')
    writer.writerow(['page','slot','source_csv_line','atlas','x','y','width','height','verification'])
    loaded={}
    for n,(line,filename,x,y,w,h) in enumerate(rows):
        if n%(COLS*ROWS)==0:
            page=Image.new('RGBA',(PAGE_W,PAGE_H),BG)
            pages.append(page)
        page_num=len(pages)
        slot=n%(COLS*ROWS)
        xx=(slot%COLS)*CELL_W
        yy=(slot//COLS)*CELL_H
        draw=ImageDraw.Draw(page)
        draw.rectangle((xx+4,yy+4,xx+CELL_W-5,yy+CELL_H-5),outline=(74,109,130,255),width=2)
        draw.text((xx+10,yy+10),f'#{n+1:02d}  {filename}',fill=(227,238,247,255))
        draw.text((xx+10,yy+27),f'REVIEW ONLY / unverified / {x},{y}  {w}x{h}',fill=(239,183,103,255))
        if filename not in loaded:
            with Image.open(atlas_path/filename) as f:
                loaded[filename]=f.convert('RGBA')
        atlas=loaded[filename]
        iw,ih=atlas.size
        if x+w>iw or y+h>ih:
            raise ValueError(f'Outside original atlas bounds: {filename} {x},{y} {w}x{h}')
        crop=atlas.crop((x,y,x+w,y+h))
        area_w,area_h=CELL_W-20,CELL_H-61
        scale=min(area_w/w,area_h/h,10.0)
        sw,sh=max(1,int(w*scale)),max(1,int(h*scale))
        tile=checkerboard(area_w,area_h)
        tile_x=(area_w-sw)//2
        tile_y=(area_h-sh)//2
        crop=crop.resize((sw,sh),Image.Resampling.NEAREST)
        tile.alpha_composite(crop,(tile_x,tile_y))
        page.alpha_composite(tile,(xx+10,yy+45))
        writer.writerow((page_num,slot+1,line,filename,x,y,w,h,'unverified'))
    return pages,output.getvalue()

def main():
    arg=argparse.ArgumentParser(description=__doc__)
    arg.add_argument('--verify',action='store_true',help='verify generated visual pages and CSV without writing')
    args=arg.parse_args()
    entries=candidates()
    pages,index=render(entries)
    outputs={f'page_{n:02d}.png':page for n,page in enumerate(pages,1)}
    if args.verify:
        names={f.name for f in OUTPUT.glob('page_*.png')}
        if names!=set(outputs):
            raise SystemExit('Gallery pages are missing or have stale extras')
        for filename,page in outputs.items():
            with Image.open(OUTPUT/filename) as saved:
                if saved.convert('RGBA').tobytes()!=page.tobytes():
                    raise SystemExit('Stale preview image: '+filename)
        if (OUTPUT/'INDEX.csv').read_text(encoding='utf-8')!=index:
            raise SystemExit('Stale review index')
    else:
        OUTPUT.mkdir(parents=True,exist_ok=True)
        for old in OUTPUT.glob('page_*.png'):
            old.unlink()
        for filename,page in outputs.items():
            page.save(OUTPUT/filename,optimize=True)
        (OUTPUT/'INDEX.csv').write_text(index,encoding='utf-8')
    print(f'{"Verified" if args.verify else "Generated"}: {len(entries)} unverified regions on {len(pages)} review pages')

if __name__=='__main__':main()
