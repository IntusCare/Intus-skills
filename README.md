# SkillSet

*A complete software factory*

Skills are grouped by who reaches for them. Each group lists its skills in the order they tend to fire, along with the main flow that strings them together.

---

## Shared

Skills every role uses.

1. `/share-grill-me` — **Interview.** Align with the AI on an idea before committing to it. Replaces `/plan`
2. `/share-wait-what` — **Say It Again.** Ask the agent to say that again, in plain English.
3. `/share-oneshot-mini` — **Quick Implement.** Implement a small ticket in a single stroke.
4. `/share-teach` — **Learn.** Learn something about the codebase.
5. `/share-research` — **Research.** Research a question with citations to primary sources.
6. `/share-upstream` — **Merge.** Upstream changes from the branch your branch derives from (or another) into your branch.
7. `/share-pr` · `/share-pr-mini` · `/share-pr-mega` — **Pull Request.** Raise a PR to merge this code up, sized to the change.

---

### Meta

Give Devin superpowers.

1. /meta-create-skill - Create. Draft a new skill along with evals and metadata for all models.
2. /meta-extract-skill - Publish. Add a skill to the shared repository, abstracting away any specifics.
3. /meta-setup-intus-skills - Install. Setup a repository for use with Intus skills.
4. /meta-improve - Continuous Learning. Take what was learned in a session and use it to improve AGENTS.md.

---

## Safety

Guardrails you switch on before risky work.

1. `/eng-share-careful` — **Safety Guardrails.** Warns before destructive commands (`rm -rf`, `DROP TABLE`, force-push). Say "be careful" to activate. Any MEDIUM warning can be overridden; root/home recursive deletes and default-branch force-pushes are hard-denied.
2. `/eng-share-freeze` — **Edit Lock.** Restrict file edits to one directory. Prevents accidental changes outside scope while debugging.
3. `/eng-share-guard` — **Full Safety.** `/careful` + `/freeze` in one command. Maximum safety for production work.
4. `/eng-share-unfreeze` — **Unlock.** Remove the `/freeze` boundary.

---

## Engineering

### Main Flow

An engineer picks up the PRD and design that the designer handed off via `/ui-shipit`. They draft a technical design doc from the PRD with `/eng-create-tdd`, pressure-test it with `/eng-grill-tdd`, and run `/eng-check-tdd` to confirm every requirement in the PRD is covered. The next step is a review of the TDD with the team.

Once it is approved, they use `/eng-create-epic` to turn it into a Jira epic and tickets, then groom each ticket with `/eng-grill-jira`, deferring and recording any product questions. A ticket too big to hold in one session gets `/eng-grill-mega` → `/eng-to-spec` → `/eng-to-tickets` to cut it down to size.

To work a ticket they use `/eng-workon` to branch off `develop`, `/eng-create-feature` to scaffold it, `/eng-test-first` to generate a red suite from the acceptance criteria, and `/eng-implement` (or `/eng-implement-mega`) to turn it green — reaching for `/eng-debug` when a test fails for a reason they can't explain, and `/eng-handoff` when the session has run long enough that a fresh agent should pick it up. Along the way `/eng-ncommit` slices the work into atomic commits and `/eng-sync` keeps the branch current with GitHub.

When it's green, `/eng-shipit` opens the PR, `/eng-review` gives feedback on the branch, and `/eng-fix` iterates on the findings until they're clear. For a well-groomed ticket they collapse that whole stretch into `/eng-buildit` (or `/eng-buildit-mega`) followed by `/eng-shipit`, or go straight from ticket to PR with `/eng-oneshot` (or `/eng-oneshot-mega`).

Then a human reviews, approves, and merges, and the engineer asks `/eng-what-pr-next` what to pick up next.

### Skills

**Design**

1. `/eng-create-tdd` — **Draft TDD.** Create a technical design doc from a PRD.
2. `/eng-grill-tdd` — **TDD Interview.** Technical design doc interview.
3. `/eng-check-tdd` — **TDD Coverage.** Check that a TDD covers all requirements in its PRD.

**Plan**

1. `/eng-create-epic` — **Create Epic.** Create a Jira epic and tickets from a TDD.
2. `/eng-grill-jira` — **Ticket Interview.** Interview an engineer on a ticket. Defer and record non-engineering questions.
3. `/eng-grill-mega` → `/eng-to-spec` → `/eng-to-tickets` — **Break Down.** Interview an engineer on a massive ticket and cut it into smaller tickets.
4. `/eng-what-pr-next` — **Next Up.** What PR should I work on next?

**Build**

1. `/eng-workon` — **Branch.** Create a branch named after a ticket off `develop` (or another branch) and start work on it.
2. `/eng-create-feature` — **Scaffold.** Stub out the code for a feature.
3. `/eng-test-first` — **TDD.** Generate a red test suite based on the acceptance criteria of a ticket.
4. `/eng-implement` · `/eng-implement-mega` — **Build.** Implement a potentially very large ticket.
5. `/eng-debug` — **Investigate.** Systematic root-cause debugging.
6. `/eng-handoff` — **Start Fresh.** Write up a long session so another agent can continue it.

**Ship**

