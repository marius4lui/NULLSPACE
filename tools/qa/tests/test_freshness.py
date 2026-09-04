"""Image-comparison guard unit tests, never native-rendering acceptance."""
from pathlib import Path
import sys
import tempfile
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from prove_freshness import compare_images


class FreshnessTests(unittest.TestCase):
    def test_pixel_equality_and_stale_hud_rejection(self) -> None:
        with tempfile.TemporaryDirectory(prefix="nullspace-image-test-") as directory:
            native, reference = Path(directory) / "native.png", Path(directory) / "viewport.png"
            pixels = Image.new("RGB", (1920, 1080), (12, 22, 32))
            pixels.save(native)
            pixels.save(reference)
            self.assertTrue(compare_images(native, reference)["exact_rgb_match"])
            pixels.paste((255, 255, 255), (50, 70, 60, 80))
            pixels.save(reference)
            result = compare_images(native, reference)
            self.assertFalse(result["exact_rgb_match"])
            self.assertGreater(result["hud_mean_difference"], 0)

    def test_wrong_resolution_rejected(self) -> None:
        with tempfile.TemporaryDirectory(prefix="nullspace-image-test-") as directory:
            image = Path(directory) / "small.png"
            Image.new("RGB", (2, 2)).save(image)
            with self.assertRaises(AssertionError):
                compare_images(image, image)


if __name__ == "__main__":
    unittest.main(verbosity=2)
