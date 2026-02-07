# Audit: `<ref>` · <YYYY-MM-DD>

**Verdict:** Ship | Fix first | Rework
**Scope:** <repos> · base `<base>` · <n> commits · <n> files changed
**Intent:** <one line: ticket summary, PR/MR title or commit messages>

Verdict rule: any Critical or High → Fix first. A wrong approach or design (not fixable with local changes) → Rework. Otherwise → Ship.

## Summary

| Severity | Count |
|---|---|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
| Criteria done / partial / missing | 0 / 0 / 0 |

Severity scale:
- **Critical**: data loss or corruption, security issue, wrong results on a production path.
- **High**: bug on a realistic path, broken contract with a caller or another repo, required criterion missing.
- **Medium**: unhandled edge case, missing test for new logic, guideline violation with a real cost.
- **Low**: minor guideline, naming or clarity issue worth fixing.

## Findings

### [H1] <short title>

- **Severity:** Critical | High | Medium | Low
- **Category:** Logic | Guidelines | Tests | Completion | Cross-repo
- **Where:** `repo/path/to/file.py:42`
- **Problem:** <what is wrong and its impact>
- **Evidence:** <the upstream / downstream / ecosystem trace that confirms it>
- **Fix:** <smallest change that resolves it>

<!-- Repeat per finding; IDs use the severity letter: C1, H1, M1, L1. -->

## Completion

| Criterion | Status | Evidence |
|---|---|---|
| <criterion> | done / partial / missing | `file:line` |

## Loose ends

- <TODOs, stubs, dead code, untested paths, missing migrations or config, callers not updated — or "None">

## Cross-repo contracts

| Contract | Side A | Side B | Status |
|---|---|---|---|
| <endpoint, field, event or model> | `repo-a/file:line` | `repo-b/file:line` | match / mismatch |

<!-- Omit this section for single-repo audits. -->

## Discarded

| Candidate | Why discarded |
|---|---|
| <candidate finding> | <the evidence that disproved it> |
