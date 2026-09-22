---
name: setup-intus-skills
description: "Configure this repo for the whole intus-skills plugin: run setup-matt-pocock-skills for the issue tracker, triage labels, and domain docs, then write the workflow, testing, PR, and pr-risk policy the other skills read from docs/intus-skills/. Run once, before first use."
disable-model-invocation: true
---

# Setup Eng Skills

The skills in this plugin carry no repo knowledge on purpose. `docs/intus-skills/` is the repo's half
of that contract: the commands, branch names, paths, and policy they read at runtime. This skill
writes it.

Two halves, in order:

1. **Delegate** the issue tracker, triage vocabulary, and domain-doc layout to
   `setup-matt-pocock-skills`, which already owns them.
2. **Write** everything it doesn't cover — workflow, testing, PR conventions, and `pr-risk` policy.

This is prompt-driven, not a script. Explore, propose, confirm, then write.

## What reads what

| File                         | Read by                                                    | Source              |
| ---------------------------- | ---------------------------------------------------------- | ------------------- |
| `issue-tracker.md`           | `to-spec`, `to-tickets`, `wayfinder`, `mp-code-review`     | delegated (half 1)  |
| `triage-labels.md`           | `triage`, `to-spec`, `to-tickets`                          | delegated (half 1)  |
| `domain.md`                  | nothing by filename — it records the `CONTEXT.md` and ADR layout that `grill-with-docs` and `domain-modeling` operate on | delegated (half 1) |
| `tickets-and-branches.md`    | `workon`, `buildit`, `test-first`, `implement`, `pull-request` | you              |
| `test-layers.md`             | `test-first`, `implement`                                  | you                 |
| `test-commands.md`           | `test-first`, `implement`                                  | you                 |
| `pre-existing-failures.md`   | `implement`                                                | you                 |
| `code-standards.md`          | `implement`                                                | you                 |
| `pr-conventions.md`          | `pull-request`, `fix`                                      | you                 |
| `test-plans.md`              | `grill-jira`                                               | you                 |
| `pr-risk-path-policy.md`     | `pr-risk`                                                  | you                 |
| `pr-risk/risk-model.md`      | `pr-risk`                                                  | you                 |
| `pr-risk/gates.md`           | `pr-risk`, `fix`                                           | you                 |
| `pr-risk/output-contract.md` | `pr-risk`                                                  | you                 |
| `README.md`                  | humans, and any agent orienting in the directory           | you                 |

Verified against this plugin's skills, not assumed — re-check with
`grep -rl '<filename>' <skills-dir>` if a skill has been added or renamed since.

**Write a file only when a skill that reads it is installed.** Check the skills folder alongside
this one, or your own available skills. An unused config file is a claim about this repo that
nothing verifies and nobody maintains.

## The one rule

**Every fact in these files is observed, never assumed.**

An absent file is harmless: each skill that points here degrades gracefully, saying the repo hasn't
configured it. A **present and wrong** file is not. It is `implement` running `yarn test` in a pnpm
repo, `workon` branching off `main` in a repo that ships from `develop`, or `pr-risk` applying a
`packages/api/**` floor to a repo with no `packages/`. All three fail confidently, which is the
expensive kind.

So: verify or omit. Read `package.json` scripts before writing a command. Read the CI workflow
before naming a required check. Run `git branch -r` before naming an integration branch. Where you
cannot observe a fact, leave that section out and list it in your closing report as something the
user must fill in. Never copy a path, package name, or command out of the templates in this folder
or out of another repo — they are shapes, not content.

## Process

### 1. Explore

Read; don't assume. Cheap probes, all of them worth running:

