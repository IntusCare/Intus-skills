<!-- SEED: near-verbatim. Keep the areas, the scoring table, the aggregation rules, the discs, and
     the override rules — those are the model. Replace the calibration bullets, the archetype rows,
     and the worked examples with this repo's own surfaces. Strip every SEED comment. -->
# PR risk — the risk model

Risk measures **consequence, blast radius, and recoverability**. It does not measure code quality,
diff size, or how sensitive the nouns in a filename sound.

Reviewability, human-only surfaces, confidence, and repository state are **separate** gates handled
in [gates.md](gates.md). They can require a human without inflating the risk band.

## The five areas

Rate each independently as `very_low`, `low`, `medium`, or `high`.

### Rating discs

Every rating, floor, band, and finding severity is printed with its disc:

| Rating   | Disc | Fast-track         |
| -------- | :--: | ------------------ |
| Very low |  🔵  | eligible           |
| Low      |  🟢  | eligible           |
| Medium   |  🟡  | blocked by gate 13 |
| High     |  🔴  | blocked by gate 13 |

Cool is the fast-track zone and warm is not, so the boundary that decides who may approve is visible
before the words are read.

The disc is **display only**. It never changes a rating, never substitutes for the word beside it,
and is not one of the disposition emoji in [gates.md](gates.md) — those describe the primary blocker,
these describe a score. Never print a rating without its disc, and never print a disc that disagrees
with its word. Discs are not added inside blocker-guidance sentences, whose wording is fixed by
[gates.md](gates.md).

| Area                     | What to assess                                                                  |
| ------------------------ | ------------------------------------------------------------------------------- |
| Change complexity        | Behavioral breadth, coupling, novelty, number of components touched             |
| Blast radius             | `<the units this repo's failures spread across — tenants, users, workflows>`     |
| Data and security        | Trust boundaries, `<this repo's sensitive data classes>`, tenant isolation, secrets, permissions, durable-data consequences |
| Operational and recovery | Deployments, migrations, `<consumers, queues, jobs>`, side effects, availability, rollback, repair |
| Verification             | Important behavior not convincingly exercised by tests or other evidence        |

## Scoring table

| Area                     | 🔵 Very low                             | 🟢 Low                                        | 🟡 Medium                                       | 🔴 High                                                                     |
| ------------------------ | --------------------------------------- | --------------------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------- |
| Change complexity        | Static or mechanical                    | Isolated, familiar behavior                   | Cross-component or novel behavior               | Broad architectural or control-plane change                                 |
| Blast radius             | No runtime users or systems             | One workflow or a narrow internal audience    | Meaningful product surface                      | `<the whole-population case for this repo>`                                 |
| Data and security        | No sensitive boundary                   | Read-only or tightly constrained data         | Sensitive handling with bounded consequences    | Auth, permissions, `<sensitive-data>` exposure, cross-tenant leakage, or durable corruption |
| Operational and recovery | No operational effect; immediate revert | Bounded side effect; straightforward rollback | Production behavior with understood recovery    | Migration, destructive action, duplicated side effects, or difficult recovery |
| Verification             | Direct, convincing coverage             | Small understood gap                          | Important behavior only partly exercised        | Critical behavior unverified or evidence unavailable                        |

## Aggregation

Mechanical. Show the work.

```
dimension peak = max(the five area ratings)
policy floor   = step 2-4 result from the repo's path policy
finding floor  = max(severity of all findings), or very_low if none
overall        = max(dimension peak, policy floor, finding floor)
```

Always print the trace:

```
dimension peak 🟡 Medium · policy floor 🔴 High · finding floor 🟢 Low → overall 🔴 High
```

**Never average.** A High data-and-security rating cannot be cancelled by four Very Lows. Breadth
appears in the profile and evidence; it cannot dilute a serious consequence.

Confidence is **not** part of the band. It is an approval gate at 0.90.

## Calibration

Reassess the current diff against this calibration every time. Never preserve a rating just because
the code is unchanged — the policy may have moved.

<!-- SEED: this is the most repo-specific section in the file. Each bullet should name a real
     directory, service, or surface in this repo. Delete any bullet you can't ground. -->

### 🟢 Low — contained consequence, readily repairable

- Docs, changelogs, tests, fixtures, stories, copy, styles, layout, visual polish.
- Isolated `<presentation paths>` with no permission, persistence, or cross-session state change.
- Internal or admin reads that are bounded, fail-soft, and cleanly implemented.
- Narrow observability or developer-tooling changes with no production control-plane effect.

### 🟡 Medium — meaningful regression possible, recovery straightforward

- End-user feature logic, client/server state coordination, caches, search behavior, `<read-path
  semantics>`.
