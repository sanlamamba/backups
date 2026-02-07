---
name: challenge
description: Stress-test a decision, plan, design or claim before committing to it. Use when asked to challenge, poke holes, or check whether I'm wrong, and before irreversible or architectural choices.
---

Challenge the decision, plan or claim the user gave with this skill. If none, take the most recent plan or decision in this conversation.

Your job is to find what's wrong, not to be agreeable. Ground every point in code, docs, data or library source you actually checked, not in general opinion. Do not edit files.

1. **Restate** the decision in one line and the goal it serves. If the goal is unclear or the decision doesn't serve it, that is the first finding.
2. **Case against**: wrong assumptions, failure modes, hidden costs (migration, operations, cognitive load), and what breaks in six months or at 10x scale. Verify each against the codebase where possible and mark which ones you verified.
3. **Alternatives**: one to three realistic options, always including "do less" or "do nothing", with the trade-off of each.
4. **Verdict**: proceed · proceed with changes · reconsider. Name the one fact that would change your verdict.

If the decision holds up, say so plainly and why. Don't invent objections to look thorough.
