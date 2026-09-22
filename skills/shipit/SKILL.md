---
name: shipit
description: "Get this branch reviewed and clean: commit and push anything outstanding, open or refresh the PR, then work the review findings. Use when asked to ship it, put it up for review, or finish off a branch."
argument-hint: "[--no-fix] [--max-iterations=N]"
---

Take a branch that has work on it and leave it as a pushed, reviewed, findings-cleared PR.

```
  dirty tree? ─► /ncommit ─► /push ─┐
  clean?  ─────────────────────────►├─► /pull-request ─► /fix
                                    ┘
```

A **conductor**: no rules of its own, every rule stays in the skill being called. Ordering, gating, and one report.

`$ARGUMENTS`:
- *(empty)* — the full chain.
- `--no-fix` — stop after `/pull-request`; leave the review findings alone.
- `--max-iterations=N` — passed through to `/fix` (default 3).

Where this sits: `/buildit` runs a ticket from branch to pushed branch and stops. `/shipit` is what comes after — and works equally well on a branch you built by hand.

---

## Invoking this from another skill

Model-invocable: `Skill(skill: "shipit", args: "--no-fix")`.

- **It publishes.** Commits, pushes, opens a PR, posts a review, and pushes again while clearing findings. A caller that must not reach `origin` should not call it.
- **Run unattended.** Each stage either completes or terminates with a report; nothing waits on a human.
- **Return the report verbatim** — callers key off `STATUS` and the per-stage lines.

---

## Stage 0 — Preconditions

- **Not on a shared branch** — the ones `docs/intus-skills/tickets-and-branches.md` names under "Shared branches and pre-push hooks" (`main`/`master` and `origin/HEAD` if the file is missing). Stop and report; this chain pushes and opens a PR, and neither belongs on a shared branch.
- **Detached HEAD** — stop, there is no branch to ship.

## The chain

| # | Call | Run it when | Stops the chain when |
|---|---|---|---|
| 1 | `Skill(skill: "ncommit")` | `git status --short` is non-empty | Nothing gets committed despite a dirty tree |
| 2 | `Skill(skill: "push", args: "--no-commit")` | Always | Push blocked after its own 3 attempts |
| 3 | `Skill(skill: "pull-request")` | Always | The PR can't be created or updated |
| 4 | `Skill(skill: "fix", args: "[--max-iterations=N]")` | Unless `--no-fix` | It reports `STOPPED` or `CAP REACHED` — that ends this chain too, it is not an error |

Notes at the seams:

- **`/ncommit` first, and only when dirty.** `/push` can commit on its own, but it makes one commit; `/ncommit` splits the tree into atomic ones. That is why stage 2 gets `--no-commit` — by then there is nothing left to commit, and the flag says so rather than relying on it.
- **A clean tree is not a no-op.** Skip stage 1, still run stage 2: the branch may hold commits that were never pushed. `/push` reports "already up to date" and costs nothing when it is.
- **Stage 3 both creates and refreshes.** `/pull-request` opens a draft PR if there is none and updates the existing one otherwise, then posts the `/review` checklist and the `/pr-risk` assessment. Stage 4 needs that comment to exist — `/fix` reads it.
- **Stage 4 ends on a fresh review.** `/fix`'s last iteration finishes with its own `/pull-request` run, so the PR's findings comment reflects the final code.

## When a stage stops

Stop at the failing stage; don't skip ahead, and don't re-run a stage that already spent its own retry budget (`/push` gets 3, `/fix` gets 3). Report where it stopped, what that stage said, and the command that resumes from there — usually just `/shipit` again once the blocker is cleared.

`/fix` finishing with findings still open is **not** a failure of this chain. The PR is up, reviewed, and honest about what is unresolved; a human takes it from there.

## Report

Quote each stage's own report underneath rather than paraphrasing — `/fix`'s `STILL OPEN` list and `/push`'s attempt count are the parts a reviewer actually needs.

```
═══════════════════════════════════════════════
SHIPIT: <branch>
═══════════════════════════════════════════════
  1 ncommit       ✓ N commits | skipped — clean tree
  2 push          ✓ origin/<branch>        | BLOCKED
  3 pull-request  ✓ #NNN <url> (draft)     | BLOCKED
  4 fix           ✓ clean | N open after N iterations | skipped

STATUS: SHIPPED | SHIPPED WITH N OPEN FINDINGS | STOPPED AT <stage>
NEXT:   review and take it out of draft   |   <resume command>
═══════════════════════════════════════════════
```

`/shipit` leaves the PR in draft. User marks it ready for review — that stays a human's call.
