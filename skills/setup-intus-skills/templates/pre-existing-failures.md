<!-- SEED: strip every SEED comment. The procedure must match this repo's tooling — whether a
     worktree needs its own install, whether two suites can run at once. Verify before writing. -->
# Proving a Test Failure Is Pre-Existing

> **TL;DR** — The file must be unmodified on this branch, and the same test must fail the same way
> on `<base>`.

## Context

`implement` ships in the shared `intus-skills` plugin. It may exclude a failure from its green bar
only by proving the failure predates the branch. This is `<repo>`'s procedure for that proof.

## Hard precondition

**The test file must exist on `<base>` and be unmodified on this branch.**

```bash
git diff <base> --name-only -- <test-file>   # must print nothing, committed and uncommitted alike
```

If the file is new or modified on this branch, it is not pre-existing — it is yours, even if it also
fails on `<base>` (a test for a feature `<base>` doesn't have obviously fails there).

## The baseline

Eligible files are checked against `<base>` in **one** scratch worktree, built once and reused for
every file in the invocation:

```bash
# once per invocation, before the first baseline check
git worktree add <scratch>/base-baseline <base>   # <scratch>: the session scratchpad, not the repo
<install command in that worktree>                # a new worktree has no dependencies installed

# then, per eligible file
<test command targeting the worktree> <file>

# once, after the last check
git worktree remove <scratch>/base-baseline
```

<!-- SEED: delete the install line if this repo's dependency layout makes a worktree usable without
     one, and say so. Keep it, with the reason, if omitting it fails. -->
**The install is not optional.** `<why — where dependencies live and why resolution never reaches
the main checkout>`.

**Build it once.** The install costs `<time>` on a repo this size, and tearing the worktree down
between files pays that cost again for every file checked.

<!-- SEED: keep only if the suites genuinely collide — a shared database name, a fixed port. -->
## Run baselines serially

**Never run a baseline check alongside the branch's own test run.** Both use `<the shared
resource>`, and two concurrent suites will corrupt each other's state and produce failures that are
artifacts of the check itself.

## What does and does not count as proof

**A baseline run that fails to boot is not evidence of anything.** Module-resolution errors, a
failed install, or a suite that never reaches the test are all `UNKNOWN`, not `pre-existing` — the
only verdict that quarantines a failure is the same test failing on `<base>` with the same
assertion. When the baseline cannot run, say so in the report and count the failure as yours.

Cache each verdict. Check a given file against `<base>` **once** per invocation, not once per
attempt.

A confirmed pre-existing failure is excluded from the green bar, listed in the report with the
baseline evidence, and otherwise left alone. Do not fix it as a favor — it is unrelated scope that
will confuse the reviewer of this ticket.
