#!/usr/bin/env python3
"""PreToolUse guard: block direct edits to lockfiles and secret files.

Codex passes the tool call as JSON on stdin. File edits arrive as `apply_patch`, with
the patch text in tool_input.command, so the edited paths come from its file headers.
Exit code 2 blocks the call and shows stderr to Codex, so it can regenerate a lockfile
through the package manager or ask the user to edit a secret file instead.

Wired in ~/.codex/hooks.json under hooks.PreToolUse for apply_patch.
"""

from __future__ import annotations

import json
import sys
from pathlib import PurePath

LOCKFILES = {
    "uv.lock", "poetry.lock", "Pipfile.lock", "pdm.lock",
    "package-lock.json", "npm-shrinkwrap.json", "pnpm-lock.yaml", "yarn.lock",
    "bun.lock", "bun.lockb", "Cargo.lock", "go.sum", "composer.lock", "Gemfile.lock",
}
SECRET_NAMES = {".env", ".envrc", ".netrc", ".pgpass", "id_rsa", "id_ed25519"}
SAFE_ENV_SUFFIXES = (".example", ".sample", ".template", ".dist")
SECRET_SUFFIXES = (".pem", ".key", ".p12", ".pfx")
PATCH_PATH_HEADERS = ("*** Add File: ", "*** Update File: ", "*** Delete File: ", "*** Move to: ")


def block_reason(path: str) -> str | None:
    name = PurePath(path).name
    if name in LOCKFILES:
        return (
            f"{name} is generated. Change the manifest and regenerate it with the "
            "package manager (e.g. `uv add`, `uv lock`, `pnpm install`)."
        )
    is_env_variant = name.startswith(".env.") and not name.endswith(SAFE_ENV_SUFFIXES)
    if name in SECRET_NAMES or is_env_variant or name.endswith(SECRET_SUFFIXES):
        return f"{name} may contain secrets. Ask the user to edit it themselves."
    return None


def patched_paths(patch: str) -> list[str]:
    return [
        line.removeprefix(header).strip()
        for line in patch.splitlines()
        for header in PATCH_PATH_HEADERS
        if line.startswith(header)
    ]


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return 0
    patch = (payload.get("tool_input") or {}).get("command")
    if not isinstance(patch, str):
        return 0
    reasons = [reason for path in patched_paths(patch) if (reason := block_reason(path))]
    if reasons:
        print(f"Blocked by ~/.codex/hooks/guard-files.py: {' '.join(reasons)}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
