#!/usr/bin/env python3
"""PreToolUse guard: block direct edits to lockfiles and secret files.

Claude Code passes the tool call as JSON on stdin. Exit code 2 blocks the call and
shows stderr to Claude, so it can regenerate a lockfile through the package
manager or ask the user to edit a secret file instead.

Wired in ~/.claude/settings.json under hooks.PreToolUse for Edit|Write|MultiEdit|NotebookEdit.
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


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return 0
    tool_input = payload.get("tool_input") or {}
    path = tool_input.get("file_path") or tool_input.get("notebook_path")
    if not path:
        return 0
    reason = block_reason(path)
    if reason:
        print(f"Blocked by ~/.claude/hooks/guard-files.py: {reason}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
