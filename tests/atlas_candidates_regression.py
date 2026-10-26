import csv
import sys
import unittest
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from detect_sprite_candidates import components,render

class CandidateTests(unittest.TestCase):
    def test_connected_components_and_source_coords(self):
        image=Image.new('RGBA',(40,30),(0,0,0,0))
        d=ImageDraw.Draw(image)
        d.rectangle((2,3,9,13),fill=(4,8,22,255))
        d.rectangle((23,19,33,28),fill=(20,44,99,255))
        boxes=components(image)
        self.assertEqual([(v[0],v[1],v[2],v[3]) for v in boxes],[(2,3,8,11),(23,19,11,10)])
    def test_never_verify_guesses(self):
        text,lua,count=render([ROOT/'assets/original/i0_8_77x152.png'])
        self.assertGreater(count,0)
        self.assertTrue(all(r['verification']=='unverified' for r in csv.DictReader(text.splitlines())))
        self.assertIn('NOT a proven sprite',lua)
    def test_repeatable_output(self):
        files=sorted((ROOT/'assets/original').glob('*.png'))
        csvtext,luatext,_=render(files)
        self.assertEqual(csvtext,(ROOT/'docs/ATLAS_CANDIDATOS.csv').read_text(encoding='utf8'))
        self.assertEqual(luatext,(ROOT/'src/atlas_candidates.lua').read_text(encoding='utf8'))

if __name__=='__main__':unittest.main()
