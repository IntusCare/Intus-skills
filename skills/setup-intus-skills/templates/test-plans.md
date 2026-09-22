<!-- SEED: strip every SEED comment. Source this from the repo's existing plan comments, not from
     taste — read three real ones before writing. If the repo has no test-plan convention, do not
     write this file; skip it and say so. -->
# Ticket Test Plans

> **TL;DR** — A test plan is `<where it lives>`. `<the one rule that keeps it usable>`.

## Context

`grill-jira` ships in the shared `intus-skills` plugin and knows only that a ticket needs a test plan.
This file says what one looks like in `<repo>`, and who reads it.

## Placement and lifecycle

<!-- SEED: the audience decides the placement. Name who reads it and where they read it. -->

- **Lives in**: `<a Jira comment / the ticket description / a file under ...>`.
- **Starts with**: `<a title line that makes it findable among other comments>`.
- **One artifact = the whole current plan.** When the change shifts, edit the existing plan in place
  and mark it `<updated marker>`. Never post an addendum that renumbers or extends earlier steps —
  the reader then has to reconcile two lists before they can test.
- **Updating the plan is part of the change.** A change that invalidates steps revises them in the
  same pass.

## Structure

<!-- SEED: keep the numbered shape; replace the line format and the examples with this repo's. -->

1. **Setup once, up top.** Preconditions — environment, flags, test data — in a short block before
   the scenarios, never repeated inside them.
2. **Flat scenario lines**, each independently executable, grouped by a context prefix:

   `<the repo's line format>`

   - Example: `<a real line from a real ticket>`
3. **One expected result per line.** A secondary assertion is its own line. Three inputs with the
   same outcome are three lines — never "repeat with X and Y".
4. **Explanation at the bottom.** Rationale and context in a short section *after* the scenarios,
   never as sub-bullets inside one.

<!-- SEED: keep this only if the repo has a verifiability standard for a scenario line. -->
**Evidence test:** write each line so it could be verified with `<one screenshot / one command>`. If
a line can't produce one distinct observable outcome, it's malformed — split it, or merge it with
the line that shows the same thing.

## Authorship

- Plans written by `grill-jira` end with a sentinel line so a later run can find its own work:
  `<sentinel>`.
- A plan **without** that sentinel was written by a human. It is not the skill's to replace.
