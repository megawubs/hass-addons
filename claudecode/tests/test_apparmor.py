"""apparmor.txt: the profile the Supervisor loads for the add-on."""
import fnmatch
import re
import unittest

from testlib import ADDON

PROFILE = (ADDON / "apparmor.txt").read_text()


def permissions_for(path: str) -> set[str]:
    permissions = set()
    for rule_match in re.finditer(r"^\s*(/\S+)\s+([a-z]+),\s*$", PROFILE, re.MULTILINE):
        rule_path, rule_permissions = rule_match.groups()
        if fnmatch.fnmatch(path, rule_path.replace("**", "*")):
            permissions |= set(rule_permissions)
    return permissions


class TestAppArmor(unittest.TestCase):
    def test_musl_loader_can_be_executed(self):
        for musl_loader in ("/lib/ld-musl-x86_64.so.1", "/lib/ld-musl-aarch64.so.1"):
            with self.subTest(musl_loader=musl_loader):
                self.assertTrue({"i", "x", "m", "r"} <= permissions_for(musl_loader), permissions_for(musl_loader))

    def test_rest_of_lib_stays_read_only(self):
        self.assertEqual(permissions_for("/lib/libz.so.1"), {"r"})


if __name__ == "__main__":
    unittest.main()
