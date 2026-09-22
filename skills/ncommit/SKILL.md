---
name: ncommit
description: Analyze git changes and create logical, atomic conventional commits
argument-hint: "[context]"
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Read
---

Analyze git changes and create logical, atomic commits using conventional commits format.

This exists because just telling claude to "commit" sometimes fails if files are deleted and it tends to lump code together in too few commits.

Deletions are staged with `git add -A`, which is why rule 1 below needs no `git rm`. The allowlist
uses `Bash(git status:*)` rather than `Bash(git status)` — the bare form matches only the exact
string and blocks `git status --short`.

`allowed-tools` records the intended surface; it has not been observed to block anything when this
skill is invoked via the `Skill` tool. Rule 1 is what actually carries that weight — do not rely on
the frontmatter to contain an agent.

$ARGUMENTS

STRICT RULES:
1. ONLY use git status, git diff, git add, and git commit commands. NEVER use: git push, git reset, git revert, git clean, git rebase, git merge, git checkout, git branch, rm, mv, Write, or Edit.
2. Use conventional commits: feat|fix|docs|style|refactor|perf|test|build|ci|chore
3. Format: <type>(<scope>): <description> (max 50 chars)\n detailed description explaining the why and what of the change\n\nBREAKING CHANGE: description of the breaking change
4. Group related changes in one commit
5. Keep commits atomic and focused
6. One logical change per commit
7. After each commit, verify with git status
8. Include `Co-Authored-By` lines in every commit message, per `AGENTS.md`.

WORKFLOW:
- Examine changes with git status and git diff
- Plan commits (announce your strategy)
- Execute commits one by one
- Provide summary of completed commits, along with full descriptions.

EXAMPLES:
- feat(auth): add JWT validation
- fix(api): resolve memory leak
- docs(readme): update setup instructions
- refactor(utils): extract validation logic
