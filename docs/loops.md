# Loops, for humans

`LOOPS.md` decides when work runs. This file explains that file
so a person can teach it, argue with it, or sit down at the desk
and know which turn they are in.

If this page and `LOOPS.md` disagree, believe `LOOPS.md`.

Skills teach how. Loops decide when.
If it isn't in the files, it isn't so.

## Skill vs loop

A skill is a procedure an agent loads. It lives at
`.agents/skills/<name>/SKILL.md`. The YAML `description` is the
hook the agent reads to decide whether to load it.

A loop is the condition under which that procedure is allowed to
run, and the stop that ends the turn. The agent does not pick a
loop because it feels productive. The human's place in the day,
plus what the files already contain, picks it.

Eight loops. `L0` through `L7`. The short table:

| Loop | When | Stop |
| --- | --- | --- |
| Examine | Always | Cited or withdrawn |
| The Day | Outer | Commit. Tomorrow starts from disk |
| Specify | Mid-day | `spec.md` exists, stack is not in it |
| Plan / tasks | Spec stable | A named task can be picked |
| Implement | Afternoon, named `slug#T0xx` | One checkbox, or a cited blocker |
| Converge | Feature close | Converged, or tasks appended. Never deleted |
| Curate | Not the work turn | Proposal only. Human merges |
| Index | After writes, before morning | Derived files match the writings |

`boot-dash` and `ocaml-code-writer` are skills. They are not loops.
One boots the Reading. The other is how OCaml gets written during
`L4`. Neither decides when work happens.

## How they sit on the day

`AGENTS.md` already has the day. `L1` is that day, named as a loop
so the other seven have somewhere to hang.

```
L1 The Day (human-owned)
|
|- morning      L7 if stale, then L0, then read-status
|- mid-day      L0, then L2 Specify
|               L3 Plan / tasks once the spec is stable
|- afternoon    L0, then L4 one named task, then L7
|- feature end  L0, then L5 Converge
|               gaps send you back to L4
|- not work     L6 Curate
```

`L0` runs on every turn. `L7` runs after a write, and before
morning if the view is stale. Owner of `L1` is the human.
Heartbeat is morning, and any "what should we work on?"

Tomorrow starts from disk because disk is the only place a claim
can be examined.

## Spec-kit

