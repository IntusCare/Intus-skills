---
name: workon
description: "Start work on a Jira task — prompting for the ticket key or link when none is given — then branch and start the work."
---

Start working on a task: resolve its Jira ticket, cut a branch, and begin the work.

`$ARGUMENTS`:
- *(empty)* — prompt for the ticket key or link.
- A ticket key (`ABC-1234`) or a browse URL — use that ticket.
- `--base=current` — branch from the current branch instead of the repo's integration branch.

## Prerequisites

**Repo-specific — read this first:** `docs/intus-skills/tickets-and-branches.md` in the repo you are
working in. It names the tracker, how to reach it and in what order, the key format, and the branch
rules. Every step below defers to it.

If that file is absent, the repo hasn't configured these skills: say so and ask the user for the
tracker and branch conventions rather than guessing.

If no access path to the tracker works, stop and name which one failed and how. Never invent a
ticket key.

---

## Step 1 — Resolve the ticket

Extract the key from `$ARGUMENTS` per the key format and URL rules in
`docs/intus-skills/tickets-and-branches.md`.

If there's no key, ask for one and end the turn on the question — no tool calls after it, so the next message is unambiguously the answer:

> What's the Jira ticket key or link?

Read the key out of the reply the same way. If the reply has no key in it, ask once more; never invent one, and never derive one from the branch name or the working tree.

Ask nothing else. This skill works only on tickets that already exist — no title, description, project, assignee, or sprint prompts. If the user has no ticket yet, say so and stop rather than filing one for them.

## Step 2 — Fetch the ticket's details

Fetch summary and description using the access order in
`docs/intus-skills/tickets-and-branches.md`. If the fetch fails, report the error and stop — don't
branch off a key you couldn't read.

## Step 3 — Branch

Name the branch and cut it per the branch-naming and cutting sections of
`docs/intus-skills/tickets-and-branches.md` — it gives the slug rules, the repo's integration branch,
and the exact commands for both the default base and `--base=current`.

Report which branch you based on and its ticket key, if any — stacked work is easy to lose track of. Uncommitted changes follow you onto the new branch either way; if `git status` isn't clean, say what's carrying over before you branch.

If any git command fails, report the error and stop, naming the ticket you were branching for.
