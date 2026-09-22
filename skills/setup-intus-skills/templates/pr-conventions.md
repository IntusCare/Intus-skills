<!-- SEED: strip every SEED comment. Source this from the PR template and the last few merged PRs,
     not from taste. -->
# Pull Request Conventions for Eng Skills

> **TL;DR** — Draft PR (always; a human marks it ready), `<n>` description sections, `<label>` label.

## Context

`pull-request` and `fix` ship in the shared `intus-skills` plugin. This file is what makes their
output look like a `<repo>` PR.

## Description sections

As concise as possible. Prefer bullets over prose.

<!-- SEED: match the repo's PR template if it has one, in its order and with its headings. -->

1. Title, `<with the ticket key if that's the convention>`
2. **Why** — problem statement, one paragraph
3. **What changed** — approach (<5 bullets), plus a reading order when the diff touches >5 files
4. **Design notes** — decisions and rejected alternatives (<5 bullets, skip unless really valuable)
5. **Testing** — commands actually run + the negative case. Never skipped: collapse it to one line,
   or `n/a — <one-line reason>` when nothing was run
6. **Conditional blocks** — see below
7. **Out of scope / follow-ups** (<5 bullets, skip unless really valuable)
8. `<attribution footer, if the repo requires one — point at where it's specified>`

<!-- SEED: keep only blocks the repo actually asks for. Each row is a path whose presence in the
     diff forces an extra section, because reviewers of that path always need it. -->
## Path-conditional blocks

Auto-include by touched path:

| Touched path            | Block to include        |
| ----------------------- | ----------------------- |
| `<migration path>`      | Migration plan          |
| `<dependency manifest>` | Dependency justification |
| `<ui path>`             | Before/after screenshots |

## Label

Apply `<label>` to the pull request.

<!-- SEED: keep only if the repo has a written review-comment style. Point at it; don't restate it. -->
## Review-comment style

Review findings and replies follow the house style in `<pointer>` — concise, imperative, one concern
per comment. That applies to findings posted on a PR and to a reply declining a reviewer's
suggestion.

<!-- SEED: keep only if the repo expects a coverage or checklist comment on every PR. -->
