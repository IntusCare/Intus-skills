<!-- SEED: strip every SEED comment. One row per layer with evidence on disk. Delete rows for
     layers this repo doesn't have; a layer nobody has written is not a layer. -->
# Test Layers for Eng Skills

> **TL;DR** — Pick the layer by where the behavior is observable. `<n>` layers; most tickets need
> one or two.

## Context

`test-first` and `implement` ship in the shared `intus-skills` plugin and decide _that_ a layer is
needed. This file decides _which_ layer, _where_ the file goes, and _how_ it is written in `<repo>`.

## The layers

Pick per behavior, not per ticket. A ticket needing all of these is rare.

| Layer                 | Write it when                               | Where                          | Harness      |
| --------------------- | ------------------------------------------- | ------------------------------ | ------------ |
| **Unit**              | The behavior is a pure function             | `<colocation convention>`      | `<runner>`   |
| **`<integration>`**   | `<the boundary this layer covers>`          | `<path convention>`            | `<harness>`  |
| **`<permission>`**    | `<the access-control change that needs it>` | `<path convention>`            | `<harness>`  |
| **Eval**              | The deliverable is behavior defined in markdown or a prompt — a skill, agent, or command, or a model-backed feature — not deterministic code | `<eval directory convention>` | `<eval runner>` |
| **E2E**               | An AC describes a flow a human clicks through, and a reviewer would only believe it by watching the browser | `<path>` | `<runner or delegate>` |

## Don't write

<!-- SEED: the repo's actual anti-patterns. These three generalize; add the repo's own. -->

- Tests for the framework or the type system — validation schemas and compile-time types included.
- E2E for a backend-only change with no user-visible difference.
- A second layer that passes for exactly the same reason as the first. One integration test that
  already exercises the mapping makes the mapping's unit test redundant — keep the unit test only if
  it covers edge cases the higher layer can't reach.

## Per-layer conventions

Read a neighboring test file in the same `<package/module>` first and match it — import style,
helper naming, and `describe` nesting all vary.

**Every layer:**

- Name the test after scenario and outcome: `'<worked example from this repo>'`.
- One reason to fail per test. Assert the positive precondition before anything derived from it.
- `<any fixture rule — no production data, no real credentials, no PII in logs>`.

**Unit:** no database, no network, no mocking of things you own. If a "unit" test needs
`<the data accessor>`, it belongs a layer up.

**`<integration>`:**

- `<the wrapper every case goes through, and what it guarantees — transaction rollback, a fresh db>`
- **Be parallel-safe:** create your own data and filter results to the IDs you created. Never
  `<the clean-slate operation>` — it nukes a concurrently running file's data.
- `<any assertion this repo requires — response shape, not just values>`

<!-- SEED: keep only if the repo has evals on disk. Name an existing eval to model new ones on. -->
**Eval:** `test-first` owns the two-layer model (integrity vs. behavioral). This file says where
each one lives in `<repo>`:

- Integrity checks: `<file name>` — deterministic, no model calls, runs in CI.
- Behavioral cases: `<file name>` — each case with the verdict the docs require.
- Model a new eval on `<an existing eval's README>`.

<!-- SEED: keep an E2E handoff section only if E2E is delegated to another skill rather than
     hand-written. Say what the attended and unattended forms are, and what gets reported. If the
     workflow is user-only (`disable-model-invocation: true`), a Skill call to it is refused: make
     both forms "plan the E2E work and name the command for the human to run". -->
## E2E handoff

E2E tests are written by `<e2e workflow>`, not by `test-first`. Its page-object and fixture rules
live in `<where they live>`.

- **Attended** (a human typed `/i:test-first`): `Skill(skill: "<e2e workflow>", args: "<KEY>")`. It
  may stop at its own gates; the human answers them. Report the layer as `delegated`.
- **Unattended** (`--unattended`, or any skill caller): `Skill(skill: "<e2e workflow>", args: "<KEY>
  <its plan-only flag>")`. Report `PLANNED, NOT WRITTEN`, include the plan, and name
  `<e2e workflow> <KEY>` as the follow-up a human runs.
- Never pass `<its skip-the-gate flag>` from the unattended form. `test-first` Step 4 says why.
