<!-- SEED: this file is generated, not copied. Every table below must be filled from this repo's
     actual tree — `git ls-files | cut -d/ -f1-3 | sort -u` is a good start. The steps, their order,
     and the bolded invariants are fixed; the rows are yours. Strip every SEED comment before
     writing, including the derivation notes. -->
# PR risk — deterministic path policy

`POLICY_VERSION: <repo>-<YYYY-MM-DD>.1`

Emit this version string in every assessment. Bump it whenever a rule below changes, so an old
assessment cannot be mistaken for a current one.

These rules are **deterministic**. Apply them by table lookup before rating anything. A floor here
cannot be argued down by a rating in [risk-model.md](./pr-risk/risk-model.md).

Floors and finding severities are printed with the discs defined in
[risk-model.md](./pr-risk/risk-model.md#rating-discs) — 🔵 very low, 🟢 low, 🟡 medium, 🔴 high.

## Order of evaluation

1. Classify every changed file (documentation / test / constrained / runtime).
2. Set the **baseline floor** from that classification.
3. Match **HIGH path rules** against runtime files.
4. Match **MEDIUM path rules** against runtime files.
5. Match **human-only surfaces** against runtime files.
6. Compute the **reviewability budget** from non-constrained files.
7. Scan the diff for **mandatory content findings**.

The policy floor is the highest of steps 2–4.

## Step 1 — Classify changed files

Two overlapping classes. The distinction matters and is easy to get wrong.

**Documentation-or-test** — excluded from path-floor and human-only matching _and_ from the
reviewability budget:

| Class         | Matches                                            |
| ------------- | -------------------------------------------------- |
| Documentation | `<doc globs>` — **except `<agent-instruction tree>`**, see below |
| Tests         | `<test globs, fixture globs, the e2e package>`      |

**Constrained** — a superset of the above. Excluded from the reviewability budget only; path floors
**still apply**:

| Class                            | Matches                                        |
| -------------------------------- | ---------------------------------------------- |
| Everything documentation-or-test | see above                                      |
| Markdown outside docs            | `**/*.md`, `**/*.mdx` — **except operative instruction content**, see below |
| Styles                           | `<style globs>`                                |
| Stories & snapshots              | `<story and snapshot globs>`                   |
| Static assets                    | `<asset globs>`                                |

This two-tier split is what lets a 200-file test-only change cost nothing against the reviewability
budget while a single migration still carries a HIGH floor.

### Operative instruction content is neither Documentation nor Constrained

The class is defined by **function, not by path prefix**: does a changed line alter what an agent
does on a future ticket? If yes it is operative instruction content — a **runtime** file. Path floors
and human-only matching in steps 3–5 apply to it, and its changed lines consume the step 6
reviewability budget.

**The most specific path wins.** Read the table longest-prefix first, as with every other lookup in
this document.

| Operative instruction content                              | Not operative                                            |
| ---------------------------------------------------------- | -------------------------------------------------------- |
| `<agent tree>` — every agent, skill, and doc; a new subdirectory is covered on the day it is created | `<retrospective paper-trail paths>` — no command reads them |
| `AGENTS.md`, `CLAUDE.md`                                   | `<eval suites>` — they assert the rules rather than state them |
| `<any other instruction file — a review rubric, a prompt>` | `<human-prose docs>`                                     |

Without this row, an agent-instruction tree nested under a `docs/` path matches the documentation
glob, is skipped by step 5, and the governance rule below becomes **unable to fire on the very rules
it protects** — a diff that weakens a rule assesses Very Low and FAST-TRACK ELIGIBLE.

**Why these files are not Constrained.** The constrained class exists for files whose line count
overstates the review burden because skimming them is cheap. Instruction content is the opposite:
every changed line rewrites what an agent will do on every future ticket, so the volume is genuine
review surface.

## Step 2 — Baseline floor

| Condition                     | Baseline                                                 |
| ----------------------------- | -------------------------------------------------------- |
| Zero changed files resolvable | 🟡 MEDIUM — assume the worst; you could not see the diff |
| Every file is documentation   | 🔵 VERY LOW                                              |
| Every file is constrained     | 🔵 VERY LOW                                              |
| Anything else                 | 🟢 LOW                                                   |

## Step 3 — 🔴 HIGH path rules

Every row is also human-only. Match against runtime files only.

<!-- SEED: derive these from the repo, one row per surface. Candidates worth hunting for: schema
     migrations, tenant/org scoping, auth and access control, the permission or role model, identity,
     secrets handling, money or eligibility mutations, destructive data scripts, deploy workflows and
     container images. Name exact files where the surface is a handful of files; glob only where the
     whole directory qualifies. -->

| Surface                         | Paths        |
| ------------------------------- | ------------ |
| `<schema migrations>`           | `<paths>`    |
| `<tenant isolation / scoping>`  | `<paths>`    |
| `<access-control enforcement>`  | `<paths>`    |
| `<permission & role model>`     | `<paths>`    |
| `<identity>`                    | `<paths>`    |
| `<the domain's consequential mutations>` | `<paths>` |
| `<backfills and data scripts>`  | `<paths>`    |
| `<deployment workflows & images>` | `<paths>`  |

<!-- SEED: for each row that is not self-evident, write one paragraph naming the consequence that
     earns HIGH. And write down any path you deliberately left out because its name sounds
     sensitive but its consequence isn't — that note is the most valuable part of this file. -->

`<path>` is deliberately **absent** from this table: `<why its name misleads, and what it actually
does>`. Matching it as a `<misleading class>` surface would flag roughly one PR in `<n>` as
human-only for a routine change. It falls under the MEDIUM rule like any other `<class>`.

**Match on consequence, never on a sensitive-sounding name.**

## Step 4 — 🟡 MEDIUM path rules

<!-- SEED: candidates: the dependency graph, runtime configuration, feature flags, shared type and
     validation contracts, the API or service layer not already HIGH, background jobs, external
     integrations, query utilities, operational scripts. -->

| Surface                        | Paths     |
| ------------------------------ | --------- |
| `<dependency graph>`           | `<paths>` |
| `<runtime configuration>`      | `<paths>` |
| `<feature flags>`              | `<paths>` |
| `<shared type & validation contracts>` | `<paths>` |
| `<API behavior not already HIGH>` | `<paths>` |
| `<background jobs>`            | `<paths>` |
| `<external integrations>`      | `<paths>` |

Everything else runtime — `<the presentation and utility paths>` — carries no floor above the LOW
baseline.

## Step 5 — Human-only surfaces

Every HIGH row in step 3, plus:

| Surface               | Paths                                              |
| --------------------- | -------------------------------------------------- |
| Secrets & credentials | `<env globs>`, anything adding a credential literal |
| Agent governance      | `AGENTS.md`, `CLAUDE.md`, `<the whole agent tree>`  |

Human-only **requires a human decision but does not raise the risk band.** An operative
instruction-content edit is 🟢 Low, because step 1 leaves it non-constrained and so step 2 gives the
LOW baseline rather than the all-constrained one. A paper-trail-only edit is 🔵 Very Low and still
NEEDS HUMAN. Neither is raised by being human-only.

The agent-governance row covers **every** file that changes what an agent does on a future ticket,
not just `/pr-risk`'s own rules. Note it deliberately matches the whole tree, including the
paper-trail and eval paths that step 1 excludes from the reviewability budget: weakening an eval is a
governance act even though the file costs no budget.

**The glob is deliberately the whole tree and not a list of subdirectories.** Enumeration fails the
same way every time — the set grows without anyone remembering to widen the row, and a diff that
weakens an unlisted subagent or doc assesses Very Low and FAST-TRACK ELIGIBLE. Match the whole tree
and let a future subdirectory be covered on the day it is created.

Human-only matching skips documentation-or-test files, so a change confined to a test file is not
human-only. Content findings still apply to it.

## Step 6 — Reviewability budget

Count only **non-constrained** files and their changed lines.

<!-- SEED: set thresholds from this repo's merged-PR distribution, not from taste. Something like:
     gh pr list --state merged --limit 100 --json files --jq '.[].files | length' | sort -n | uniq -c
     Pick a limit only the genuine outliers exceed — if it fires on a normal PR, every PR needs a
     human and the gate means nothing. -->

| Limit                    | Threshold        |
| ------------------------ | ---------------- |
| Reviewable files         | more than **<n>** |
| Reviewable changed lines | more than **<n>** |

Exceeding either fails the reviewability gate. It **never** raises the risk band. Report it as
`autonomous reviewability limit: <n> reviewable files exceeds the <n>-file limit`.

A large fully-constrained change consumes zero budget. Operative instruction content is **not**
constrained (step 1), so policy rewrites consume budget in full.

## Step 7 — Mandatory content findings

Path rules cannot see whether code reads or writes. These `<repo>`-specific patterns are read off the
diff body and are **mandatory** — if the pattern is present, the finding is filed at the stated
severity, which then floors the overall band per [risk-model.md](./pr-risk/risk-model.md).

Sourced from `<the repo's written standards — name the file and sections>`.

<!-- SEED: one row per rule, each with an ID, the pattern, a severity, and its exemptions. A rule
     with no exemption column is a rule that will fire on correct code. Measure every one before you
     keep it — see Measurements. Four to eight rules is a healthy number; twenty is noise. -->

| ID     | Pattern     | Severity | Exemptions — check these first |
| ------ | ----------- | -------- | ------------------------------ |
| `<ID>` | `<pattern>` | 🔴 HIGH  | `<paths and cases where this is correct>` |
| `<ID>` | `<pattern>` | 🟡 MEDIUM | `<...>`                       |
| `<ID>` | `<pattern>` | 🟢 LOW   | —                              |

<!-- SEED: for any rule whose severity is conditional, or that reads backwards from how the standards
     phrase it, add a subsection explaining it. Those are the rules that get misapplied. -->

## Measurements

Every figure above came from one of these. Re-run them before changing a rule — see
[Recalibrating](#recalibrating). Figures were taken on `<date>` at `<commit>`; expect drift as
commits land, and record the new number rather than quietly keeping the old one.

```sh
# <ID> — <what this counts>                                        → <n>
<command>
```

## Recalibrating

When you change a rule, a severity, or an exemption:

1. Re-run the relevant command above and record the number you actually got.
2. If the new base rate contradicts the rule you were about to write, **the base rate wins.**
3. Update the figures in this file and the dated observations they support.
4. Bump `POLICY_VERSION` at the top. Required for any rule, severity, or exemption change; not for
   wording or formatting fixes.

**Measure before raising a severity.** A rule that fires on correct code trains the reader to ignore
every rule next to it.

## Worked examples

Verify against these before trusting a novel assessment. The near-misses are the point.

<!-- SEED: build these from real diffs in this repo's history. Include, at minimum: a docs-only
     diff, an agent-instruction-only diff (Low but NEEDS HUMAN), a migration, the
     sensitive-sounding-but-not path from step 3, a large constrained diff that passes reviewability,
     and a large presentation diff that fails it. -->

| Diff                        | Baseline | Floor     | Human-only | Reviewability | Overall       |
| --------------------------- | -------- | --------- | ---------- | ------------- | ------------- |
| `<agent instruction file>`  | 🟢 Low (operative, not constrained) | — | **Yes** | 1 file | 🟢 **Low**, NEEDS HUMAN |
| `<migration file>`          | 🟢 Low   | 🔴 HIGH   | Yes        | 1 file        | 🔴 **High**   |
| `<the misleading path>`     | 🟢 Low   | 🟡 MEDIUM | **No**     | 1 file        | 🟡 **Medium** |
| `<200 test files>`          | 🔵 Very Low (all constrained) | — | No | **0 files — passes** | 🔵 **Very Low** |
| `<90 presentation files>`   | 🟢 Low   | —         | No         | **fails**     | 🟢 **Low**, NEEDS HUMAN |

The last two are the most instructive: size gates reviewability, never risk.
