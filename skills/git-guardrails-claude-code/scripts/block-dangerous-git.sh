#!/bin/bash
# Claude Code PreToolUse hook (matcher: Bash) that blocks destructive git commands.
#
# Exit codes, per the Claude Code hook contract:
#   0  allow the command
#   2  block it; stderr is shown to the model
# Any other exit code is treated by Claude Code as a *non-blocking* error and the
# command runs anyway. This script therefore FAILS CLOSED: every failure path —
# missing interpreter, unreadable input, an unexpected crash — is converted to exit 2.
#
# What it looks for is decided by parsing the command the way a shell would (words,
# quotes, `;`/`&&`/`|` separators, `$(...)`, `sh -c "..."`, `eval`, heredocs), then
# reading each `git` invocation's real subcommand after its global options. So
# `git -C . push` is blocked and `echo "git push"` is not.
#
# Known limits, on purpose: it cannot see inside scripts on disk, git aliases already
# in your config, or commands built from variables (`$CMD push`). It is a guardrail
# against mistakes, not a substitute for branch protection on the remote.

set -u

fail_closed() {
  printf 'BLOCKED: block-dangerous-git.sh could not run (%s). Failing closed: no Bash command is allowed until this is fixed or the hook is deliberately removed.\n' "$1" >&2
  exit 2
}

INPUT=$(cat) || fail_closed "could not read the tool input"

command -v python3 >/dev/null 2>&1 || fail_closed "python3 is not on PATH"

read -r -d '' PY <<'PYTHON' || true
import json, os, re, shlex, sys

MAX_DEPTH = 6
SHELLS = {"sh", "bash", "zsh", "dash", "ksh", "fish"}
WRAPPERS = {"command", "exec", "sudo", "doas", "env", "nohup", "nice", "ionice", "time",
            "builtin", "xargs", "timeout", "stdbuf", "chronic", "caffeinate"}
WRAPPER_OPTS_WITH_ARG = {"-u", "-g", "-n", "-C", "--chdir", "-S", "-I", "-L", "-P", "-k", "-s", "-i", "-o", "-e"}
GIT_OPTS_WITH_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--super-prefix",
                     "--config-env", "--list-cmds"}
ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
DURATION = re.compile(r"^\d+(\.\d+)?[smhd]?$")
WHOLE_TREE = {".", "./", ":/", ":/.", ":(top)", "*", "./*"}
REDIRECTS = {"<", ">", ">>", "<<", "<<<", "<>", ">|", "&>", "&>>", ">&", "<&"}
PUNCT = ";|&()<>\n"

def block(reason):
    sys.stderr.write(
        "BLOCKED: " + reason + ". The user has prevented you from doing this. Do not work around "
        "it (no --no-verify, no wrapping it in a script, no alias); tell the user and let them run it.\n")
    sys.exit(2)

def base(word):
    return word.rsplit("/", 1)[-1]

def short_letters(tok):
    return set(tok[1:]) if tok.startswith("-") and not tok.startswith("--") and len(tok) > 1 else set()

# ---- git subcommand rules ------------------------------------------------------------

def check_git(args):
    """args = everything after the `git` word. Returns a reason string or None."""
    i = 0
    while i < len(args):
        a = args[i]
        if not a.startswith("-"):
            break
        if a == "-c":
            val = args[i + 1] if i + 1 < len(args) else ""
            if val.startswith("alias."):
                return "`git -c alias.…` defines an on-the-fly alias, which can hide a blocked subcommand"
            i += 2
            continue
        if a in GIT_OPTS_WITH_ARG:
            i += 2
            continue
        i += 1
    else:
        return None
    sub, rest = args[i], args[i + 1:]

    if sub == "push":
        return "this runs `git push`"
    if sub == "reset" and "--hard" in rest:
        return "this runs `git reset --hard`"
    if sub == "clean":
        for r in rest:
            if r == "--force" or "f" in short_letters(r):
                return "this runs `git clean` with --force"
    if sub == "branch":
        letters = set().union(*(short_letters(r) for r in rest)) if rest else set()
        delete = "--delete" in rest or "d" in letters
        force = "--force" in rest or "f" in letters
        if "D" in letters or (delete and force):
            return "this force-deletes a branch (`git branch -D`)"
    if sub in ("checkout", "restore"):
        for r in rest:
            if r in WHOLE_TREE:
                return f"this runs `git {sub} {r}`, discarding every working-tree change"
    return None

# ---- shell parsing -------------------------------------------------------------------

def substitutions(text):
    """Inner text of every $(...) and `...` in text."""
    out = []
    i = 0
    while True:
        j = text.find("$(", i)
        if j < 0:
            break
        depth, k = 0, j + 1
        while k < len(text):
            if text[k] == "(":
                depth += 1
            elif text[k] == ")":
                depth -= 1
                if depth == 0:
                    break
            k += 1
        out.append(text[j + 2:k])
        i = k + 1
    parts = text.split("`")
    out.extend(parts[1::2])
    if len(parts) % 2 == 0:          # unbalanced backtick: scan the tail too
        out.append(parts[-1])
    return [s for s in out if s.strip()]

