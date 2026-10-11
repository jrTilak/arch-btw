#!/usr/bin/env python3
"""Run UI keyboard tests with Quickshell's icon lookup isolated from its host."""
import os
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]

# Quickshell embeds its plugins in its executable, so qmltestrunner cannot load
# them. These tests use bundled icons only; stub the unused desktop-icon lookup.
with tempfile.TemporaryDirectory(prefix="luna-qml-test-") as temporary:
    module = Path(temporary) / "Quickshell"
    module.mkdir()
    (module / "qmldir").write_text("module Quickshell\nsingleton Quickshell 1.0 Quickshell.qml\n")
    (module / "Quickshell.qml").write_text(
        'pragma Singleton\nimport QtQml\nQtObject { function iconPath(name, fallback) { return ""; } }\n')
    result = subprocess.run(
        ["/usr/lib/qt6/bin/qmltestrunner", "-import", temporary, "-input", str(repo / "tests/qml")],
        env=dict(os.environ, QT_QPA_PLATFORM="offscreen"), cwd=repo)
    raise SystemExit(result.returncode)
