<!-- SEED: strip every SEED comment before writing. Keep only rows for files that were actually
     written; a row pointing at a missing file is worse than no table. -->
# Eng Skills

`<repo>`'s repo-specific configuration for the workflow commands that ship in the shared
`intus-skills` plugin. The skills themselves are repo-agnostic and live outside this repo; these files
supply the `<repo>` specifics they read at runtime — where issues live, what triage vocabulary to
use, which commands run the tests, and which domain docs to read before exploring the codebase.

Edit these files directly; the skills read them on every run.

A skill that points at a file here degrades gracefully: if the file is absent, the repo hasn't
configured that skill, and the skill says so rather than guessing.

## Documents

| Document                                               | Description                                                                |
| ------------------------------------------------------ | -------------------------------------------------------------------------- |
| [tickets-and-branches.md](./tickets-and-branches.md)   | Tracker access, key resolution, branch naming, cutting a branch, shared branches, pre-push hooks |
| [test-layers.md](./test-layers.md)                     | Which test layer a change needs, where it lives, and any handoff           |
| [test-commands.md](./test-commands.md)                 | Commands for running tests and the verification gates                      |
| [pre-existing-failures.md](./pre-existing-failures.md) | The baseline procedure for quarantining a failure you didn't cause         |
| [code-standards.md](./code-standards.md)               | The non-negotiables that bite most often mid-implementation, and that `fix` won't trade away |
| [pr-conventions.md](./pr-conventions.md)               | PR description sections, conditional blocks, label, and comment style      |
| [test-plans.md](./test-plans.md)                       | Where a ticket's test plan lives, its lifecycle, and its line format       |
| [pr-risk-path-policy.md](./pr-risk-path-policy.md)     | Deterministic path-to-severity floors and human-only surfaces for `pr-risk` |
| [pr-risk/](./pr-risk/)                                 | The rest of the `pr-risk` policy: risk model, gates, output contract       |
| [issue-tracker.md](./issue-tracker.md)                 | Where issues live and the operations skills use to read and write them     |
| [triage-labels.md](./triage-labels.md)                 | Mapping from the five canonical triage roles to this repo's labels         |
| [domain.md](./domain.md)                               | How skills consume `CONTEXT.md` and the ADRs                               |

## Which skill reads what

| Skill                                            | Reads                                                                 |
| ------------------------------------------------ | --------------------------------------------------------------------- |
| `workon`, `buildit`, `push`, `shipit`            | `tickets-and-branches.md`                                             |
| `test-first`                                     | `tickets-and-branches.md`, `test-layers.md`, `test-commands.md`       |
| `implement`                                      | all of the above plus `pre-existing-failures.md`, `code-standards.md` |
| `pull-request`                                   | `tickets-and-branches.md`, `pr-conventions.md`                        |
| `fix`                                            | `pr-conventions.md`, `code-standards.md`, `pr-risk/gates.md`          |
| `grill-jira`                                     | `test-plans.md`, `issue-tracker.md`, `tickets-and-branches.md`        |
| `pr-risk`                                        | `pr-risk-path-policy.md` and everything under `pr-risk/`              |
| `triage`                                         | `triage-labels.md`                                                    |
| `to-spec`, `to-tickets`                          | `issue-tracker.md`, `triage-labels.md`                                |
| `wayfinder`, `mp-code-review`                    | `issue-tracker.md`                                                    |
