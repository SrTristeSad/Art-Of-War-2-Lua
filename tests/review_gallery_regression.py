import hashlib
import sys
import unittest
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from build_review_gallery import candidates,render

class GalleryTests(unittest.TestCase):
    def test_inventory_complete_and_unverified(self):
        boxes=candidates()
        self.assertEqual(len(boxes),72)
        pages,index=render(boxes)
        self.assertEqual(len(pages),6)
        self.assertEqual(len(index.strip().splitlines()),73)
        self.assertEqual(index.count(',unverified\n'),72)
        self.assertTrue(all(page.size==(804,820) for page in pages))
    def test_readonly_original_source(self):
        f=ROOT/'assets/original/i0_8_77x152.png'
        original=hashlib.sha256(f.read_bytes()).hexdigest()
        render(candidates())
        self.assertEqual(hashlib.sha256(f.read_bytes()).hexdigest(),original)
    def test_nearest_neighbor_copy_of_rgb_and_alpha(self):
        from tempfile import TemporaryDirectory
        with TemporaryDirectory() as temp:
            folder=Path(temp)
            image=Image.new('RGBA',(3,2),(0,0,0,0))
            image.putpixel((0,0),(250,20,30,255))
            image.putpixel((1,0),(20,210,40,255))
            image.save(folder/'tiny.png')
            pages,_=render([(2,'tiny.png',0,0,3,2)],folder)
            self.assertEqual(len(pages),1)
            self.assertEqual(pages[0].getpixel((10+(248-30)//2,45+(144-20)//2)),(250,20,30,255))
    def test_reject_out_of_bounds(self):
        with self.assertRaises(ValueError):
            render([(2,'i0_8_77x152.png',75,0,5,10)])

if __name__=='__main__':unittest.main()
