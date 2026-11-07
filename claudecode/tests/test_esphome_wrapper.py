"""esphome: forwards the ESPHome CLI to the ESPHome add-on with `docker exec`.

A fake `docker` on PATH answers `info` and `ps` from environment variables and records
the `exec` call; ESPHOME_LOCAL_ROOT points the /homeassistant -> /config mapping at a
scratch directory.
"""
import os
import shutil
import tempfile
import unittest
from pathlib import Path

from testlib import BIN_DIR, run_cli

WRAPPER = BIN_DIR / "esphome"

FAKE_DOCKER = """#!/bin/bash
case "$1" in
  info) exit "${FAKE_DOCKER_INFO_EXIT:-0}" ;;
  ps)   printf '%b' "${FAKE_DOCKER_PS:-}" ;;
  exec) printf '%s\\n' "$@" > "$FAKE_DOCKER_CALL"; exit "${FAKE_DOCKER_EXEC_EXIT:-0}" ;;
esac
"""


class TestEsphomeWrapper(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)
        self.root = self.tmp / "homeassistant"
        (self.root / "esphome/wall-pad").mkdir(parents=True)
        (self.root / "esphome/wall-pad/wall-pad.yaml").write_text("esphome:\n")
        (self.root / "esphome/m5dial.yaml").write_text("esphome:\n")
        fake_bin = self.tmp / "bin"
        fake_bin.mkdir()
        (fake_bin / "docker").write_text(FAKE_DOCKER)
        (fake_bin / "docker").chmod(0o755)
        self.call = self.tmp / "call"
        self.env = dict(os.environ, PATH=f"{fake_bin}:{os.environ['PATH']}", FAKE_DOCKER_CALL=str(self.call),
                        ESPHOME_LOCAL_ROOT=str(self.root),
                        FAKE_DOCKER_PS="app_1016f397_claudecode\\napp_15ef4d2f_esphome\\napp_core_mosquitto\\n")
        self.env.pop("ESPHOME_CONTAINER", None)

    def run_wrapper(self, *args, cwd=None, **env):
        return run_cli([WRAPPER, *args], dict(self.env, **env), cwd=cwd or self.root)

    def exec_call(self):
        """argv after `docker exec`: (flags, container, command)."""
        argv = self.call.read_text().splitlines()[1:]
        flags = argv[:argv.index("esphome") - 1]
        return flags, argv[len(flags)], argv[len(flags) + 1:]

    def test_relative_path_from_a_subdirectory(self):
        rc, out, err = self.run_wrapper("compile", "wall-pad.yaml", cwd=self.root / "esphome/wall-pad")
        self.assertEqual(rc, 0, err)
        flags, container, cmd = self.exec_call()
        self.assertEqual(container, "app_15ef4d2f_esphome")
        self.assertEqual(cmd, ["esphome", "compile", "/config/esphome/wall-pad/wall-pad.yaml"])
        self.assertEqual(flags, ["-i", "-w", "/config/esphome/wall-pad"])

    def test_absolute_path_and_pass_through_arguments(self):
        rc, _, err = self.run_wrapper("upload", str(self.root / "esphome/m5dial.yaml"),
                                      "--device", "192.168.68.115", "--no-logs")
        self.assertEqual(rc, 0, err)
        _, _, cmd = self.exec_call()
        self.assertEqual(cmd, ["esphome", "upload", "/config/esphome/m5dial.yaml",
                               "--device", "192.168.68.115", "--no-logs"])
        flags, _, _ = self.exec_call()
        self.assertEqual(flags[-1], "/config")

    def test_new_yaml_file_is_mapped_too(self):
        self.run_wrapper("wizard", "esphome/nieuw.yaml")
        _, _, cmd = self.exec_call()
        self.assertEqual(cmd, ["esphome", "wizard", "/config/esphome/nieuw.yaml"])

    def test_paths_outside_the_config_are_left_alone(self):
        outside = self.tmp / "elders.yaml"
        outside.write_text("")
        self.run_wrapper("config", str(outside), cwd=self.tmp)
        flags, _, cmd = self.exec_call()
        self.assertEqual(cmd, ["esphome", "config", str(outside)])
        self.assertEqual(flags, ["-i", "-w", "/config"])

    def test_container_override(self):
        self.run_wrapper("version", ESPHOME_CONTAINER="mijn_esphome")
        _, container, cmd = self.exec_call()
        self.assertEqual((container, cmd), ("mijn_esphome", ["esphome", "version"]))

    def test_stable_container_wins_over_beta(self):
        self.run_wrapper("version", FAKE_DOCKER_PS="app_5c53de3b_esphome-beta\\napp_15ef4d2f_esphome\\n")
        _, container, _ = self.exec_call()
        self.assertEqual(container, "app_15ef4d2f_esphome")

    def test_only_a_beta_container(self):
        self.run_wrapper("version", FAKE_DOCKER_PS="addon_5c53de3b_esphome-beta\\n")
        _, container, _ = self.exec_call()
        self.assertEqual(container, "addon_5c53de3b_esphome-beta")

    def test_two_candidates_without_a_stable_one_is_an_error(self):
        rc, _, err = self.run_wrapper("version", FAKE_DOCKER_PS="app_a_esphome-beta\\napp_b_esphome-dev\\n")
        self.assertEqual(rc, 1)
        self.assertIn("ESPHOME_CONTAINER", err)
        self.assertFalse(self.call.exists())

    def test_no_esphome_container(self):
        rc, _, err = self.run_wrapper("version", FAKE_DOCKER_PS="app_1016f397_claudecode\\n")
        self.assertEqual(rc, 69)
        self.assertIn("ESPHome Device Builder", err)

    def test_protection_mode_on(self):
        rc, _, err = self.run_wrapper("version", FAKE_DOCKER_INFO_EXIT="1")
        self.assertEqual(rc, 69)
        self.assertIn("Protection mode", err)
        self.assertFalse(self.call.exists())

    def test_exit_code_of_esphome_is_passed_on(self):
        rc, _, _ = self.run_wrapper("compile", "esphome/m5dial.yaml", FAKE_DOCKER_EXEC_EXIT="2")
        self.assertEqual(rc, 2)


if __name__ == "__main__":
    unittest.main()
