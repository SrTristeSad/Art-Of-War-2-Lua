#!/usr/bin/env python3
"""List/extract JAR resources and find concatenated PNGs (stock-library only).
Usage: python tools/inventory_jar.py path/to/original.jar
Never runs code from the JAR.
"""
import sys, hashlib, json, zipfile, struct
from pathlib import Path
PNG=b'\x89PNG\r\n\x1a\n'

def main(src):
    src=Path(src)
    out=src.parent/(src.stem+'_re_inventory')
    out.mkdir(parents=True,exist_ok=True)
    manifest=[]
    with zipfile.ZipFile(src) as jar:
        for name in jar.namelist():
            if name.endswith('/'):continue
            blob=jar.read(name)
            report={'name':name,'size':len(blob),'sha256':hashlib.sha256(blob).hexdigest(),
                    'kind':'class' if name.endswith('.class') else 'resource', 'png_offsets':[]}
            offset=0
            while True:
                pos=blob.find(PNG,offset)
                if pos<0:break
                report['png_offsets'].append(pos)
                # Parse PNG chunks to find IEND, without trusting offsets blindly.
                p=pos+8
                try:
                    while p+12<=len(blob):
                        n=int.from_bytes(blob[p:p+4],'big')
                        if n>50_000_000 or p+12+n>len(blob): break
                        kind=blob[p+4:p+8];p+=12+n
                        if kind==b'IEND':
                            target=out/'png'/('%s__%d.png'%(name.replace('/','_'),pos))
                            target.parent.mkdir(parents=True,exist_ok=True)
                            target.write_bytes(blob[pos:p]);break
                except (ValueError,IndexError):pass
                offset=pos+len(PNG)
            if not name.endswith('.class'):
                target=out/'resources'/name
                if '..' in Path(name).parts or Path(name).is_absolute(): continue
                target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(blob)
            manifest.append(report)
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
    print('Arquivos analisados:',len(manifest),'Classes:',sum(f['kind']=='class' for f in manifest),'Destino:',out)

if __name__=='__main__':
    if len(sys.argv)<2: raise SystemExit('Uso: python tools/inventory_jar.py original.jar')
    main(sys.argv[1])