```sh
git remote -v                                  # host, org, repo name
git branch -r --sort=-committerdate | head     # develop? main? trunk?
gh pr list --state merged --limit 5 --json baseRefName --jq '.[].baseRefName' | sort | uniq -c
ls                                             # workspace shape
cat package.json 2>/dev/null                   # scripts, packageManager, workspaces
ls pnpm-workspace.yaml turbo.json Cargo.toml go.mod pyproject.toml Makefile 2>/dev/null
ls .github/workflows/ 2>/dev/null
ls docs/intus-skills/ 2>/dev/null                # has this already run?
ls AGENTS.md CLAUDE.md CONTEXT.md 2>/dev/null
ls .github/pull_request_template.md .github/CODEOWNERS 2>/dev/null
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null   # the default branch
git config core.hooksPath; ls .husky .git/hooks 2>/dev/null | grep -v sample   # pre-push hooks
grep -n 'filter=lfs' .gitattributes 2>/dev/null           # LFS-tracked paths
```

What you are trying to learn, and where each answer lands:

| Question                                   | Look at                                                            | Lands in                   |
| ------------------------------------------ | ------------------------------------------------------------------ | -------------------------- |
| Package manager and runner                 | `packageManager`, lockfile, `scripts`                              | `test-commands.md`         |
| The exact test command, and a narrow-scope form | `scripts.test`, a neighbouring test file's path                | `test-commands.md`         |
| Type-check, lint, format gates             | `scripts`, the CI workflow                                         | `test-commands.md`         |
| Any test-harness trap (retries, required services, env) | `scripts.test` flags, `docker-compose*`, `setup-tests.*`  | `test-commands.md`         |
| Integration branch                         | `git branch -r`, merged PR base refs, branch protection            | `tickets-and-branches.md`, `pre-existing-failures.md`, `pr-risk-path-policy.md` |
| Branch naming already in use               | `git branch -r`, recent merged PR head refs                        | `tickets-and-branches.md`  |
| Shared branches and pre-push hooks         | branch protection, `origin/HEAD`, `core.hooksPath`, `.husky/`, `.gitattributes` | `tickets-and-branches.md`  |
| Test layers that actually exist            | where `*.test.*` / `*.spec.*` files sit, an `e2e` package, evals    | `test-layers.md`           |
| Standards worth putting in front of an agent | `AGENTS.md`, `CLAUDE.md`, `docs/`, lint config                    | `code-standards.md`        |
| PR shape                                   | `pull_request_template.md`, the last few merged PR bodies          | `pr-conventions.md`        |
| Required checks                            | the CI workflow's job names, branch-protection settings            | `pr-risk/gates.md`         |
| Sensitive surfaces                         | auth, migrations, schema, permissions, deploy, secrets directories | `pr-risk-path-policy.md`   |
| Owners of those surfaces                   | `CODEOWNERS`, `docs/`                                              | `pr-risk-path-policy.md`   |
| Docs frontmatter convention                | any two files under `docs/`                                        | every file you write       |

**Match the repo's docs convention.** If files under `docs/` carry YAML frontmatter (`title`,
`description`, `category`, `owner`, `status`, `tags`), give every file you write the same keys with
real values. If they carry none, write none. Consistency here is what keeps these files inside the
repo's own doc tooling rather than beside it.

### 2. Delegate half 1

Run `setup-matt-pocock-skills` **before writing anything**. It settles the issue tracker that
`tickets-and-branches.md` builds on, and it creates the `## Agent skills` block in
`CLAUDE.md`/`AGENTS.md` that you extend in step 5.

Try `Skill(skill: "setup-matt-pocock-skills")`. It is marked `disable-model-invocation`, so the call
may be refused — when it is, read `../setup-matt-pocock-skills/SKILL.md` and follow it end to end
yourself, seed templates included. Either route, let it ask its own questions; don't answer them on
the user's behalf or pre-empt them with your own.

If `docs/intus-skills/issue-tracker.md` already exists, half 1 has run. Say so, don't re-run it, and
read the existing file — `tickets-and-branches.md` has to agree with it.

### 3. Take the remaining sections in order

One section, one answer, then the next. **Lead with the answer exploration already suggests** so the
user can accept it in a word, and skip any section exploration settled outright. Say where each
answer will be written.

