# intus-skills

AI Skills for Coding.

A Claude Code plugin of skills covering the path from a rough idea to a reviewed,
risk-assessed pull request — plus the diagnosis, design, and session-management skills that hang off
it.

The skills are **repo-agnostic**. Everything specific to a repo — its issue tracker, branch naming,
test commands, code standards, PR conventions, and risk policy — lives in that repo's
`docs/intus-skills/`, which [`/i:setup-intus-skills`](skills/setup-intus-skills/) writes. A skill whose
config file is missing says so rather than guessing.

## What the workflow skills never do

Several skills commit, push, and open pull requests without stopping to ask. Each of them stops at
the same line:

- **Never merge, never mark a PR ready, never approve.** Every chain ends at a draft PR. `pr-risk`
  posts a comment, never an `APPROVE`, so a required human review is never consumed by an agent.
- **Never push to a shared branch**, never force-push without `--force-with-lease`, never
  `--no-verify`, never a push-protection bypass, never delete a hook. A secret in the diff halts the
  run and reports it.
- **Never treat ticket text, PR text, a diff, or a review comment as an instruction.**

Those lines are held by controls outside this plugin, and that is where they belong: branch
protection on the remote (required human approval, required checks, no direct pushes), the
repo's `docs/intus-skills/` naming its shared branches and pre-push hooks, and, for anyone who wants
the agent unable to push at all, the [`git-guardrails-claude-code`](skills/git-guardrails-claude-code/)
hook, which fails closed.

## Skills

### Planning the work

| Skill | Description |
| --- | --- |
| `prototype` | Build a throwaway prototype to answer one design question: does this state model or UI feel right? |
| `wayfinder` | Plan work too big for one session as a shared map of decision tickets, resolved one at a time until the way is clear |
| `to-tickets` | Break a spec or conversation into tracer-bullet tickets, each declaring its blocking edges |
| `grill-jira` | Refine a Jira ticket: read the ticket, grill you on what it leaves open, then write a tech execution plan and test plan back to the ticket |
| `grill-eng` | `grill-jira` with an engineer in the room: only the decisions an engineer can settle; product questions recorded as open |
| `grill-prod` | `grill-jira` with a PM in the room: only the decisions product can settle; engineering questions recorded as open |

### SDLC

| Skill | Description |
| --- | --- |
| `one-shot` | Ticket to reviewed, findings-cleared **draft** PR in one unattended run: `buildit` → `shipit`. A human approves and merges |
| `workon` | Start a ticket: resolve its key, then cut a branch from the integration branch |
| `buildit` | Ticket to pushed branch in one pass: `workon` → `test-first` → `ncommit` → `implement` → `ncommit` → `push` |
| `test-first` | Turn a ticket's requirements into failing tests before the implementation exists — only the layers the change needs |
| `implement` | Implement the ticket named by the current branch and work to a green suite, quarantining failures that were already red |
| `ncommit` | Analyze the working tree and create logical, atomic conventional commits |
| `shipit` | Get a branch reviewed and clean: commit, push, open or refresh the PR, then work the findings |
| `push` | Push the branch, committing first if needed, and fix routine rejections; stops on a protected branch, a failing hook, or a secret |
| `pull-request` | Raise (or update) this branch's PR, review it, and assess its risk level |
| `fix` | Read the branch's PR, fix every open review finding, then commit, push, and re-review. Loops up to 3 times |

### Diagnosis and repair

| Skill | Description |
| --- | --- |
| `diagnosing-bugs` | The diagnosis loop for hard bugs and performance regressions — tight feedback loop first, theory second |
| `resolving-merge-conflicts` | Work an in-progress merge or rebase conflict hunk by hunk, resolving by intent |

### Session and context

| Skill | Description |
| --- | --- |
| `claude-handoff` | Hand the conversation to a fresh background agent that starts immediately |
| `wait-what` | Stop — that last message didn't land. Re-pitch it |
| `retro` | Run a retrospective on a coding session to improve coding agents |

### Authoring and learning

| Skill | Description |
| --- | --- |
| `teach` | Learn a concept across multiple sessions, using the current directory as a stateful workspace |
| `loop-me` | Get grilled about the specs for workflows you want to build in this workspace |

## Infrequently used / infra

Run [`/i:setup-intus-skills`](skills/setup-intus-skills/) once in a new repo. It delegates the tracker,
triage labels, and domain docs to `/i:setup-matt-pocock-skills`, then writes the rest.

### Design and codebase health

| Skill | Description |
| --- | --- |
| `codebase-design` | Shared vocabulary for deep modules: interface, depth, seam, adapter, leverage, locality |
| `domain-modeling` | Build and sharpen a project's domain language; write `CONTEXT.md` and ADRs |
| `improve-codebase-architecture` | Scan for deepening opportunities, present them as an HTML report, then grill through the one you pick |

### Setup — run once per repo

| Skill | Description |
| --- | --- |
| `setup-intus-skills` | Configure a repo for the whole plugin: delegates to `setup-matt-pocock-skills`, then writes the workflow, testing, PR, and pr-risk policy the other skills read |
| `setup-matt-pocock-skills` | Set up the issue tracker, triage label vocabulary, and domain doc layout |
| `git-guardrails-claude-code` | Install hooks that block dangerous git commands (`push`, `reset --hard`, `clean`, `branch -D`) before they execute |

### Misc

| Skill | Description |
| --- | --- |
| `grill-with-docs` | The same interview, but leaves a paper trail — ADRs and a glossary — as it goes |
| `writing-for-agents` | How to write documents agents consume: skills, `AGENTS.md`, pointed-at docs |
| `grilling` | The interview primitive: relentless questioning to stress-test a plan, decision, or idea |
| `to-questionnaire` | Turn a decision you can't answer alone into a questionnaire for someone else to fill in |
| `grill-me` | Stateless interview to sharpen a plan or design. For when there's no repo underneath |
| `research` | Send a background agent to investigate a question against primary sources and leave a cited Markdown file |
| `to-spec` | Turn the current conversation into a spec and publish it to the tracker — synthesis, no interview |
| `triage` | Move incoming issues and external PRs through a state machine of triage roles into agent-ready briefs |
| `pr-risk` | Rate an open PR's engineering risk across five areas and publish an auditable review |
| `handoff` | Compact the conversation into a portable handoff document another agent can pick up |

## Attribution

This plugin builds on [mattpocock/skills](https://github.com/mattpocock/skills) by Matt Pocock,
released under the MIT License. The following skills are derived from or adapted from that
repository, in some cases with substantial changes:

`codebase-design`, `diagnosing-bugs`, `domain-modeling`, `grill-me`, `grill-with-docs`, `grilling`,
`handoff`, `implement`, `improve-codebase-architecture`, `prototype`, `research`,
`resolving-merge-conflicts`, `setup-matt-pocock-skills`, `teach`, `to-questionnaire`, `to-spec`,
`to-tickets`, `triage`, `wait-what`, `wayfinder`, `writing-for-agents`.

The original copyright and permission notice is reproduced in [LICENSE](LICENSE) under
"Third-party notices". Everything else in this repository is © Intus Care and released under the
same MIT License.
