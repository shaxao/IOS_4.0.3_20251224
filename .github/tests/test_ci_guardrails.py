from pathlib import Path
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
WORKFLOW_FILE = REPO_ROOT / ".github" / "workflows" / "ios-build.yml"
PROJECT_YML_FILE = REPO_ROOT / "RestaurantIngredientManager" / "project.yml"
SDK_DIR = REPO_ROOT / "RestaurantIngredientManager" / "RestaurantIngredientManager"
REQUIRED_LIBS = ("JCAPI.a", "JCLPAPI.a", "libSkiaRenderLibrary.a")
LFS_POINTER_PREFIX = b"version https://git-lfs.github.com/spec/v1"


class CIGuardrailsTest(unittest.TestCase):
    def test_workflow_enables_lfs_checkout(self) -> None:
        content = WORKFLOW_FILE.read_text(encoding="utf-8")
        self.assertIn("lfs: true", content)
        self.assertIn("Ensure LFS objects are downloaded", content)
        self.assertIn("Validate required SDK binaries", content)
        self.assertIn("Install xcodegen with retry", content)
        self.assertIn("concurrency:", content)

    def test_sdk_binaries_are_not_lfs_pointer_files(self) -> None:
        for lib_name in REQUIRED_LIBS:
            lib_path = SDK_DIR / lib_name
            self.assertTrue(lib_path.exists(), f"missing required binary: {lib_name}")
            head = lib_path.read_bytes()[:128]
            self.assertNotIn(
                LFS_POINTER_PREFIX,
                head,
                f"{lib_name} is still an LFS pointer file",
            )
            self.assertTrue(head.startswith(b"!<arch>"), f"{lib_name} is not a valid static archive")

    def test_project_yml_uses_sdk_framework_dependencies(self) -> None:
        content = PROJECT_YML_FILE.read_text(encoding="utf-8")
        self.assertIn("- sdk: CoreData.framework", content)
        self.assertIn("- sdk: AVFoundation.framework", content)
        self.assertIn("- sdk: CoreMedia.framework", content)
        self.assertIn("- sdk: Combine.framework", content)
        self.assertNotIn("- framework: CoreData.framework", content)
        self.assertNotIn("- framework: AVFoundation.framework", content)
        self.assertNotIn("- framework: CoreMedia.framework", content)
        self.assertNotIn("- framework: Combine.framework", content)


if __name__ == "__main__":
    unittest.main(verbosity=2)