**Section A — Integration branch and branch naming.** Propose the base branch you actually observed
(the modal base ref of recent merged PRs beats a guess from branch names) and the naming pattern
recent branches follow. If the repo's tracker is local markdown, there is no ticket key to put in a
branch name — propose a slug-only pattern instead. In the same section, name the **shared branches**
(the integration branch, the default branch, anything protected) and every **pre-push hook** you
found — LFS-tracked paths from `.gitattributes`, a `.husky/pre-push`, a `core.hooksPath` script —
with its install command. `push` and `shipit` read these to know where they must stop and which hook
failures are fixed by installing something rather than by retrying.

**Section B — Test and verification commands.** Propose the commands from `scripts`, including the
narrow-scope form, and every gate CI enforces. Name any trap you found: a retry flag that hides
flakes, a database that must be running, a required env file. **Do not invent a script that isn't
declared.** If there is no test command at all, say so and skip `test-commands.md` and
`test-layers.md` both — `test-first` and `implement` will then say the repo hasn't configured them,
which is the truth.

**Section C — Test layers.** Propose only layers with evidence on disk: unit tests beside sources,
an integration harness, a permission-test convention, an e2e package, evals. One row per layer, each
with where the file goes and which harness it uses. A layer nobody has written yet is not a layer.

**Section D — Code standards.** This is the short list an agent breaks mid-implementation, not the
authority. Propose up to ~8 lines drawn from `AGENTS.md`, `CLAUDE.md`, or the repo's own docs, each
pointing at the full rule. If the repo has no written standards, skip the file rather than inventing
house style.

**Section E — Pre-existing failures.** `implement` may exclude a red test from its green bar only by
proving the failure predates the branch. Propose the procedure this repo's tooling actually
supports: the baseline command, whether a worktree needs its own install, and whether two suites can
run concurrently (a shared test database means no).

**Section F — PR conventions.** Propose the description sections, any path-conditional block worth
requiring, and the label to apply — sourced from the PR template and the last few merged PRs, not
from taste. PRs always open as drafts; that is the plugin's rule, not the repo's choice, so don't ask.

**Section H — Test plans.** Only if `grill-jira` is installed. Propose the placement and line
format the repo already uses — read three real plan comments (or plan files) before proposing
anything. The audience decides the placement: if QA works from the tracker and never opens the repo,
the plan belongs on the ticket. If the repo has no convention at all, skip the file rather than
inventing one; `grill-jira` will then write its description block and say the test plan was skipped.

**Section G — `pr-risk` policy.** Only if `pr-risk` is installed. Four files; three are close to
repo-agnostic and come from the seeds, and the fourth is entirely this repo's. Present a **draft
path policy** for confirmation: the classification globs, the HIGH and MEDIUM surfaces, the
human-only surfaces, the reviewability budget, and the mandatory content findings. Expect the user
to correct it — they know which directory is the control plane and which one merely sounds like it.

### 4. Confirm

Show the full file list you're about to write, and the contents of anything you generated rather
than seeded — `tickets-and-branches.md`, `test-commands.md`, `test-layers.md`, `code-standards.md`,
`pr-conventions.md`, and the path policy. Let the user edit before anything lands on disk.

### 5. Write

Seeds live in [templates/](./templates/). Each one is a **shape**: its headings, tables, and the
invariants in bold are the part to keep; every path, command, and example is a placeholder to
replace with what you observed.

