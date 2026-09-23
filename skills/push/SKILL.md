---
name: push
description: "Push the current branch to origin, committing anything uncommitted first, and fix the routine rejections — missing upstream, remote ahead, expired auth, a hook that needs a tool installed. Stops, and never bypasses anything, on a protected branch, a failing hook, or a secret in the diff. Use when asked to push, or as the publish step of another workflow."
argument-hint: "[--no-commit] [--watch-ci] [--force-with-lease]"
---

Get this branch's work onto `origin`, and resolve what the push complains about — by fixing the cause, never by removing the check that complained. Push protection, pre-push hooks, and protected branches are the remote's rules; this skill obeys them and reports when it can't.

**Scope:** errors *the push itself* raises. It does not review the diff, open a PR (`/i:pull-request`), or chase a red CI run beyond reporting it — unless `--watch-ci` is set.

`$ARGUMENTS`:
- *(empty)* — commit everything uncommitted, then push.
- `--no-commit` — push only what is already committed; leave the working tree alone.
- `--watch-ci` — after a successful push, wait on the PR's checks and report what fails (Step 5).
- `--force-with-lease` — the local history was intentionally rewritten (rebase, amend) and overwriting the remote branch is the point. Never `--force`, and never on a shared branch.

**Repo-specific — read this first:** the "Shared branches and pre-push hooks" section of `docs/intus-skills/tickets-and-branches.md` in the repo you are in. It names the branches nobody pushes to directly and the hooks a push has to satisfy (LFS-tracked paths, for one). If the file is missing, treat `main`, `master`, and whatever `origin/HEAD` points at as shared, and say the repo hasn't configured this skill.

---

## Invoking this from another skill

Model-invocable: call it as `Skill(skill: "i:push", args: "--no-commit")` rather than reimplementing the retry table.

- **Run unattended.** Every branch below either fixes itself or terminates with a report. Do not stop to confirm routine work — staging deletions, rebasing onto a moved remote, and setting an upstream all just happen.
- **Only three things halt it**, and each returns a report rather than a question: a protected branch, a secret in the diff, and a rejection that survived three attempts.
- **Return the Step 5 report verbatim.** Callers key off `PUSHED` and `attempts`.
- **It commits and pushes** — that is the point of it. A caller that must not publish should not call this skill.

---

## Step 1 — Survey before touching anything

```bash
git rev-parse --abbrev-ref HEAD
git status -sb          # branch, upstream, ahead/behind, dirty paths
git log @{u}..HEAD --oneline 2>/dev/null || echo "no upstream"
```

Three terminal conditions, caught here rather than discovered by the remote:

- **On a shared branch** (per `tickets-and-branches.md`) — stop and report. Work belongs on a ticket branch. Never push directly to a shared branch, and never force-push one.
- **Detached HEAD** — stop and report. There is no branch to push.
- **Nothing ahead and nothing dirty** — already up to date. Report and stop; don't manufacture an empty commit.

## Step 2 — Commit what isn't committed

Skip with `--no-commit`.

```bash
git status --short
git diff --stat
git add -A
```

Stage everything, **including deletions** — a removed tracked file is a change like any other and gets committed without asking. Then make a conventional commit: `type(scope): subject`, imperative mood, matching recent history (`git log --oneline -10`). Split genuinely unrelated changes into separate commits rather than one grab-bag. End the message with:

```
Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
```

**One exception, and it is a hard stop:** if the staged set contains `.env*`, a key, a token, or anything else that reads as a credential, unstage it and report. Committing a secret is not undone by a later commit — it lives in the reflog and forces a rotation. Add it to `.gitignore` instead.

## Step 3 — Push

```bash
git push                                    # upstream already set
git push -u origin HEAD                     # no upstream yet
git push --force-with-lease                 # only with the flag, only on a ticket branch
```

## Step 4 — Fix what it rejects (max 3 attempts)

Read the actual error text — git names the cause. Match it, fix the cause, push again. Three attempts; if the same error survives all three, stop and report rather than escalating to a bigger hammer.

| Rejection | Cause | Fix |
|---|---|---|
| `no upstream branch` / `set-upstream` | Branch has never been pushed | `git push -u origin HEAD` |
| `non-fast-forward` / `fetch first` / `behind its remote` | Remote has commits you don't | `git pull --rebase`, then push again. Conflicts → resolve them; if the resolution isn't obvious, stop and report them |
| `protected branch` / `required status checks` | Pushing straight at a protected branch | Don't fight it. Report; the work needs a branch and a PR (`/i:pull-request`) |
| `GH013 … push cannot contain secrets` | GitHub push protection found a credential | **Never use the bypass URL.** Remove the secret from the commit (`git rebase -i`, or amend if it's the tip), report that the credential **must be rotated** — it's in the reflog — then push |
| `file … is N MB; exceeds GitHub's 100 MB limit` | Large blob | Track it with LFS (`.gitattributes`) or drop it from history. Don't retry unchanged |
| `git-lfs was not found on your path` (exit 2) | The LFS pre-push hook can't run | Install `git-lfs` the way `tickets-and-branches.md` says — else install the `git-lfs` program with the system's package manager, then run `git lfs install` (which needs that program) — and push again. **Never delete the hook** to get past it — the repo tracks files in LFS (the same section lists them), and a push without it replaces them with pointer stubs |
| `LFS … 422` / upload failure | LFS object rejected or over quota | Report it. Don't retry in a loop; it won't clear on its own |
| `Authentication failed` / `could not read Username` | Expired credential on the HTTPS remote | `gh auth status`, then `gh auth login`. Don't silently rewrite the remote to SSH — that's a config change nobody asked for |
| `Repository not found` with valid auth | No access, or a typo'd remote | Report. Don't guess at another remote |
| Pre-push hook fails for any other reason | The hook is doing its job | Fix what it flagged. **Never `--no-verify`** |

**Never, at any attempt count:** `--force` (as opposed to `--force-with-lease`), `--no-verify`, a secret-scanning bypass link, deleting a hook, or pushing to a shared branch to route around a branch problem. Each of these turns a blocked push into a worse problem that lands on someone else.

## Step 5 — Report

```bash
git status -sb
gh pr view --json number,url,isDraft,state 2>/dev/null || echo "no PR"
```

```
PUSHED: <branch> → origin/<branch>   |   BLOCKED: <reason>
  commits:  N   (<first> … <last>)
  attempts: N   [what was fixed, if anything]
  PR:       #NNN <url> (draft) | none — /i:pull-request to open one
```

With `--watch-ci`, follow the run and report the outcome:

```bash
gh run watch --exit-status || gh run view --log-failed | tail -40
```

Report which checks failed and why. Fix only failures this branch caused, and only ones with an obvious cause — a lint or type error in a file you just changed. Anything deeper is a separate task: name it and hand it back rather than starting an open-ended debugging loop inside a push.
