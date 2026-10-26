import importlib.util
import tempfile
import unittest
from pathlib import Path
from PIL import Image

SPEC = importlib.util.spec_from_file_location('sequence_preview', Path(__file__).resolve().parents[1] / 'tools/preview_atlas_sequences.py')
M = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(M)

class PreviewTest(unittest.TestCase):
    def test_load_render_and_reject_bad_csv(self):
        with tempfile.TemporaryDirectory() as temp:
            t = Path(temp)
            original = t / 'original'
            original.mkdir()
            Image.new('RGBA', (24, 24), (255, 30, 20, 200)).save(original / 'safe.png')
            csv_file = t / 'candidates.csv'
            csv_file.write_text(','.join(M.HEADER) + '\n' +
                'draft_0001,1,safe.png,0,0,12,12,8,unverified\n' +
                'draft_0001,2,safe.png,12,0,12,12,8,unverified\n', encoding='utf-8')
            groups = M.load_candidates(csv_file, original)
            self.assertEqual([x['index'] for x in groups['draft_0001']], [1,2])
            previews = M.render_candidates(groups, original, t/'previews')
            self.assertEqual(len(previews), 1)
            with Image.open(previews[0]) as result:
                self.assertEqual(result.size, (208,130))
            with self.assertRaises(FileExistsError):
                M.render_candidates(groups, original, t/'previews')
            csv_file.write_text(','.join(M.HEADER) + '\n' +
                'draft_0001,1,../bad.png,0,0,12,12,8,unverified\n')
            with self.assertRaises(ValueError):
                M.load_candidates(csv_file, original)
            csv_file.write_text(','.join(M.HEADER) + '\n' +
                'draft_0001,1,safe.png,20,20,12,12,8,unverified\n')
            with self.assertRaises(ValueError):
                M.load_candidates(csv_file, original)
            csv_file.write_text(','.join(M.HEADER) + '\n' +
                'draft_0001,2,safe.png,0,0,12,12,8,unverified\n')
            with self.assertRaises(ValueError):
                M.load_candidates(csv_file, original)

if __name__=='__main__':
    unittest.main()
