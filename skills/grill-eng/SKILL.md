---
name: grill-eng
description: "Refine a Jira ticket with an engineer in the room: the /grill-jira flow, asking only the decisions an engineer can settle. Product decisions get recorded, not asked."
argument-hint: "<TICKET-KEY>"
disable-model-invocation: true
---

Run `/grill-jira` with `--audience=eng`.

- Try `Skill(skill: "grill-jira", args: "<KEY> --audience=eng")`. `grill-jira` is
  `disable-model-invocation`, so the call may be refused — then read
  [../grill-jira/SKILL.md](../grill-jira/SKILL.md) and follow it end to end with that audience.
- Ask only what an engineer can settle: implementation shape, seams, data model, migration,
  sequencing, rollback, perf budget, what breaks downstream.
- Scope, acceptance criteria, priority, and edge-case behaviour are **not** the engineer's to
  decide. They go to `Open questions` as `[needs product]` — never guessed, never put to the
  engineer as if they spoke for product.
- Everything else is unchanged: same enrichment, same parallel plans, same write-back, same label.