| Template                                                             | Adaptation                                                                                |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| [README.md](./templates/README.md)                                   | Keep only rows for files you wrote                                                        |
| [tickets-and-branches.md](./templates/tickets-and-branches.md)       | Tracker access from half 1, observed base branch and naming                               |
| [test-commands.md](./templates/test-commands.md)                     | Real scripts only; drop sections for gates this repo has no command for                   |
| [test-layers.md](./templates/test-layers.md)                         | One row per layer with evidence; delete the rest                                          |
| [pre-existing-failures.md](./templates/pre-existing-failures.md)     | The baseline procedure this repo's tooling supports                                       |
| [code-standards.md](./templates/code-standards.md)                   | The repo's own rules, each pointing at its authority                                      |
| [pr-conventions.md](./templates/pr-conventions.md)                   | Sections, conditional blocks, and label from the PR template and merged PRs               |
| [test-plans.md](./templates/test-plans.md)                           | Placement, lifecycle, and line format read off three real plans                           |
| [pr-risk-path-policy.md](./templates/pr-risk-path-policy.md)         | Generated from the repo tree; a fresh `POLICY_VERSION`; **derivation notes deleted**      |
| [pr-risk/risk-model.md](./templates/pr-risk/risk-model.md)           | Near-verbatim; swap the calibration bullets, archetypes, and examples for this repo's     |
| [pr-risk/gates.md](./templates/pr-risk/gates.md)                     | Near-verbatim; fill in required checks and base branch. **Keep all 15 gates and the rank table** |
| [pr-risk/output-contract.md](./templates/pr-risk/output-contract.md) | Near-verbatim; swap the worked example for one from this repo                             |

Then extend the `## Agent skills` block that half 1 wrote, in whichever of `CLAUDE.md` /
`AGENTS.md` it chose — never the other one, and never both. Add one sub-block per file you wrote,
in the same one-line-plus-pointer form it uses:

```markdown
### Workflow and testing

Branches are `<pattern>` off `<base>`. See `docs/intus-skills/tickets-and-branches.md`,
`test-layers.md`, `test-commands.md`, `pre-existing-failures.md`, and `code-standards.md`.

### Pull requests

[one line]. See `docs/intus-skills/pr-conventions.md`.

### PR risk policy

[one line]. See `docs/intus-skills/pr-risk-path-policy.md` and `docs/intus-skills/pr-risk/`.
```

Update an existing block in place rather than appending a second one, and leave the surrounding
sections alone.

### 6. The path policy is a first draft, and say so

Every other file states something the repo already does. `pr-risk-path-policy.md` states a
**judgement** about consequence, and a first pass gets some of it wrong in both directions: a
sensitive-sounding router that is really a plain CRUD surface, a quiet utility that is really the
tenant-isolation seam.

So before you finish, **measure** rather than trusting the draft:

- For each mandatory content finding, count how often the pattern already appears in code that is
  known-good (`grep -rn <pattern> <src> | wc -l`). A rule that fires on a hundred correct lines is
  not a rule; either exempt the legitimate uses or drop it. **The base rate wins over the prose.**
- Record the number you actually got, next to the rule, with the date and commit.
- Sanity-check the floors against the last handful of merged PRs. If nearly every one lands MEDIUM
  or higher, nothing can ever fast-track and the policy is decoration.

Write the measurement commands into the file's `Measurements` section so the next person can re-run
them, and tell the user in your closing report that this file wants a second pass with someone who
knows the codebase.

### 7. Done

Report:

- Every file written, and every file **skipped with the reason** — "no test command declared", "the
  `triage` skill isn't installed".
- Every fact you could not observe and left as a gap for the user.
- That `pr-risk-path-policy.md` is a draft pending the measurement pass in step 6.
- That these files are edited directly from here on; re-running this skill is for starting over.

## Guardrails

- **Never write a command you haven't seen declared.** A plausible command is the worst output of
  this skill.
- **Never copy content out of another repo**, including the examples in the seeds. Copy the shape.
- **Don't create `AGENTS.md` when `CLAUDE.md` exists**, or the reverse. Edit the one that's there.
- **Don't overwrite a file that already exists** without showing the user a diff first. These files
  get hand-tuned, and the tuning is the valuable part.
- **Don't set a policy the repo can't meet.** A required check that isn't in CI blocks every PR
  forever.
- When the two halves disagree — half 1 recorded a local-markdown tracker, but branch names carry
  ticket keys — stop and ask. Don't paper over it.
