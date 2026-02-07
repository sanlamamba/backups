---
name: tdd
description: Implement new behavior or a bug fix test-first with strict red-green-refactor, using acceptance scenarios as the outer loop for features. Use after a plan is approved and the change needs tests.
argument-hint: "<behavior or bug to implement>"
---

Implement $ARGUMENTS test-first. Follow the project's test style and `~/.claude/rules/testing.md`.

## Outer loop (features with acceptance criteria)

0. Turn each acceptance criterion into a Given / When / Then scenario. Write one failing acceptance test for the first scenario at the cheapest level that exercises it end to end (a use case with fakes, or the API with local dependencies). It stays red while you work the inner loop. Skip the outer loop for bug fixes and small internal changes.

## Inner loop, one behavior at a time

1. **Red**: write one test named as a behavior sentence. For a bug, the test reproduces the reported bug. Run only that test file and confirm it fails for the right reason — an assertion about the behavior, not an import, fixture or typo error. Show the failure.
2. **Green**: write the minimum code to pass. Rerun the file.
3. **Refactor**: remove duplication and sharpen names in code the task touched; tests stay green. Anything wider goes under "Noticed, not done".
4. Repeat with the next behavior, including at least one failure path, until the acceptance test passes. Then take the next scenario.

## Finish

5. Run the full suite, linter and type checker. Report each command and its actual output.

Never change a test to make it pass. If a test turns out to be wrong, stop and say why.