Berea sits on [GitHub Spec Kit](https://github.com/github/spec-kit).
It does not wrap spec-kit in a second process. The writings are
the spec-kit files. The loops say when those files may be written.

Spec-kit's chain:

```
constitution -> specify -> clarify -> plan -> checklist
             -> tasks -> analyze -> implement -> converge
```

Berea's mapping:

| Spec-kit | Berea | What lands on disk |
| --- | --- | --- |
| constitution | house file, not a loop | `.specify/memory/constitution.md` |
| specify + clarify | `L2` | `specs/NNN-slug/spec.md` |
| plan + tasks + analyze | `L3` | `plan.md`, then `tasks.md` |
| implement | `L4` | code, and one checkbox |
| converge | `L5` | gaps appended, or a cited "converged" |

Clarify is not its own loop. `specify-writing` already caps it:
at most five questions that change the writing, encoded back into
`spec.md`. No side list in chat.

Analyze is not its own loop. `L3` says analyze must be clean
enough to pick a named task. If it is not, you are still in plan
and tasks.

Checklist is not named as a Berea loop. The constitution check
lives in the plan. That is the gate this house kept.

The `specify` CLI, if present, may write the files. The files
still win if it is not. A loop does not depend on the binary
being installed.

## L0 Examine

Always. Skill: `examine`. Every other skill assumes this one
already ran.

**When.** Any turn that is about to claim a fact. Status, a
decision, what a spec says, what a task says, whether memory is
canon. Before generated context is treated as true.

**Who.** Action or Curator. Both examine. The role split does not
excuse either mouth from pointing at a file.

**Reads, in order.**

1. `.dash/context/summary.md` if the question is status or "what next"
2. `specs/INDEX.md` or the named `NNN-slug`
3. The feature file that holds the claim
4. Constitution only for gates and "why we don't"
5. Reviewed memory only for facts that are not already a spec artifact

Do not slurp the tree. Cap what you load. Cite `001-reading-surface` or
`001-reading-surface#T012`.

**Writes.** Nothing. Examine is a read. If the summary looks
stale, the next move is `L7`, not an edit of `summary.md`.

**Refuses.** Conversation as evidence. Model confidence as
evidence. A slug that is not a directory under `specs/`. A status
column the writings do not have. Copying constitution or spec
bodies into memory.

**Stop.** Cited or withdrawn. The writing and the summary
disagree: believe the writing, then rebuild.

The house tagline lives here for a reason. An agent that answers
from the last chat turn has already left Berea.

## L1 The Day

Outer cadence. No skill of its own. The human owns it.

```
Morning    read-status from .dash/context/summary.md
Mid-day    specify-writing -> specs/NNN-slug/spec.md
Afternoon  implement-task -> one checkbox -> rebuild-context
End of day commit. Tomorrow starts from disk.
```

**When.** The shape of a working day. Also any moment someone
asks "what should we work on?" That question is morning, even at
11pm.

**Who.** The human. The agent proposes a next action taken from
the files. It does not invent a new day, a sprint, or a board
that survives the commit.

Morning is `read-status`. It reads a generated summary. It does
not walk every `spec.md` to invent a ranking. If the summary is
missing or `/health` says stale, run `L7` first, then examine,
then answer.

Mid-day is `L2`. Afternoon is `L4`. End of day is a commit, not
a standup note the agent will "remember tomorrow."

**Writes.** Whatever the inner loop of the moment writes. `L1`
itself writes nothing.

**Stop.** The commit landed. Tomorrow starts from disk.

A day that never commits is a chat log. Berea does not run on
chat logs.

## L2 Specify

Mid-day. Skill: `specify-writing`.

A conversation that does not land in a file did not happen.

**When.** The human is shaping a feature. They say specify, or
write the spec, or the talk has not yet landed. Not when they
named a `T0xx`. That is afternoon.

**Who.** Action, in view of the human. The human has to read the
spec before anyone pretends it is blessed.

**Writes.** `specs/NNN-slug/spec.md` only. If the feature already
has a directory, amend that file. If not, take the next `NNN`
from existing directories and a short slug from the human's
words. Do not reuse a number.

Optional frontmatter on `spec.md` only:

```yaml
---
horizon: now | next | later
priority: critical | high | medium | low
---
```

Horizon is not an Epic type. If it is absent, infer: in-progress
is now, specified-but-unplanned is next. That rule is Article VIII
of the constitution.

**Belongs in spec.md.** What and why. User-visible behavior.
Acceptance that can be checked later. Open questions, listed.
Non-goals.

**Does not belong.** Tech stack, libraries, folder layout. That
is `plan.md`. A task checklist. That is `tasks.md`. Copies of
constitution text. Point at it.

**Clarify.** At most five questions that change the writing.
Encode the answers back into `spec.md`. Do not keep a side list
in chat. That is spec-kit clarify, folded into this loop so it
cannot become its own ceremony.

**After.** Rebuild the index. Do not flip tasks. There are none
yet.

**Stop.** `spec.md` exists, and the stack is not in it.
Constitution would reject the feature: write that gate down and
stop. The human is talking implementation: switch to plan. Do
not smuggle how into what.

The usual miss is putting Bun in the spec because the human
mentioned Bun. Stack goes in the plan. The spec should still
make sense if the plan later picks something else.

## L3 Plan and tasks

Spec stable. No dedicated skill.

This is deliberate. Spec-kit already knows how to write `plan.md`
and `tasks.md`. Berea only says when they are allowed, and what
"done enough" means.

**When.** After `L2`, once the spec is stable enough that how
can be written without rewriting what. Not during implement.
Not as a way to sneak extra work onto a feature that already
has tasks.

**Who.** Action. Constitution check lives in the plan. If the
gate fails, the feature derives as blocked. That is Article IV,
not a status the agent stores somewhere else.

**Writes.** `plan.md` first, then dependency-ordered `tasks.md`.
Use the `specify` CLI if present. The files still win if it is
not.

**Analyze.** Read-only across spec, plan, and tasks. Conflicts,
gaps, a task with no matching requirement. If that report is
dirty, you are still in `L3`. You do not start `T014` to "get
momentum."

**Stop.** A named task can be picked. Prerequisites are visible.
The constitution check in the plan is either clean or explicitly
failing, not shrugged off.

There is no `plan-writing` skill on the skills list. If that
starts to hurt, the fix is a skill, not a second planning doc
under `docs/plans/`. That path already failed once in this repo.
The draft had to be promoted into `specs/` because nothing
reconciled it.

## L4 Implement

Afternoon. Skill: `implement-task`.

One named task. One checkbox. No extras.

**When.** The human names `NNN-slug#T0xx`, or a `T0xx` that
resolves to one spec, or says implement that task. Unnamed work
is refused.

**Who.** Action. Curator does not implement, and does not flip
the box.

**Reads, in order.**

1. That feature's `spec.md`
2. `plan.md` if present
3. The task line and any unchecked prerequisites in `tasks.md`

If a prerequisite is open, stop. Cite it. Do not "also do T011."

**Isolation.** Worktree or a clean branch for this task. Do not
share a dirty tree with another in-flight task.

**Does the work.** Only what the task names. Match the plan's
stack when a plan exists. Match existing code shape. Do not
refactor neighbors. Run the deterministic checks the repo
already has. Prefer those over an LLM verdict.

For `tools/status-dash`, that is `bun run build` then
`bun run check`. Commit the regenerated `_generated/` JS with
the change. Degraded mode runs it.

OCaml or Melange in the diff loads `ocaml-code-writer`. That is
how, not when.

**Closes the task.**

1. Flip only that task's checkbox in `tasks.md`. Preserve the
   rest of the document. Do not explode tasks into one file each.
2. Rebuild context. Never hand-edit `.dash/context/`.
3. Allowed extra write: append `memory/sessions/`.
4. Open a PR if the human wants one. Cite the ref in the message.

**Refuses.** Constitution edits. Reviewed memory. `AGENTS.md`
beyond a link. Generated context. A second checkbox because it
was small. Checking the box before the check ran.

**Stop.** That one box flips, or you cite a blocker: open
prerequisite, spec has to move first, three failures with no
new file evidence. Retrying the same compile error is not a new
round. Delete, publish, production, rewrite of house files:
human.

Starting implement on a spec that has no `tasks.md` is the
agent skipping `L3`. Don't.

## L5 Converge

Feature close. Skill: `converge-writings`.

This is spec-kit converge. Append-only. Never edit code to hide
a gap. Never delete a task to make the feature look done.

**When.** Closing a feature. After a stretch of `L4`. When the
human says converge, did we miss anything, or is this feature
done.

**Who.** Action, reading. The only write this loop is allowed
is appending tasks.

**Reads.** The feature the human named. If none, the in-flight
spec from `.dash/context/active.md`. If several are in flight,
ask which. Then `spec.md`, `plan.md` if present, `tasks.md`,
and the parts of the tree the plan said would exist.

The `specify` CLI may run `/speckit.converge`. Still write the
result in the files.

**Verdicts.**

Converged. Every acceptance in the spec has a cited place in the
tree or in a checked task. Open questions in the spec are either
answered in the writing or explicitly deferred. Say so with
citations.

Gaps. List each gap as a citation: which sentence in spec or
plan has no task and no code. Append new tasks under a
`Convergence` heading in that feature's `tasks.md`. Do not
reorder or rewrite existing tasks except to add that heading
and the new lines.

Then stop. Implement is a different loop. The new lines go back
to `L4`.

**Feature status is derived.** Article IV:

- no `plan.md` -> specified
- `plan.md`, tasks open -> planned / in progress
- all tasks checked and converge clean -> done
- constitution check failing -> blocked

Do not store that status in SQLite as source.

**Stop.** Converged, or tasks appended. Cannot name the feature:
do not converge the whole repo. Tempted to "just fix it" in
code: that is `L4`. Tempted to mark a vague task done so the
list is green: leave it.

Declaring done because the agent is tired is the failure this
loop exists to catch.

## L6 Curate

Not the work turn. Skill: `curate-memory`. Role: Curator.

Reviewed memory is canon. Sessions are proposals. The human
merges.

**When.** After a session. When the human says remember this,
capture the regression, or this belongs in the writings. Not
during an `L4` turn. Action on a work turn may only append
`memory/sessions/`.

**Who.** Curator proposes. Human merges. Action does not promote
a session note into `decisions/`, `regressions/`, or
`conventions/`.

**Input.** Transcript plus diff. **Output.** A proposed patch.

**Classify each fact.**

| Kind | Destination | When |
| --- | --- | --- |
| Already in constitution or a spec | discard | point at the writing |
| Changes what or why of a feature | patch `specs/<slug>/spec.md` | it is about what we are building |
| House principle | patch `.specify/memory/constitution.md` | it gates future work |
| How we write files or code | `memory/conventions/` | how we work, not a feature |
| A failure we must not repeat | `memory/regressions/` | it recurred or cost a session |
| A choice no writing records | `memory/decisions/` | neither constitution nor spec holds it |
| Noise | discard | chatter, duplicates |

Anything bound for `memory/` lands first as a proposal under
`memory/sessions/`. The human promotes it. Frontmatter stays
`status: proposal` until that merge. Commits that land memory
start with `memory:`.

**Refuses.** Flipping a checkbox. Editing `tasks.md`. Editing
reviewed memory directly. Editing constitution or `spec.md`
from this skill. Copying constitution or spec bodies into
memory. Silently committing. Personal preferences. Those stay
in a vault, not this repo.

**Stop.** Proposal only. The same fact already lives in a
writing: point at it, discard the note. Unsure which kind:
propose and say so. Do not guess canon.

Checking `T012` because the session "finished it" is the
classic mix-up. Different loop. Different role.

## L7 Index

Derived. Skill: `rebuild-context`.

Derived files are a view. Rebuild them. Do not author them.

**When.** After a write that changes what morning will say: a
new spec, a flipped checkbox, a converge that appended tasks.
Before morning if `.dash/context/summary.md` is missing or
`/health` reports stale context.

**Who.** Action. Rebuilding the index is on the allowed list.
Hand-editing `.dash/context/` is not.

**Writes, by generator only.**

```
.dash/context/summary.md     ~1000 tokens. Morning target.
.dash/context/active.md
.dash/context/blocked.md
.dash/context/metrics.md
specs/INDEX.md               router across features
.dash/dash.sqlite            FTS overlay, gitignored
```

From `tools/status-dash`:

```
bun run index
```

or `POST /api/sync` if the dash is up. `/api/index` is the same
handler.

If `_generated/` is missing, the dash is unbuilt. Say that.
Point at `boot-dash`. Do not invent a parallel generator.

**After.** Confirm `summary.md` numbers match `specs/`
directories and the checkboxes you can see. If they disagree,
the generator is wrong. Do not "fix" the markdown by hand. Fix
the generator under `tools/status-dash/src/`, and `bun run check`
before believing it.

**Stop.** Derived files match the writings. Migration or sqlite
failure: fail visible. Do not answer status from a half-written
summary.

Skipping rebuild after a checkbox flip, then answering morning
from yesterday, is how a done feature keeps showing up as work.

## Roles

Two mouths. Same repo.

Action may read writings, append `memory/sessions/`, flip a
checkbox in `tasks.md`, rebuild the index, open a PR.

Action may not edit reviewed memory, rewrite `AGENTS.md` or
`CLAUDE.md` beyond a link, hand-edit generated context, or
silently commit memory.

Curator proposes. Human merges.

The split exists so an implement turn cannot launder a decision
into canon, and a memory turn cannot close a task.

## Stop rules that apply everywhere

From `LOOPS.md`. Not flavor.

- Cannot cite it -> do not claim it
- Prerequisites open -> do not start
- Same failure three times, no new file evidence -> stop
- Irreversible effect -> human
- Derived drift -> rebuild, do not edit

"Three failures" means the tree did not change in a way that
explains the miss. "Prerequisites open" means `L4` does not
start `T014` while `T012` is unchecked. "Irreversible" is
delete, publish, production, or a rewrite of house files.

## No second backlog

Article I: constitution, `spec.md`, `plan.md`, and `tasks.md`
are the source of intent and backlog. There is no second board.
SQLite is an overlay. Pins, chat, FTS, snapshots. It is never
a copy of the writings.

Task status is the checkbox in `tasks.md`. Cite work as
`003-auth#T012`. Do not explode tasks into one file each. Do
not invent `TASK-xxxxx` or `EPIC-xxxxx` files.

Horizon is optional frontmatter on `spec.md`. It is not a new
entity type and not a column on a board.

The Reading can draw a backlog visual from the same files.
Inventing a board so the agent has somewhere to park work is
the thing these loops exist to prevent.

This page is an explainer. It is not a plan, not a task list,
and not a third place to record what we are building. Those
belong under `specs/`.
