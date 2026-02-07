---
name: audit
description: Audit a branch or commit in one repo or across repos for logic, guidelines, completion and cross-repo contracts.
---

Arguments: what the user wrote with this skill.

The first word is the ref (branch or commit SHA); the rest is optional ticket text or a URL. Audit only: don't edit repo files and don't spawn agents. The only file you write is the report (step 7). For an unbiased review, run this in a fresh session, not the one that wrote the code.

LAUNCH_DIR is the working directory when the audit starts.

## 1. Resolve scope

- Inside a repo (`git rev-parse --show-toplevel` succeeds): audit only that repo.
- Otherwise: candidates are the direct subfolders of LAUNCH_DIR that contain `.git`.
- For each candidate: `git -C <repo> fetch --prune -q`, then resolve the ref with `git -C <repo> rev-parse --verify -q <ref>`, falling back to `origin/<ref>` for branches that exist only on the remote. Keep the repos where it resolves, and remember the resolved name.
- Show repo paths relative to LAUNCH_DIR. If no repo has the ref, stop and say so.

## 2. Get the change (per repo)

- Base for a branch: `origin/HEAD`; if unset, `origin/main`, then `origin/master`. Say which base you used.
- Branch: `git log --oneline <base>..<resolved>` and `git diff <base>...<resolved>`.
- Commit: `git show <sha>`.
- Intent: the ticket text if given (fetch a URL only if reachable); else the branch's PR/MR, with the CLI for the `origin` host if it's installed (GitHub: `gh pr list --head <ref>` then `gh pr view`; GitLab: `glab mr list --source-branch <ref>` then `glab mr view`); else the commit messages.

## 3. Audit (per repo)

Read the surrounding code and callers, not just the diff. Check against `~/.codex/AGENTS.md`, the repo's own CLAUDE.md or AGENTS.md, and its guideline docs:

- Logic: bugs, edge cases, broken contracts with callers, swallowed or broad exceptions, error paths.
- Guidelines: design rules, layering and dependency direction, scope creep, duplicated logic (search the repo and its dependencies).
- Tests: new behavior and failure paths covered, behavior-level assertions, no weakened or junk tests, fakes over mocks.

## 4. Completion

- Each ticket criterion and the stated intent: done / partial / missing, with `file:line` evidence.
- Loose ends: TODOs, stubs, dead code, untested paths, missing migrations or config, callers not updated.

## 5. Cross-repo (more than one repo)

Compare contracts between repos: API endpoints and fields, message or event schemas, shared models. Flag every mismatch with both sides' `file:line`.

## 6. Verify each candidate finding

Try to disprove every candidate before reporting it:

- Upstream: callers and every input source. Can the bad input or state actually occur? Check validation layers, types, DB constraints.
- Downstream: consumers of the return value or side effect, persisted data, API or message consumers in other repos.
- Ecosystem: the actual library or framework source in `.venv` / `node_modules` (not memory), config and env, existing tests on the path, project guidelines.

Keep a finding only with concrete evidence from this trace; otherwise move it to "Discarded" with the reason. Report what affects correctness, requirements or a written guideline; style preferences are Low at most.

## 7. Report

- Path: `LAUNCH_DIR/reviews/<scope>-<ref>-<YYYY-MM-DD>.md`, where `<scope>` is the repo name (or `multi` for several repos) and `<ref>` is the branch name or 8-character SHA with `/` replaced by `-`. Run `mkdir -p LAUNCH_DIR/reviews` first.
- Follow `report-template.md` in this skill's folder exactly. Findings most severe first.
- In chat, print only the report path, the verdict and the summary table.
