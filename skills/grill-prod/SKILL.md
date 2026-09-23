---
name: grill-prod
description: "Refine a Jira ticket with a product manager in the room: the /i:grill-jira flow, asking only the decisions a PM can settle. Engineering decisions get recorded, not asked."
argument-hint: "<TICKET-KEY>"
disable-model-invocation: true
---

Run `/i:grill-jira` with `--audience=product`.

- Try `Skill(skill: "i:grill-jira", args: "<KEY> --audience=product")`. `grill-jira` is
  `disable-model-invocation`, so the call may be refused — then read
  [../grill-jira/SKILL.md](../grill-jira/SKILL.md) and follow it end to end with that audience.
- Ask only what a product manager can settle: scope in and out, acceptance criteria, behaviour at
  the edges, priority, whether a partial ships, copy and labels, which tradeoff wins for the user.
- Seams, data model, migration, and sequencing are **not** the PM's to decide. They go to
  `Open questions` as `[needs engineering]` — never guessed, never put to the PM as if they spoke
  for engineering.
- Ask in product language. A question a PM can't parse is a question they can't answer.
- Everything else is unchanged: same enrichment, same parallel plans, same write-back, same label.
