#!/usr/bin/env python3
import csv
import tempfile
import unittest
from pathlib import Path
from PIL import Image
from tools.export_atlas_regions import export_regions, FIELDS


class ExportTest(unittest.TestCase):
    def test_exact_pixel_and_rejections(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            src, dst = root/'original', root/'out'
            src.mkdir()
            im = Image.new('RGBA', (9, 7))
            for y in range(7):
                for x in range(9):
                    im.putpixel((x,y),(x*20,y*30,(x+y)*8,255))
            im.save(src/'i0_1_9x7.png')
            path=root/'regions.csv'
            def records(rows):
                with path.open('w', newline='') as f:
                    w=csv.writer(f);w.writerow(FIELDS);w.writerows(rows)
            records([('i0_1_9x7.png',2,3,4,2,'unverified')])
            output=export_regions(path,src,dst)
            self.assertEqual(len(output),1)
            with Image.open(output[0]) as crop:
                self.assertEqual(crop.size,(4,2))
                self.assertEqual(crop.getpixel((0,0)),im.getpixel((2,3)))
                self.assertEqual(crop.getpixel((3,1)),im.getpixel((5,4)))
            with self.assertRaises(FileExistsError):
                export_regions(path,src,dst)
            records([('i0_1_9x7.png',8,0,4,2,'unverified')])
            with self.assertRaises(ValueError):
                export_regions(path,src,dst)
            records([('../secret.png',0,0,1,1,'unverified')])
            with self.assertRaises(ValueError):
                export_regions(path,src,dst)
            records([('i0_1_9x7.png',0,0,1,1,'verified')])
            with self.assertRaises(ValueError):
                export_regions(path,src,dst)


if __name__ == '__main__':
    unittest.main()