- External-service reads in user-facing paths — `<the integrations this repo calls>`.
- Dependency upgrades, `<background-job>` control flow, reversible performance or reliability changes.
- Internal tools that write data or trigger actions.
- A plausible defect with real user or operational impact but no likely data breach, durable
  corruption, or hard-to-reverse effect.

### 🔴 High — crosses a trust boundary, mutates durable state broadly, or is hard to recover

- Authentication, authorization, `<the tenant-scoping mechanism>`, secrets, encryption,
  `<sensitive-data>` exposure, or permission enforcement.
- `<the domain mutations that carry legal, financial, or clinical consequence>` — not merely reading
  those records.
- Schemas, migrations, backfills, destructive operations, deployment workflows, or broad
  `<durable-execution>` changes.
- Credible data loss, cross-tenant exposure, duplicated side effects, or a rollback that cannot
  restore prior state.

## Archetype profiles

Start from the closest profile. Rate **above** it only for a concrete consequence or finding, and
say what that evidence is.

| Archetype                    | Complexity  | Blast radius | Data/security | Operational | Verification |
| ---------------------------- | ----------- | ------------ | ------------- | ----------- | ------------ |
| Documentation-only           | 🔵 very_low | 🔵 very_low  | 🔵 very_low   | 🔵 very_low | 🔵 very_low  |
| Presentation-only            | 🟢 low      | 🟢 low       | 🔵 very_low   | 🔵 very_low | 🟢 low       |
| Internal read-only report    | 🟢 low      | 🔵 very_low  | 🟢 low        | 🟢 low      | 🟢 low       |
| Dependency bump              | 🟢 low      | 🟡 medium    | 🟢 low        | 🟡 medium   | 🟡 medium    |
| `<background-job>` change    | 🟡 medium   | 🟡 medium    | 🟢 low        | 🟡 medium   | 🟡 medium    |
| Migration or backfill        | 🟡 medium   | 🔴 high      | 🔴 high       | 🔴 high     | 🔴 high      |

## Rules that override intuition

- **Diff size never sets the band.** A large generated or repetitive diff can stay Very Low. A
  one-line permission change is High.
- **Reading is not mutating.** A bounded, fail-soft read of sensitive data is normally Low for
  data-and-security. A write to the same store is not.
- **Green CI is not proof of low risk.** `<name a real consequence this repo's suite does not
  cover>`.
- **A docs-only title is not proof of a docs-only diff.** Read the file list.
- **Do not lower a rating to make a PR look approvable.** If it is Medium, say Medium.
- **NEEDS HUMAN is not an accusation.** It means policy or repository state requires judgment, not
  that the code is defective. Never describe it as a defect.
- **Finding severity floors the band.** A 🟡 Medium finding forces at least 🟡 Medium; a 🔴 High
  finding forces 🔴 High.
- **Display-only inaccuracies and missing edge-case tests are 🟢 LOW.** Reserve 🟡 Medium and 🔴 High
  for consequences that meet the definitions above.

## Confidence

A number in `[0, 1]`. It answers _"how much do I trust this assessment?"_, not _"how safe is this
change?"_

Lower it for: a diff you could not fully read, generated code you could not verify, behavior that
depends on data you cannot see, or an unfamiliar subsystem. Reflect incomplete inspection here and
in the verification rating — never by narrating tool mechanics in the summary.

Below 0.90 blocks fast-track eligibility. It does not change the band.

## Worked examples

<!-- SEED: replace all rows with diffs from this repo. Keep a row where a path rule and the
     calibration disagree, and a row where a content finding overrides an otherwise trivial diff —
     those two are what the table is for. -->

| Change                               | Ratings (cx/br/ds/op/vf) | Trace                                                  | Overall       |
| ------------------------------------ | ------------------------ | ------------------------------------------------------ | ------------- |
| `<agent-instruction file>` edit      | 🔵🔵🔵🔵🔵               | peak 🔵 Very Low · floor 🟢 Low · findings —           | 🟢 **Low**    |
| `<presentation component>` variant   | 🟢🟢🔵🔵🟢               | peak 🟢 Low · floor — · findings —                     | 🟢 **Low**    |
| Migration adding an indexed field    | 🟡🔴🔴🔴🟡               | peak 🔴 High · floor 🔴 High · findings —              | 🔴 **High**   |
| `<read-only report path>`            | 🟢🔵🟢🟢🟢               | peak 🟢 Low · floor 🟡 **Medium** · findings —         | 🟡 **Medium** |
| `<presentation diff that logs PII>`  | 🟢🟢🔴🔵🟢               | peak 🔴 High · floor — · findings 🔴 **High (`<ID>`)** | 🔴 **High**   |

The discs in the ratings column read in the header's order — cx/br/ds/op/vf. The last row is the one
to internalize: a trivial presentation diff becomes 🔴 High the moment sensitive data reaches
telemetry. Path rules alone would have called it 🟢 Low.
