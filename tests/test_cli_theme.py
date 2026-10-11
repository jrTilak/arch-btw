"""Exercise theme commands without changing the user's theme library or desktop."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class ThemeCLI(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="luna theme's ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.environment = dict(os.environ, HOME=str(self.root),
                                XDG_CONFIG_HOME=str(self.root / "config"),
                                XDG_DATA_HOME=str(self.root / "data"))
        self.library = self.root / ".local/share/luna/themes"
        self.active = self.root / ".config/luna/theme"

    def command(self, *arguments, success=True):
        result = subprocess.run([str(REPO / "bin/luna"), "theme", *arguments],
                                env=self.environment, cwd=self.root,
                                capture_output=True, text=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def package(self, name="custom"):
        path = self.root / name
        path.mkdir()
        shutil.copyfile(REPO / "themes/tokyo-night/base.json", path / "base.json")
        return path

    def test_bundled_theme_is_copied_and_preserved(self):
        self.assertIn("tokyo-night", self.command("list").stdout)
        marker = self.library / "tokyo-night/personal-note.txt"
        marker.write_text("keep")
        self.command("list")
        self.assertEqual(marker.read_text(), "keep")

    def test_activation_and_current(self):
        self.assertEqual(self.command("current").stdout.strip(), "none")
        self.command("set", "tokyo-night")
        self.assertEqual(self.command("current").stdout.strip(), "tokyo-night")
        self.assertTrue(self.active.is_symlink())
        self.assertEqual(json.loads((self.active / "base.json").read_text()),
                         json.loads((REPO / "themes/tokyo-night/base.json").read_text()))

    def test_home_paths_ignore_xdg_and_allow_repeated_activation(self):
        self.command("set", "tokyo-night")
        active = self.root / ".config/luna/theme"
        previous = active.resolve()
        self.command("set", "tokyo-night")
        self.assertNotEqual(active.resolve(), previous)
        self.assertTrue((previous / "base.json").is_file())
        self.assertTrue((self.root / ".local/share/luna/themes/tokyo-night/base.json").is_file())
        self.assertFalse((self.root / "config").exists())
        self.assertFalse((self.root / "data").exists())

    def test_lock_prevents_changes(self):
        self.command("list")
        (self.library / ".lock").mkdir()
        result = self.command("set", "tokyo-night", success=False)
        self.assertIn("locked", result.stderr)
        self.assertFalse(self.active.exists())

    def test_full_package_is_preserved_in_library_and_active_copy(self):
        source = self.package()
        (source / "apps").mkdir()
        (source / "apps/top-bar.json").write_text('{"workspaceActive":"#123456"}')
        (source / "assets").mkdir()
        (source / "assets/source.txt").write_text("reusable source")
        self.command("install", str(source))
        self.command("set", "custom")
        for path in (self.library / "custom", self.active):
            self.assertEqual((path / "assets/source.txt").read_text(), "reusable source")
            self.assertEqual(json.loads((path / "apps/top-bar.json").read_text()),
                             {"workspaceActive": "#123456"})
        self.assertFalse((self.library / "custom/.luna-theme-name").exists())

    def test_existing_theme_requires_force_and_install_does_not_activate(self):
        source = self.package()
        self.command("install", str(source))
        (source / "extra.txt").write_text("new")
        self.command("install", str(source), success=False)
        self.assertFalse((self.library / "custom/extra.txt").exists())
        self.command("install", str(source), "--force")
        self.assertTrue((self.library / "custom/extra.txt").is_file())
        self.assertEqual(self.command("current").stdout.strip(), "none")

    def test_invalid_force_replacement_preserves_installed_theme(self):
        source = self.package()
        self.command("install", str(source))
        previous = (self.library / "custom/base.json").read_text()
        (source / "base.json").write_text("{}")
        self.command("install", str(source), "--force", success=False)
        self.assertEqual((self.library / "custom/base.json").read_text(), previous)
        self.assertFalse((self.library / ".lock").exists())

    def test_invalid_activation_keeps_current_theme(self):
        self.command("set", "tokyo-night")
        previous = self.active.readlink()
        source = self.package()
        self.command("install", str(source))
        (self.library / "custom/base.json").write_text('{"background":12}')
        self.command("set", "custom", success=False)
        self.command("set", "../tokyo-night", success=False)
        self.command("set", "missing", success=False)
        self.assertEqual(self.active.readlink(), previous)
        self.assertEqual(self.command("current").stdout.strip(), "tokyo-night")

    def test_rejects_invalid_json_and_app_colors(self):
        source = self.package()
        original = (source / "base.json").read_text()
        for invalid in ("[]", original + " garbage", "// comment\n" + original,
                        original.replace("#1a1b26", "not-a-color")):
            (source / "base.json").write_text(invalid)
            self.command("install", str(source), success=False)
        (source / "base.json").write_text(original)
        (source / "apps").mkdir()
        (source / "apps/top-bar.json").write_text('{"accent":false}')
        self.command("install", str(source), success=False)
        self.assertFalse((self.library / "custom").exists())

    def test_symlinks_and_real_active_directory_are_preserved(self):
        source = self.package()
        (source / "external").symlink_to(REPO)
        self.command("install", str(source), success=False)
        self.active.mkdir(parents=True)
        (self.active / "keep").write_text("existing")
        self.command("set", "tokyo-night", success=False)
        self.assertEqual((self.active / "keep").read_text(), "existing")


if __name__ == "__main__":
    unittest.main()
