<!-- SEED: near-verbatim. Keep all fifteen gates, the disposition tables, and the rank table — the
     numbering is referenced from the skill and from output-contract.md. Fill in the required check
     names and the base branch from what CI and branch protection actually say. Strip every SEED
     comment. -->
# PR risk — gates, disposition, and guidance

Gates decide **who may approve**, not how risky the change is. A gate failure never raises the risk
band. Evaluate every gate; report all failures but act on the highest-priority one.

Band words below carry the discs from [risk-model.md](risk-model.md#rating-discs). The disposition
emoji in this file are a **different** vocabulary — they name the primary blocker, not a score — so
never substitute one for the other.

## Check gate

<!-- SEED: list the required checks by their exact reported names, sourced from the workflow file
     and branch protection. A required name that CI never produces blocks every PR forever. -->

Required checks, from `<workflow file>` — all `<n>`:

```
<check-1>  <check-2>  <check-3>
```

Fetch them for the PR head SHA:

```sh
gh pr view <number> --json statusCheckRollup \
  --jq '.statusCheckRollup[] | {name: (.name // .context), status, conclusion, state, startedAt, completedAt}'
```

`startedAt`/`completedAt` are required, not optional. Without them the deduplication rule below has
nothing to order by, and a re-run check is decided by whichever entry the array happens to list
first.

### Evaluation

Deduplicate by name, keeping the most recent run per name — most recent by `completedAt`, falling
back to `startedAt`. **A name with any non-terminal run is `pending` regardless of timestamps**: a
check that re-ran has not finished, whatever an older successful attempt says. One head SHA can
report the same check as both `IN_PROGRESS` and `SUCCESS` simultaneously, and picking the wrong one
flips gate 7 between `pending` and `accepted`.

Then classify — **the required checks and everything else are treated differently**:

| Observed                                                        | Required check | Non-required check                  |
| --------------------------------------------------------------- | -------------- | ----------------------------------- |
| Not present at all                                              | `missing`      | —                                   |
| `status` not `completed`, `conclusion` null, or state `pending` | `pending`      | `pending`                           |
| `success`                                                       | `accepted`     | `accepted`                          |
| `failure`, `timed_out`, `startup_failure`, `action_required`    | `blocking`     | `blocking`                          |
| `cancelled`, `stale`, `neutral`, `skipped`                      | `blocking`     | **advisory** — report, do not block |

The gate is green when `missing`, `pending`, and `blocking` are all empty.

**Why non-required checks get the softer rule.** Most repos run workflows that are non-SUCCESS by
design on a healthy PR — a failure-notifier that only runs when something failed, a duplicate run
superseded by a later one. Blocking on those makes the gate unsatisfiable on **every** PR. A genuine
`failure` anywhere still blocks, so the safety property survives; only by-design skips and
superseded cancellations are downgraded.

<!-- SEED: record this repo's by-design non-SUCCESS checks here, as a dated observation with the
     command that produced it, so the next reader can re-measure instead of guessing:
     gh pr view <n> --json statusCheckRollup --jq '.statusCheckRollup[] | select((.conclusion // .state) != "SUCCESS")' -->

Never downgrade a `failure` on any check, required or not.

<!-- SEED: keep only if this repo shards a required job across a matrix. -->
**Matrix jobs:** `<job>` runs sharded, so names arrive as `<job> (1, N)` through `<job> (N, N)`. A
required name is satisfied by a check whose name equals it _or_ begins with `<name> (`. All shards
must succeed.

A non-green gate does **not** stop the assessment — report it as one failed gate and continue.

## Approval gates

| #   | Gate               | Fails when                                                                                   |
| --- | ------------------ | -------------------------------------------------------------------------------------------- |
| 1   | Base branch        | base is not `<base>`                                                                         |
| 2   | PR state           | PR is not open                                                                               |
| 3   | Draft              | PR is a draft                                                                                |
| 4   | Mergeable          | PR has merge conflicts                                                                       |
| 5   | Fork               | head repo differs from base repo                                                             |
| 6   | Diff provenance    | context was read from the local working tree while local `HEAD` differs from the PR head SHA |
| 7   | Check gate         | the gate above is not green                                                                  |
| 8   | Thread visibility  | review-thread resolution could not be read                                                   |
| 9   | Open threads       | one or more unresolved review threads                                                        |
| 10  | Changes requested  | a human's latest review is `CHANGES_REQUESTED`                                               |
| 11  | Human-only surface | any human-only path matched (repo path policy, step 5)                                       |
| 12  | Reviewability      | file or line budget exceeded (step 6)                                                        |
| 13  | Risk band          | overall band is 🟡 `medium` or 🔴 `high`                                                     |
| 14  | Confidence         | confidence below `0.90`                                                                      |
| 15  | Findings           | any finding at 🟡 `medium` or 🔴 `high`                                                      |

Gate 6 is about **provenance, not location**. It fails only when you read the diff or surrounding
code from the local working tree while that tree sits on a different commit — then the code you
judged is not the code in the PR. Reading entirely from the PR head via `gh pr diff` and
`gh api .../contents?ref=<head>` satisfies it no matter what branch is checked out; note the
provenance and pass.

That is separate from the **stale-SHA guard**, which always applies: re-read the head SHA
immediately before publishing and abort if it moved since you gathered context. Provenance is about
what you read; the stale guard is about what happened while you read it.

Gate 10 ignores this command's own prior comments. Take each human reviewer's **latest** review
state only; a later `APPROVED` supersedes an earlier `CHANGES_REQUESTED`.

Unresolved threads. Derive `owner`/`repo` rather than guessing them — a wrong guess returns
`NOT_FOUND`, which must fail gate 8 rather than be read as zero unresolved threads:

```sh
gh repo view --json owner,name --jq '.owner.login + " " + .name'

gh api graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) { nodes { isResolved isOutdated } }
      }
    }
  }' -F owner=<owner> -F repo=<repo> -F number=<number> \
  --jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)] | length'
```

If that query errors or is truncated, gate 8 fails — do not assume zero.

## Disposition

Two independent steps. Pick the disposition, then pick the emoji from the **primary blocker** — never
from a condition the primary blocker is not.

**Step 1 — disposition.** Evaluate in order; the first match wins.

| Condition                            | Disposition             | GitHub review event |
| ------------------------------------ | ----------------------- | ------------------- |
| Any 🟡 `medium` or 🔴 `high` finding | **REQUEST CHANGES**     | `REQUEST_CHANGES`   |
| Any gate 1–15 fails                  | **NEEDS HUMAN**         | `COMMENT`           |
| Every gate passes                    | **FAST-TRACK ELIGIBLE** | `COMMENT`           |

**Step 2 — emoji.** Determine the primary blocker first, by lowest rank in
[Blocker guidance](#blocker-guidance) below, then read the emoji off that blocker:

| Disposition / primary blocker                       | Emoji |
| --------------------------------------------------- | ----- |
| REQUEST CHANGES (any disposition-setting finding)   | 🛠️    |
| merge conflicts (rank 10)                           | 🚧    |
| unresolved review threads (rank 50)                 | 💬    |
| risk band, where the band is 🔴 `high` (rank 130)   | 🚨    |
| risk band, where the band is 🟡 `medium` (rank 130) | 🧭    |
| confidence (rank 140)                               | 🔎    |
| any other failed gate                               | 👀    |
| FAST-TRACK ELIGIBLE                                 | ✨    |

Deriving the emoji from the primary blocker is what keeps the icon and the printed next step
describing the same problem. The band rows are **not** evaluated ahead of the specific blockers: a PR
with a merge conflict _and_ a 🟡 Medium band has merge conflict as its primary blocker (rank 10 beats
rank 130), so it shows 🚧 and the rebase guidance — not 🧭 over rebase advice.

**Never submit `APPROVE`.** The review is submitted with the invoking engineer's token, so an
approval would consume a required human approval without a human having reviewed. FAST-TRACK
ELIGIBLE therefore posts as `COMMENT` and must state outright:

> This is not an approval. GitHub still requires one qualifying human approval.

## Blocker guidance

Report every failed gate, but lead with the highest-priority one — lowest rank wins.

| Rank | Blocked by                                              | Next step                                                                                                                   |
| ---- | ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 10   | pull request has merge conflicts                        | Rebase or merge `<base>`, resolve conflicts, and push.                                                                      |
| 15   | diff was read from a working tree on a different commit | Check out the PR head and re-run, or re-read the diff from the PR head; the assessment does not describe the pushed commit. |
| 20   | pull request is a draft                                 | Mark the PR ready for review, then reassess.                                                                                |
| 30   | pull request is not open                                | Reopen the PR if review should continue.                                                                                    |
| 40   | an active changes-requested review exists               | Address the reviewer's comments and re-request review.                                                                      |
| 50   | _n_ unresolved review threads                           | Resolve or reply to open review threads, then reassess.                                                                     |
| 60   | review-thread resolution could not be verified          | Ask a human reviewer to confirm threads are resolved.                                                                       |
| 70   | required checks are still running                       | Wait for CI to finish on this head SHA, then reassess. No code change is implied — nothing has failed.                      |
| 75   | configured check gate is not green                      | Fix failing or missing required checks on this head SHA, then reassess.                                                     |
| 80   | fork pull requests require human approval               | A maintainer must review from the upstream repository.                                                                      |
| 100  | base branch _x_ is not allowlisted                      | Target `<base>`, or use normal human review for this branch.                                                                |
| 110  | human-only: _reason_                                    | Request review from an owner of this surface — see `<owners pointer>`.                                                      |
| 120  | reviewability limit: _reason_                           | Split the PR, or have a human reviewer approve the full diff.                                                               |
| 130  | risk is MEDIUM / HIGH (only LOW can fast-track)         | Ask a qualified reviewer to approve; the change may be clean but is not fast-track eligible.                                |
| 140  | confidence _n_% (needs 90%)                             | No code change required for this gate — ask a reviewer to spot-check the assessment.                                        |

Phrase counts naturally: `1 unresolved review thread`, not `1 unresolved review thread(s)`.

Two guidance lines carry weight and must not be softened:

- **Confidence** — "No code change required for this gate." Low confidence is a statement about the
  assessment, not the code. Do not send someone hunting for a defect.
- **Risk band** — "the change may be clean but is not fast-track eligible." 🟡 Medium risk is not a
  finding.

Both lines are quoted verbatim and take **no** disc, even where they name a band — the discs belong
to printed scores, not to fixed guidance wording.
