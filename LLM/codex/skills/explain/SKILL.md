---
name: explain
description: Briefly explain a commit, branch, PR/MR, diff, file, folder or symbol, with file:line and commit references. Use when asked to explain something, "what does X do", "what happened in", or "what changed".
---

Explain the target the user gave with this skill.

Goal: I understand what this is or what happened, fast, and can verify every claim myself. Read-only: don't edit files and don't review or critique unless I ask.

## 1. Identify the target

- Empty: the uncommitted changes (`git diff HEAD`), or else the last thing we discussed.
- Commit SHA or ref (`git rev-parse --verify -q <arg>^{commit}` succeeds): `git show --stat <sha>`, then `git show <sha>`.
- Branch: base is `origin/HEAD` (fallback `origin/main`, then `origin/master`); `git log --oneline <base>..<branch>` and `git diff <base>...<branch>`.
- Range `a..b`: `git log --oneline a..b` and `git diff a...b`.
- PR number (`#123`, GitHub): `gh pr view 123` and `gh pr diff 123`. MR number (`!123`, GitLab): `glab mr view 123` and `glab mr diff 123`. Only if the CLI is installed; on GitLab `#123` is an issue, not an MR.
- File: read it, find its main callers (`grep` for its exports), its tests, and `git log --oneline -5 -- <file>`.
- Folder: list it two levels deep, read its README or manifest, find its entry points and public interface, and read only the key files. Don't read every file.
- Symbol (function or class name): find the definition and its callers.

If the argument is ambiguous (a name that's both a branch and a folder), say which one you picked.

## 2. Gather the why

For commits and branches, take intent from the commit messages, the PR/MR description and the ticket ID in the branch name. If intent isn't written anywhere, infer it from the code and mark it "(inferred)".

## 3. Answer in this shape

**TL;DR**: one or two sentences on what this is or what happened, and why.

Then the body for the target type:

- **Commit / branch / PR/MR / diff**
  - Why: the intent, with its source (commit, PR/MR, ticket) or "(inferred)".
  - What changed: grouped by concern, not by file, one bullet each with `file:line` refs.
  - Behavior: before → after, for anything a user, caller or API consumer would notice.
  - Notable: migrations, config or env changes, public API or schema changes, untested new logic. Omit if none.
- **File**
  - Role: what it's responsible for, which layer it sits in, and who calls it.
  - Main pieces: each important function or class in one line with `file:line`.
  - Main flow: the typical path through it in three to six steps.
  - Depends on / used by: the key imports and the callers that matter.
  - Gotchas: non-obvious behavior, side effects, surprising coupling. Omit if none.
- **Folder**
  - Purpose: what this part of the system does.
  - Map: each subfolder or key file → its responsibility, one line each.
  - Entry points: where execution or usage starts.
  - Connections: what it depends on and what depends on it.
  - Start reading at: the two or three files to open first, in order.
- **Symbol**
  - What it does, its inputs and outputs, where it's defined, who calls it, and any side effects.

## Rules

- Every claim gets a reference: `path/file.py:42` or a short SHA. No reference means you haven't verified it yet, so go and check.
- Brief: about 25 lines for a commit, file or symbol, 40 for a folder or a big branch. Cut detail before cutting references.
- Show code only when a line or two says it better than prose; never paste large blocks.
- Separate fact from inference, and mark inference.
- If you spot a clear bug, add one line under Notable; don't turn the answer into a review.
- If I asked a specific question, answer it first, then give only the context it needs.
- End with one line: the natural next question, or "`/teach-me <target>` for a step-by-step walkthrough".