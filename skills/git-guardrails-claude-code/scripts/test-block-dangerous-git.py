#!/usr/bin/env python3
"""Self-test for block-dangerous-git.sh: bypass attempts must exit 2, ordinary commands must exit 0.
Run: python3 scripts/test-block-dangerous-git.py"""
import json, subprocess, sys
import os
HOOK = os.path.join(os.path.dirname(os.path.abspath(__file__)), "block-dangerous-git.sh")
BLOCK = [
 "git push", "git push origin main", "git -C . push", "git -C /tmp/repo push --force", "/usr/bin/git push",
 "git  push", r"git pu\sh", "sudo git push", "env FOO=1 git push", "FOO=bar git push", "command git push",
 "xargs git push", "timeout 10 git push", "cd x && git push", "ls; git push", "ls | git push",
 "echo $(git push)", 'echo "$(git push)"', "echo `git push`", 'sh -c "git push"', "bash -lc 'cd x && git push'",
 'eval "git push"', "eval git push", "git -c alias.p=push p", "git reset --hard", "git reset --hard HEAD~1",
 "git clean -fd", "git clean -xdf", "git clean --force", "git branch -D foo", "git branch -fd foo",
 "git branch --delete --force foo", "git checkout .", "git checkout -- .", "git restore .",
 "git restore --staged --worktree .", "git restore -s HEAD -- :/", "cat <<EOF\n$(git push)\nEOF",
 "> out git push", "git push 2>&1", "git push > /dev/null 2>&1", "git --no-pager -C sub push",
 'echo "unbalanced \'quote; git push', "true && (git push)", "git push\n", "git status\ngit push",
]
ALLOW = [
 'echo "git push"', 'git log --grep "git push"', 'git commit -m "prepare git push"', "git status", "git clean -n",
 "git clean -i", "git branch -d foo", "git branch -a", "git reset HEAD~1", "git reset --soft HEAD~1",
 "git checkout main", "git checkout -b feature", "git checkout -- file.txt", "git restore file.txt",
 "cat <<'EOF'\ngit push\nEOF", "cat > f <<EOF\ngit push origin main\nEOF", 'grep -rn "git push" skills/',
 "python3 -c \"print('git push')\"", "git -C sub status", "git config --get alias.p", "gh pr create",
 'echo "unbalanced \'quote git status', "git fetch && git rebase origin/main", "git stash", "git diff --stat",
 "cat > hook.sh <<'EOF'\n#!/bin/bash\ngit push --force\ngit reset --hard\nEOF\nchmod +x hook.sh",
 "echo done # git push later", "git push-something",
]
def run(payload):
    p = subprocess.run(["bash", HOOK], input=payload, capture_output=True, text=True)
    return p.returncode, p.stderr.strip()
fails = 0
for cmd in BLOCK:
    rc, err = run(json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}}))
    if rc != 2: fails += 1; print(f"MISSED  rc={rc} {cmd!r}")
for cmd in ALLOW:
    rc, err = run(json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}}))
    if rc != 0: fails += 1; print(f"FALSE+  rc={rc} {cmd!r}\n        {err[:120]}")
# edge inputs
for label, payload, want in [
    ("empty stdin", "", 0),
    ("non-Bash tool", json.dumps({"tool_name": "Read", "tool_input": {"file_path": "git push"}}), 0),
    ("no command", json.dumps({"tool_name": "Bash", "tool_input": {}}), 0),
    ("invalid json", "{not json", 2),
    ("json array", "[1,2]", 2),
]:
    rc, err = run(payload)
    if rc != want: fails += 1; print(f"EDGE    {label}: rc={rc} want={want} {err[:100]}")
print(f"{len(BLOCK)} block cases, {len(ALLOW)} allow cases, 5 edge cases; failures: {fails}")
sys.exit(1 if fails else 0)
