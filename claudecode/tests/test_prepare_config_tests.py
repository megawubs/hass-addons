"""prepare-config-tests: readies the Home Assistant config's test-suite at boot.

Fake `uv` and `git` on PATH record how they were called; CONFIG_TESTS_DIR and
CONFIG_TESTS_VENV point the script at a scratch config dir and environment.
"""
import os
import shutil
import tempfile
import unittest
from pathlib import Path

from testlib import BIN_DIR, run_cli

SCRIPT = BIN_DIR / "prepare-config-tests"

FAKE = """#!/bin/bash
echo "$(basename "$0") $*" >> "$FAKE_CALLS"
exit "${FAKE_EXIT:-0}"
"""


class TestPrepareConfigTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.config = self.tmp / "homeassistant"
        self.config.mkdir()
        self.venv = self.tmp / "data/uv/venv"
        fake_bin = self.tmp / "bin"
        fake_bin.mkdir()
        for name in ("uv", "git"):
            (fake_bin / name).write_text(FAKE)
            (fake_bin / name).chmod(0o755)
        self.calls = self.tmp / "calls"
        self.env = dict(os.environ, PATH=f"{fake_bin}:{os.environ['PATH']}", FAKE_CALLS=str(self.calls),
                        CONFIG_TESTS_DIR=str(self.config), CONFIG_TESTS_VENV=str(self.venv),
                        UV_CACHE_DIR=str(self.tmp / "data/uv/cache"))

    def run_script(self, **extra_env):
        rc, out, err = run_cli([SCRIPT], dict(self.env, **extra_env))
        self.assertEqual(rc, 0, out + err)
        return out

    def recorded(self):
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def make_project(self, lock=True, submodules=True):
        (self.config / "pyproject.toml").write_text("[project]\nname = 'x'\n")
        if lock:
            (self.config / "uv.lock").write_text("")
        if submodules:
            (self.config / ".gitmodules").write_text("")

    def test_without_pyproject_does_nothing(self):
        out = self.run_script()
        self.assertIn("nothing to prepare", out)
        self.assertFalse((self.config / ".venv").exists())
        self.assertEqual(self.recorded(), [])

    def test_links_venv_checks_out_submodules_and_syncs_frozen(self):
        self.make_project()
        out = self.run_script()
        link = self.config / ".venv"
        self.assertTrue(link.is_symlink())
        self.assertEqual(os.readlink(link), str(self.venv))
        self.assertTrue(self.venv.is_dir())
        self.assertEqual(self.recorded(), ["git rev-parse --git-dir",
                                           "git submodule update --init --recursive",
                                           "uv sync --frozen"])
        self.assertIn("Ready", out)

    def test_without_lock_syncs_unfrozen_and_skips_submodules_without_gitmodules(self):
        self.make_project(lock=False, submodules=False)
        self.run_script()
        self.assertEqual(self.recorded(), ["uv sync"])

    def test_replaces_a_real_virtualenv(self):
        self.make_project()
        old = self.config / ".venv"
        old.mkdir()
        (old / "pyvenv.cfg").write_text("home = /usr/bin\n")
        self.run_script()
        self.assertTrue(old.is_symlink())

    def test_leaves_a_non_virtualenv_alone(self):
        self.make_project()
        odd = self.config / ".venv"
        odd.mkdir()
        (odd / "keep.txt").write_text("mine")
        out = self.run_script()
        self.assertFalse(odd.is_symlink())
        self.assertTrue((odd / "keep.txt").exists())
        self.assertIn("left alone", out)

    def test_repoints_a_stale_symlink(self):
        self.make_project()
        (self.config / ".venv").symlink_to(self.tmp / "elsewhere")
        self.run_script()
        self.assertEqual(os.readlink(self.config / ".venv"), str(self.venv))

    def test_a_failing_sync_is_reported_not_fatal(self):
        self.make_project(submodules=False)
        out = self.run_script(FAKE_EXIT="1")
        self.assertIn("uv sync failed", out)


if __name__ == "__main__":
    unittest.main()
