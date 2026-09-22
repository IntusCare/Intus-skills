<!-- SEED: strip every SEED comment. Fill from what you observed, not from this file's examples.
     The tracker section must agree with issue-tracker.md, which setup-matt-pocock-skills wrote. -->
# Tickets and Branches for Eng Skills

> **TL;DR** — `<tracker>` is the tracker. Branches are `<pattern>` cut from `<base>`. `<tool order>`.
> Shared branches: `<list>`. Pre-push hooks: `<none / LFS / ...>`.

## Context

The `workon`, `buildit`, `test-first`, `implement`, `pull-request`, `push`, and `shipit` skills ship
in the shared `intus-skills` plugin and carry no repo-specific knowledge. This file supplies `<repo>`'s.

## Tracker access

<!-- SEED: list the access routes in preference order, most reliable first, with the exact tool or
     command for each. Name the project keys / label sets / board in active use. -->

Use the first that works, in this order:

1. `<primary — e.g. an MCP tool with its workspace id, or `gh issue`>`
2. `<fallback CLI, with a pointer to its manual if the repo has one>`

If none work, stop and name which one failed and how. **Never invent a ticket key.**

<!-- SEED: delete this section entirely for a local-markdown tracker; say instead that issues are
     files under `.scratch/<feature>/` and how they are named. -->

## Resolving a key from arguments

Extract `<key-regex>` — from the path if it's a URL (`<example-url>` → `<KEY>`), or as-is if it's
already a key.

When there's no key, ask for one and end the turn on the question, so the next message is
unambiguously the answer:

> What's the ticket key or link?

Never derive a key from the branch name or the working tree at this stage.

## Resolving a key from the branch

Skills that run on a branch `workon` already cut (`test-first`, `implement`) take the ticket from
the branch name instead of an argument: `<parsing rule>`. When the branch carries no key, `<stop
and ask / proceed without one>`.

## Fetching a ticket

`<fetch command>`; else `<fallback>`. If the fetch fails, report the error and stop — don't branch
off a key you couldn't read.

Read the whole ticket, not just the title: acceptance criteria, any linked ticket the description
leans on, and `<any repo-specific convention — a QA test plan comment, a spec link>`.

## Branch naming

`<pattern>`, where the slug is the summary lowercased, non-alphanumerics collapsed to single
hyphens, trailing hyphens trimmed, max `<n>` chars — e.g. `<worked example>`.

## Cutting the branch

Base `<base>` (the default):

```bash
git fetch origin <base>
git checkout <base> && git pull origin <base>
git checkout -b <BRANCH>
```

Base the current branch (`--base=current`):

```bash
git checkout -b <BRANCH>
```

Report which branch you based on and its ticket key, if any — stacked work is easy to lose track
of. Uncommitted changes follow you onto the new branch either way; if `git status` isn't clean, say
what's carrying over before you branch.

## Shared branches and pre-push hooks

<!-- SEED: `push` and `shipit` read this section. Shared branches come from branch protection and
     `origin/HEAD`, not from taste. Hooks come from `core.hooksPath` / `.husky/` / `.git/hooks` and
     `.gitattributes` — list only hooks that actually exist. Delete the LFS bullet if
     `.gitattributes` has no `filter=lfs` lines. -->

**Shared branches** — never pushed to directly, never force-pushed: `<base>`, `<default branch>`.
A skill that finds itself on one stops and reports.

**Pre-push hooks** a push has to satisfy:

- `<hook>` — `<what it checks>`. Install: `<command>`. A failing hook is fixed, never deleted or
  bypassed with `--no-verify`.
- **Git LFS** — `.gitattributes` tracks `<paths>`. Install with `<install command>`. Pushing
  without LFS installed replaces those files with pointer stubs; a push blocked on a missing
  `git-lfs` is fixed by installing it, never by removing the hook.
