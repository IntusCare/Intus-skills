<!-- SEED: strip every SEED comment. Every command here must be declared in the repo — a script in
     package.json, a Makefile target, a documented CLI. Delete any section this repo has no command
     for rather than inventing one. -->
# Test and Verification Commands for Eng Skills

> **TL;DR** — `<test command>`. `<the one trap worth knowing>`.

## Context

`test-first` and `implement` ship in the shared `intus-skills` plugin and know only that they need to
run tests. These are `<repo>`'s commands. Always `<package manager>` — never `<the wrong ones>`.

## Running tests

```bash
<narrow-scope test command>     # <what the flags do>
```

`<scope>` is the narrowest path that covers the changed code, e.g. `<real example path>`. A tight
scope is what makes an iterative green loop affordable.

<!-- SEED: only if a service, container, or env file must be up first. Name the command that starts
     it and what breaks without it. -->
**`<service>` must be up.** If the suite can't boot, `<start command>` first.

<!-- SEED: keep this section only if a real trap exists — a retry flag, a snapshot auto-update, a
     cache that hides staleness. Delete it otherwise; a fabricated trap teaches distrust. -->
## The trap

`<command>` runs with `<flag>`, so `<what a green result can hide>`. When a result looks unstable,
re-run with `<the honest command>` before believing either outcome.

Never `<the workaround that hides it>` in place of diagnosing it. If a test passes and fails across
attempts with no edit in between, report it as flaky rather than counting it green.

## Widening before you call it done

On the final passing attempt, widen once: run `<the next scope up — the package, the suite>`, not
just the file, to catch collateral damage the narrow scope hid.

## The remaining gates

Once tests are green:

```bash
<type-check command>
<lint command>
<any other gate CI enforces>
```

<!-- SEED: if the repo has one command that runs them all, name it and say what order it runs in. -->

Type and lint errors in the changed files are yours — fix them and re-run the scope.
