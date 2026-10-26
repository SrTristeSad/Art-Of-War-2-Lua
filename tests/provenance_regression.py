"""Deliberate mutation must be noticed before a claim of verified 1:1 pixels."""
import shutil
import tempfile
import unittest
from pathlib import Path
from PIL import Image
from tools.verify_sprite_provenance import verify, ROOT

class ProvenanceTests(unittest.TestCase):
    def test_exact_pixels(self):
        self.assertEqual(verify()[0],21)

    def test_pixel_changed_detection(self):
        with tempfile.TemporaryDirectory() as d:
            temp=Path(d)
            sprites=temp/'sprites';sprites.mkdir()
            for file in (ROOT/'assets/sprites').glob('*.png'):
                shutil.copyfile(file,sprites/file.name)
            path=sprites/'blue_infantry.png'
            with Image.open(path) as image:
                image=image.convert('RGBA')
                image.putpixel((0,0),(17,33,99,255))
                image.save(path)
            with self.assertRaisesRegex(ValueError,'pixel RGBA divergente'):
                verify(sprites_dir=sprites)

if __name__=='__main__':unittest.main()
