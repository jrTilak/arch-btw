"""Verify bar deployment preserves settings and works from portable paths."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class BarSetup(unittest.TestCase):
    def test_deployment_is_repeatable_and_preserves_user_files(self):
        with tempfile.TemporaryDirectory(prefix="luna bar's ") as temporary:
            root = Path(temporary)
            home = root / "home"
            config = root / "custom config"
            state = root / "state"
            (config / "hypr").mkdir(parents=True)
            hypr = config / "hypr/hyprland.lua"
            hypr.write_text("-- Keep the user's configuration.\n")
            (config / "luna").mkdir()
            settings = config / "luna/top-bar.json"
            settings.write_text('{"workspaceIcons":{"1":"firefox"}}')
            (home / ".local/bin").mkdir(parents=True)
            (home / ".local/bin/luna-bar").write_text("existing command")
            runner = root / "run.lua"
            runner.write_text(
                'package.path = arg[1] .. "/helpers/?.lua;" .. arg[1] .. "/install/?.lua;" .. package.path\n'
                'require("stow").apply(arg[1])\nrequire("bar").apply(arg[1])\n')
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(config),
                       XDG_STATE_HOME=str(state))
            env.pop("HYPRLAND_INSTANCE_SIGNATURE", None)
            for _ in range(2):
                result = subprocess.run(["luajit", str(runner), str(REPO / "setup")],
                                        env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(settings.read_text(), '{"workspaceIcons":{"1":"firefox"}}')
            self.assertEqual(hypr.read_text().count('/hypr/bar.lua'), 1)
            self.assertIn("Keep the user's configuration", hypr.read_text())
            self.assertEqual((home / ".local/src/top-bar/shell.qml").resolve(),
                             REPO / "src/top-bar/shell.qml")
            self.assertEqual((home / ".local/bin/luna-bar").resolve(), REPO / "bin/luna-bar")
            backups = list((state / "luna/backups").glob("bar-*"))
            self.assertEqual(len(backups), 1)
            self.assertEqual((backups[0] / "luna-bar").read_text(), "existing command")

    def test_bar_scope_selects_native_runtime_without_aur(self):
        code = ('package.path="setup/helpers/?.lua;setup/install/?.lua;"..package.path; '
                'local p=require("packages").load_manifest("setup/dependencies.lua","bar"); '
                'assert(#p.aur==0); for _,name in ipairs(p.pacman) do print(name) end')
        result = subprocess.run(["luajit", "-e", code], cwd=REPO,
                                capture_output=True, text=True, check=True)
        self.assertEqual(set(result.stdout.splitlines()),
                         {"stow", "quickshell", "pipewire", "wireplumber", "networkmanager",
                          "bluez", "upower", "qt6-svg", "brightnessctl", "hyprlock"})


if __name__ == "__main__":
    unittest.main()
