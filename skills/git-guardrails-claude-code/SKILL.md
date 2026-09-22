---
name: git-guardrails-claude-code
description: Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code.
---

# Setup Git Guardrails

Sets up a PreToolUse hook that intercepts and blocks dangerous git commands before Claude executes them.

## What Gets Blocked

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean` with `-f` / `--force` (any cluster, e.g. `-xdf`)
- `git branch -D`, and `--delete` combined with `--force`
- `git checkout .` / `git restore .` (any whole-tree pathspec: `.`, `:/`, `*`)
- `git -c alias.<x>=…` — an on-the-fly alias that could hide any of the above

The hook parses the command the way a shell would rather than searching for a string, so:

- **Wrappers and global options don't hide it:** `git -C . push`, `sudo git push`, `env X=1 git push`,
  `/usr/bin/git push`, `cd x && git push`, `echo $(git push)`, `sh -c "git push"`, `eval "git push"`,
  and `$(git push)` inside an unquoted heredoc are all blocked.
- **Mentions aren't commands:** `echo "git push"`, `git log --grep "git push"`, a quoted heredoc that
  writes a script containing `git push`, and `git clean -n` are all allowed.
- **It fails closed.** Claude Code runs the command when a hook exits with anything other than 0 or 2, so
  every failure path — `python3` missing, unreadable or malformed input, an unexpected crash — exits 2
  and blocks. A repo where the hook cannot run is a repo where no Bash command runs until it's fixed
  or the hook is removed on purpose.

When blocked, Claude sees a message naming what the command would have done, saying the user has
prevented it, and telling it not to work around the block.

## What It Cannot See

Say this to the user when installing; it's what decides whether they also need branch protection:

- A script on disk that pushes (`./deploy.sh`), or a `Makefile` / `package.json` script that does.
- Git aliases already in `~/.gitconfig` (`git p` where `p = push`).
- Commands assembled from variables (`$GIT push`, `$CMD`).
- Anything that isn't the `Bash` tool.

It is a guardrail against mistakes by an agent, not a security boundary. Protected branches on the
remote are the boundary.

## Requirements

`bash` and `python3` on `PATH`. No `jq`.

## Steps

### 1. Ask scope

Ask the user: install for **this project only** (`.claude/settings.json`) or **all projects** (`~/.claude/settings.json`)?

### 2. Copy the hook script

The bundled script is at: [scripts/block-dangerous-git.sh](scripts/block-dangerous-git.sh)

Copy it to the target location based on scope:

- **Project**: `.claude/hooks/block-dangerous-git.sh`
- **Global**: `~/.claude/hooks/block-dangerous-git.sh`

Make it executable with `chmod +x`.

### 3. Add hook to settings

Add to the appropriate settings file:

**Project** (`.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

**Global** (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

If the settings file already exists, merge the hook into the existing `hooks.PreToolUse` array. Don't overwrite other settings.

### 4. Ask about customization

Ask if the user wants to add or remove anything from the blocked list. The rules live in the
`check_git` function of the copied script, one `if sub == ...` block per subcommand; each returns the
reason string Claude will see. Add or remove a block there — don't reintroduce a string match on the
raw command, which is what this script exists to avoid.

### 5. Verify

Run the bundled self-test against the copied script — it drives the hook with 46 bypass attempts,
28 ordinary commands, and malformed inputs, and fails on any mismatch:

```bash
cp <this-skill>/scripts/test-block-dangerous-git.py <hook-dir>/
python3 <hook-dir>/test-block-dangerous-git.py
```

Then spot-check the three behaviours by hand:

```bash
H=<path-to-script>
echo '{"tool_input":{"command":"git -C . push"}}'   | bash $H; echo "rc=$? (want 2)"
echo '{"tool_input":{"command":"echo \"git push\""}}' | bash $H; echo "rc=$? (want 0)"
echo 'not json'                                     | bash $H; echo "rc=$? (want 2: fails closed)"
```

If the user customised the pattern list in step 4, add a case for each change to the test file
before trusting it.