HEREDOC = re.compile(r"(?<!<)<<(?!<)-?\s*(?:'([^']+)'|\"([^\"]+)\"|\\?([^\s;|&()<>]+))")

def strip_heredocs(text, depth):
    """Remove heredoc bodies so their prose is not parsed as commands; still scan
    unquoted bodies for $(...) and backticks, which the shell would expand."""
    lines = text.split("\n")
    out, i = [], 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        pending = [(m.group(1) or m.group(2) or m.group(3), m.group(1) is None and m.group(2) is None
                    and not line[m.start():].lstrip("<-").lstrip().startswith("\\"), "-" in line[m.start():m.start() + 3])
                   for m in HEREDOC.finditer(line)]
        i += 1
        for delim, unquoted, dash in pending:
            body = []
            while i < len(lines):
                l = lines[i]
                i += 1
                if (l.lstrip("\t") if dash else l) == delim:
                    break
                body.append(l)
            if unquoted:
                for inner in substitutions("\n".join(body)):
                    analyze(inner, depth + 1)
    return "\n".join(out)

def tokenize(text):
    lex = shlex.shlex(text, posix=True, punctuation_chars=PUNCT)
    lex.whitespace = " \t\r"
    lex.whitespace_split = True
    lex.commenters = ""
    return list(lex)

def segments(tokens):
    """Split a token list into simple commands, dropping redirections."""
    seg, i = [], 0
    while i < len(tokens):
        t = tokens[i]
        if t and all(c in PUNCT for c in t):
            if t in REDIRECTS:
                i += 2                        # operator + its target / delimiter
                continue
            if seg:
                yield seg
            seg = []
            i += 1
            continue
        if re.match(r"^\d*(>>?|<)&?\d*$", t) or t in REDIRECTS:   # 2>&1, 2>, &>
            i += 2 if t.endswith((">", "<")) else 1
            continue
        seg.append(t)
        i += 1
    if seg:
        yield seg

def strip_wrappers(words):
    i = 0
    while i < len(words):
        w = words[i]
        if ASSIGN.match(w):
            i += 1
            continue
        b = base(w)
        if b in WRAPPERS:
            i += 1
            if b == "timeout" and i < len(words) and DURATION.match(words[i]):
                i += 1
            while i < len(words) and words[i].startswith("-"):
                i += 2 if words[i] in WRAPPER_OPTS_WITH_ARG else 1
            continue
        break
    return words[i:]

def analyze_segment(words, depth):
    words = strip_wrappers(words)
    if not words:
        return
    head = base(words[0])
    if head == "git":
        reason = check_git(words[1:])
        if reason:
            block(reason)
        return
    if head in SHELLS:
        for j, w in enumerate(words[1:], 1):
            if w.startswith("-") and not w.startswith("--") and "c" in w and j + 1 < len(words):
                analyze(words[j + 1], depth + 1)
                break
        return
    if head == "eval":
        analyze(" ".join(words[1:]), depth + 1)

def analyze(text, depth=0):
    if depth > MAX_DEPTH or not text.strip():
        return
    for inner in substitutions(text):
        analyze(inner, depth + 1)
    text = strip_heredocs(text, depth)
    try:
        tokens = tokenize(text)
    except ValueError:
        # Unbalanced quotes: fall back to a word-level scan. Over-blocks rather than under-blocks.
        words = [w for w in re.split(r"[\s;|&()<>`]+", text) if w]
        for k, w in enumerate(words):
            if base(w) == "git":
                reason = check_git(words[k + 1:k + 40])
                if reason:
                    block(reason + " (command could not be fully parsed; fix the quoting if this is a false positive)")
        return
    for seg in segments(tokens):
        analyze_segment(seg, depth)

# ---- entry -----------------------------------------------------------------------------

raw = sys.stdin.read()
try:
    data = json.loads(raw) if raw.strip() else {}
except Exception as e:
    block(f"the hook could not parse its input as JSON ({e}), so it cannot tell what would run")
if not isinstance(data, dict):
    block("the hook input was not a JSON object, so it cannot tell what would run")
if data.get("tool_name") not in (None, "Bash"):
    sys.exit(0)
tool_input = data.get("tool_input") or {}
cmd = tool_input.get("command") if isinstance(tool_input, dict) else None
if not isinstance(cmd, str) or not cmd.strip():
    sys.exit(0)
analyze(cmd)
sys.exit(0)
PYTHON

printf '%s' "$INPUT" | python3 -c "$PY"
rc=$?
case $rc in
  0) exit 0 ;;
  2) exit 2 ;;
  *) fail_closed "the parser exited with status $rc" ;;
esac
