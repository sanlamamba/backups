"""Behavior of guard-files.py, driven through stdin the way Codex runs it."""

from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

HOOK = Path(__file__).with_name("guard-files.py")


def run_hook(stdin: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(HOOK)], input=stdin, capture_output=True, text=True, check=False
    )


def apply_patch_call(*file_sections: str) -> str:
    patch = "\n".join(["*** Begin Patch", *file_sections, "*** End Patch"])
    return json.dumps({"tool_name": "apply_patch", "tool_input": {"command": patch}})


class GuardFilesTest(unittest.TestCase):
    def test_blocks_patches_that_touch_lockfiles_or_secret_files(self) -> None:
        cases = [
            ("updates a lockfile", ["*** Update File: app/uv.lock\n@@\n-a\n+b"], "uv.lock is generated"),
            ("adds a local env file", ["*** Add File: .env.local\n+TOKEN=x"], ".env.local may contain secrets"),
            (
                "moves a file onto a secret name",
                ["*** Update File: notes.txt\n*** Move to: deploy/server.pem"],
                "server.pem may contain secrets",
            ),
            (
                "deletes a secret file among ordinary edits",
                ["*** Update File: src/main.py\n@@\n-a\n+b", "*** Delete File: .env"],
                ".env may contain secrets",
            ),
        ]
        for case, file_sections, reason in cases:
            with self.subTest(case):
                result = run_hook(apply_patch_call(*file_sections))

                self.assertEqual(result.returncode, 2)
                self.assertIn(reason, result.stderr)

    def test_allows_a_patch_to_ordinary_and_example_env_files(self) -> None:
        result = run_hook(apply_patch_call("*** Update File: src/main.py\n@@\n-a\n+b", "*** Add File: .env.example\n+TOKEN="))

        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stderr, "")

    def test_allows_the_call_when_stdin_is_not_json(self) -> None:
        result = run_hook("not json")

        self.assertEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