1. `/eng-ncommit` — **Git Commit.** Slice up the changes in your working directory into atomic commits.
2. `/eng-sync` — **Git Pull & Push.** Synchronize your branch with what's in GitHub.
3. `/eng-shipit` — **PR It.** Go from implementation to PR in one stroke.
4. `/eng-review` — **Code Review.** Get feedback on your branch.
5. `/eng-fix` — **Correct Review Findings.** Iteratively run a code review and fix findings automatically.

**Shortcuts**

1. `/eng-buildit` — **Build.** Go from ticket to implementation.
2. `/eng-buildit-mega` — **Mega Build.** Go from a massive ticket to implementation in a single stroke.
3. `/eng-oneshot` — **Ticket to PR.** Go from ticket to PR in a single stroke.
4. `/eng-oneshot-mega` — **Mega Ticket to PR.** Go from one massive ticket to a PR, using sub-agents to keep context under control.

---

## Product

### Main Flow

A product manager fills out a `/prod-draft-prd` and refines it via `/prod-grill-prd`. Next they build a prototype using `/prod-prototype`, which they can refine via the design skills below. They can run in-silico research using `/prod-ask-persona`.

After engineering has produced a TDD and tickets, product can refine the tickets and check them for completeness using `/prod-grill-jira`.

### Skills

1. `/prod-draft-prd` — **New PRD.** Create a draft Product Requirements Document.
2. `/prod-grill-prd` — **Interview.** Hone a PRD by iteratively questioning the PM about it.
3. `/prod-prototype` — **Mockup.** Build a prototype that answers questions in a PRD.
4. `/prod-ask-persona` — **Query Product Research.** Answer questions in a PRD by asking an AI persona drawing from product research.
5. `/prod-grill-jira` — **Sharpen a Ticket.** Answer questions from the AI about a Jira ticket.

---

## Design

### Main Flow

A designer refines a PRD using `/ui-grill-prd` and turns it into a prototype using `/ui-prototype`. They use `/ui-tweak` and `/ui-goal` to perfect it. They use `/ui-shotgun` to test variants and `/ui-review` & `/prod-ask-persona` to get feedback. The next step is a review of the design with the team.

Once it is approved, they use `/ui-feature` to build it pixel-perfect, working it with the skills above. Finally, they use `/ui-shipit` to hand off to engineering.

### Skills

1. `/ui-grill-prd` — **Refine a PRD.** Interviews the designer to identify further questions and align.
2. `/ui-prototype` — **Branch.** Set up a prototype branch based on a ticket for building on.
3. `/ui-tweak` — **Tweak.** Make a small UI change based on a ticket and ship a PR.
4. `/ui-goal` — **Verify.** Iteratively test in the browser that a change actually does what it should do.
5. `/ui-shotgun` — **Variants.** Generate 6 mockup variants of a design.
6. `/ui-feature` — **Feature.** Make a UI change based on a ticket, but let the designer iterate on it before shipping. Locked.
7. `/ui-review` — **Design Review.** Design-focused review of a UI.
8. `/ui-shipit` — **Handoff.** Prepare UI work for handoff to engineering.

---

## Review Axes

What `/eng-review`, `/eng-fix`, and `/share-pr` look at.

1. **Correctness** — Logic errors, off-by-ones, wrong conditions, unhandled null/undefined, race conditions, broken edge cases, behavior that doesn't match the ticket/intent.
2. **Security** — Injection, authz/authn gaps (e.g. missing tenant/org scoping in multi-tenant code), secrets in code/logs, unsafe deserialization, PHI/PII exposure.
3. **Data integrity & migrations** — Schema changes without migrations, non-idempotent or irreversible migrations, breaking changes to shared types/contracts (Zod/tRPC), backfill gaps.
4. **DRY** — Logic, constants, or types duplicated instead of reusing an existing utility, component, or shared definition.
5. **Error handling & resilience** — Swallowed errors, missing retries/timeouts on external calls (EHR APIs, Service Bus), partial-failure states, poor failure messages.
6. **Performance** — N+1 queries, missing indexes, unbounded queries/loops, unnecessary re-renders, large payloads, blocking work on hot paths. Baseline page load times, Core Web Vitals, and resource sizes; compare before/after on every PR.
7. **Concurrency / async** — Unawaited promises, shared mutable state, ordering assumptions, AsyncLocalStorage context leaks.
8. **API / contract design** — Backward compatibility, naming, over-broad inputs, leaking internals, inconsistent return shapes.
9. **Tests** — Missing coverage for new branches/edge cases, tests that assert implementation rather than behavior, flaky patterns, tests modified just to pass.
10. **Maintainability** — Duplication, dead code, overly clever code, misleading names, violated existing conventions/utilities, oversized functions/files.
11. **Scope & diff hygiene** — Unrelated changes, leftover debug/console logs, commented-out code, generated files edited by hand, dependency additions (version pinning, recency, necessity).
12. **Observability** — Missing/noisy logging, audit context not propagated, feature flags without a cleanup path.
13. **Telemetry** — Metrics, traces, and analytics events for new behavior; dashboards and alerts that will surface a regression after deploy.
14. **Docs / comments** — Stale comments, comments that describe the diff rather than the code, missing notes for non-obvious decisions.
15. **Platform** — Is this ready to be deployed? 12-factor compliance, identity and access, system design and hosting fit, data and integration, quality, delivery, and infrastructure.
16. **Architecture** — Seams, dependency cycles, interfaces, layout, naming.
