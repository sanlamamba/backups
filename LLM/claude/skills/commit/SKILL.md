---
name: commit
description: Stage changes and create a Conventional Commit after my approval.
argument-hint: "[optional hint for the message]"
disable-model-invocation: true
---

## Current state

- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Staged: !`git diff --staged --stat`
- Unstaged: !`git diff --stat`
- Recent commits: !`git log --oneline -5`

## Steps

1. **Files**: from the state above, list the files to stage. Exclude AI instruction files (`CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.md`, `.claude/`) unless the repo already tracks them, generated files, lockfiles changed by accident, env files, `.python-version` and `reviews/`. If an excluded file is already staged, say so and propose `git restore --staged -- <file>`.
2. **Read** the diffs of those files. If they mix unrelated changes, propose splitting them into separate commits.
3. **Message**: Conventional Commits. Short imperative title, at most 72 characters, no trailing period. No body unless the why isn't obvious from the title; then one or two lines. No author, co-author, trailer or "generated with" lines. Use $ARGUMENTS as a hint if given.
   - Types: build, ci, chore, docs, feat, fix, perf, refactor, release, revert, style, test.
   - Scope: the ticket, in the format earlier commits use; never invent one. Candidates in the branch name: a key of letters then digits (`feat-proj-123-…` → `PROJ-123`) or a bare issue number (`fix-123-…` → `#123`). Use a candidate only if the same key prefix or `#` style appears in the recent commits; otherwise ask, since `utf-8` or `node-20` aren't tickets. No candidate in the branch: take it from the branch's earlier commits, or omit the scope.
   - Breaking change: `type(scope)!: …` plus a `BREAKING CHANGE: …` footer.
   - Revert: `revert: <original header>`, body `This reverts commit <sha>.`
4. **Stop**: show the file list and the message, then wait for approval.
5. **After approval**: `git add -- <files>` with explicit paths only, then commit with the message passed through a quoted heredoc:

   ```bash
   git commit -F - <<'EOF'
   <message>
   EOF
   ```

6. If a git hook fails or modifies files, show its output, fix the cause, re-stage, and show the new state before retrying. Never use `--no-verify`. Never push.
