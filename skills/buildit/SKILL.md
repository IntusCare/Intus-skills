---
name: buildit
description: "Take a Jira ticket key from branch to pushed branch in one pass: /i:workon, /i:test-first, /i:ncommit, /i:implement, /i:ncommit, /i:push. Use when asked to build / do / take on a ticket end to end."
argument-hint: "<JIRA-KEY> [--from=<stage>] [--no-push]"
---

Run one ticket through the whole pipeline. `/i:buildit ABC-1234` branches, writes the failing tests, commits them, implements until green, commits that, and pushes.

This skill is a **conductor**. It contributes no rules of its own — every rule lives in the skill being called, and each stage's report is the input to the next. Its whole job is ordering, gating, and one report at the end.

```
  $ARGUMENTS ──► /i:workon <KEY>        branch cut from the integration branch
                      │
                      ▼
                 /i:test-first          failing tests for each AC
                      │
                      ▼
                 /i:ncommit             commit the red tests
                      │
                      ▼
                 /i:implement           code until green (≤5 attempts)
                      │
                      ▼
                 /i:ncommit             commit the implementation
                      │
                      ▼
                 /i:push                origin/<branch>
```

`$ARGUMENTS`:
- `<TICKET-KEY>` — required, e.g. `ABC-1234`. A browse URL works too. **Never invent one**; with no key, ask and end the turn on the question.
- `--from=<stage>` — resume at `test-first` | `implement` | `push`, skipping earlier stages. For picking up a run that stopped.
- `--no-push` — stop after the second `/i:ncommit`.

---

## Stage 0 — Preconditions

Check before calling anything:

- **Clean working tree.** `git status --short` must be empty. Two of the six stages commit whatever is present, so unrelated changes would be swept into this ticket's history. Dirty tree → report and stop; let the user stash or commit first.
- **A key was supplied.** No key, no run.

## The chain

Call each with the `Skill` tool, in order. Each stage's report goes into the next; do not re-derive what a stage already told you.

| # | Call | Produces | Stops the chain when |
|---|---|---|---|
| 1 | `Skill(skill: "i:workon", args: "<KEY>")` | Branch `<KEY>-<slug>` off the integration branch | Ticket can't be fetched, or the branch can't be cut |
| 2 | `Skill(skill: "i:test-first", args: "--unattended")` | Red tests per AC + its report | It reports no testable AC at all |
| 3 | `Skill(skill: "i:ncommit")` | The red tests, committed | Nothing to commit *and* stage 2 claimed files |
| 4 | `Skill(skill: "i:implement", args: "--no-tests")` | Green suite | `STATUS: BLOCKED` |
| 5 | `Skill(skill: "i:ncommit")` | The implementation, committed | — |
| 6 | `Skill(skill: "i:push")` | `origin/<branch>` | Unless `--no-push`; push blocked after its own 3 attempts |

Notes that matter at the seams:

- **Stages 2 and 4 read the branch, not an argument.** `/i:workon` names it `<KEY>-<slug>`, and both resolve the ticket from that name (per `docs/intus-skills/tickets-and-branches.md`). This is why stage 1 cannot be skipped unless you are already on the ticket's branch — check with `git rev-parse --abbrev-ref HEAD` before honoring `--from`.
- **Stage 3 commits a red suite on purpose.** That is the point of test-first: the commit records the specification before the code. Say so in the commit body so a reviewer reading history doesn't think the branch was broken. Never let this stage "fix" a test to make the commit look green.
- **Stage 4 gets `--no-tests`** because stage 2 already wrote them. `/i:implement` must not call `/i:test-first` itself.
- **Stage 6 runs unattended** and commits anything the second `/i:ncommit` left behind.
- **All six are model-invocable today.** If someone adds `disable-model-invocation: true` to any of them, this chain breaks and the stage must be inlined instead — per `AGENTS.md`, that flag means "do the steps directly."

## When a stage stops

Stop the chain at the failing stage. Do not skip ahead, and do not retry a stage that already exhausted its own retry budget — `/i:implement` gets 5 attempts and `/i:push` gets 3; re-running them from here just spends them twice.

**Never push a blocked implementation.** If stage 4 reports `BLOCKED`, run stage 5 so the partial work is committed and nothing is lost, then stop before stage 6.

Report where it stopped, what that stage said, and the single command that resumes:

```
/i:buildit <KEY> --from=implement
```

## Report

Print the chain's outcome, then quote each stage's own report underneath rather than paraphrasing it — a summary that drops `/i:implement`'s `PRE-EXISTING` list or `/i:test-first`'s `NOT COVERED` list hides exactly what the reviewer needs.

```
═══════════════════════════════════════════════
BUILD: <KEY> — <ticket summary>
BRANCH: <branch>
═══════════════════════════════════════════════
  1 workon      ✓  branch cut from the integration branch
  2 test-first  ✓  N tests, N red
  3 ncommit     ✓  <sha> <subject>
  4 implement   ✓  green in N attempts   | BLOCKED
  5 ncommit     ✓  <sha> <subject>
  6 push        ✓  origin/<branch>       | skipped | BLOCKED

STATUS: COMPLETE | STOPPED AT <stage>
NEXT:   /i:pull-request   |   /i:buildit <KEY> --from=<stage>
═══════════════════════════════════════════════
```

`/i:buildit` does not open a PR. When it finishes, `/i:pull-request` is the next step.
