---
description: "Start a task — show available tasks, validate WIP limit, create branch, and move issue to in-progress"
tools: ['execute', 'read']
---

# Start Task

Pick a task from the issue tracker, validate it's ready to start, create the feature branch, and update the issue status to `in-progress`.

> **Adapter note (read first):** the placeholders below are wrapped in `<<...>>`. Replace each one with values that fit the receiving project before this skill is usable.
>
> | Placeholder | What it represents | Example |
> |---|---|---|
> | `<<TASK_PREFIX>>` | Task ID prefix in titles | `TASK`, `JIRA`, `TICKET` |
> | `<<ISSUE_TRACKER>>` | Tracker integration | `gh`, `jira`, `linear` |
> | `<<STATUS_BACKLOG>>` | Label/state meaning "ready to be picked up" | `status: backlog` |
> | `<<STATUS_SPECIFIED>>` | Label/state meaning "specs written, ready to start" (or remove if unused) | `status: specified` |
> | `<<STATUS_IN_PROGRESS>>` | Label/state meaning "actively working" | `status: in-progress` |
> | `<<DEFAULT_BRANCH>>` | Repo default branch | `main`, `master` |
> | `<<WIP_LIMIT>>` | Max simultaneous in-progress tasks | `3` |
> | `<<DOCS_FILE>>` | Project context file the agent should read | `CLAUDE.md`, `docs/architecture.md` |
> | `<<PHASE_HINTS>>` | Optional table mapping phase labels → reading list & recommended agent | (see step 10) |

## Input

- **issue-number** (OPTIONAL): Issue tracker number to start directly. Leave blank to browse available tasks.

${input:issue-number:Issue number — leave blank to browse all available tasks}

## Instructions

### 1. Verify prerequisites

#### Tracker CLI (if `<<ISSUE_TRACKER>>` is `gh`)

```bash
which gh
```

If not found:
```bash
brew install gh
```

If Homebrew is not installed either:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install gh
```

After installing, check authentication:
```bash
gh auth status
```

If not authenticated:
```bash
gh auth login
```
Follow the prompts, then re-run.

### 2. Fetch available tasks (skip if issue-number was provided)

```bash
gh issue list --label "<<STATUS_BACKLOG>>"   --json number,title,labels,assignees --limit 50
gh issue list --label "<<STATUS_SPECIFIED>>" --json number,title,labels,assignees --limit 50
```

Display grouped by priority (parse the `priority: P0` / `priority: P1` labels):

```
🔴 P0 — Critical Path
  #8   <<TASK_PREFIX>>-001  Short title         [phase: 1-infra]
  #19  <<TASK_PREFIX>>-014  Another title       [phase: 4-app]    ★ SPECIFIED

🟡 P1
  #14  <<TASK_PREFIX>>-007  Yet another         [phase: 3-svc]
```

Ask: **"Which issue number do you want to work on?"**

### 3. Load task details

```bash
gh issue view <number> --json number,title,body,labels,assignees
```

Display full task details (title, description, acceptance criteria from body).

### 4. Validate WIP limit

```bash
gh issue list --label "<<STATUS_IN_PROGRESS>>" --json number,title,assignees
```

If **`<<WIP_LIMIT>>` or more** tasks are in progress, warn:
> "⚠️ WIP limit: X tasks already in progress. Starting another may hurt flow. Continue? (y/n)"

### 5. Check for blockers

Scan the issue body for `Depends on`, `blocked by`, or `Dependencies:` patterns.
If found, display them and ask:
> "⚠️ This task mentions dependencies. Are they completed? (y/n)"

### 6. Assign the task

```bash
gh api user --jq '.login'
```

Ask: **"Who is working on this? (default: your username)"**

### 7. Note any known blockers upfront

Ask: **"Any blockers to note before starting? (Enter to skip)"**

If provided:
```bash
gh issue comment <number> --body "🚧 Blocker noted at start: <text>"
```

### 8. Mark issue as in-progress immediately

Do this **before** creating the branch so the team sees the task is taken as soon as you commit to it.

```bash
gh issue edit <number> \
  --remove-label "<<STATUS_BACKLOG>>" \
  --remove-label "<<STATUS_SPECIFIED>>" \
  --add-label "<<STATUS_IN_PROGRESS>>" \
  --add-assignee <username>
```

Confirm the update printed without error before continuing.

### 9. Create feature branch

Extract the task ID from the issue title (e.g. `[<<TASK_PREFIX>>-014]` → `task-014`).
Build branch name: `feature/task-<id>-<first-4-words-kebab-case>`.

```bash
git status
```

If `<<DEFAULT_BRANCH>>` has uncommitted changes, stop and ask the user to resolve them first.

```bash
git checkout <<DEFAULT_BRANCH>>
git pull origin <<DEFAULT_BRANCH>>
git checkout -b feature/task-XXX-short-description
```

### 10. Print context summary

Print a per-phase reading list and the recommended implementation/QA agent. Replace the table below with `<<PHASE_HINTS>>` for the receiving project. Example template:

```
✅ Issue #19 → <<STATUS_IN_PROGRESS>> (assigned to <username>)
✅ Branch created: feature/task-014-short-description

📚 Read before starting:
  phase: 1-infra      → docker-compose.yml, .github/workflows/
  phase: 2-database   → docs/architecture/database-schema.md
  phase: 3-svc        → projects/<service>/src/, <<DOCS_FILE>>
  phase: 4-app        → projects/<app>/, docs/architecture/

💡 Architecture reminder:
  <one-sentence project invariant the agent must respect>

🤖 Agents for this task:
  phase: 3-svc        → implementation: <agent>   |  QA: <agent>
  phase: 4-app        → implementation: <agent>   |  QA: <agent>
  phase: 1-infra      → implementation: <agent>   |  QA: <agent>

🔗 Issue: <issue URL>
```

---

⛔ **DO NOT write any code yet.** Proceed to step 11.

---

### 11. Planning — Socratic analysis BEFORE implementation

**This step is mandatory. No code until it is complete.**

Read the following in parallel:
- The full issue body (AC, type, dependencies)
- `<<DOCS_FILE>>` — project goals, standards, DoD
- The architecture / system overview document
- Phase-specific rules file (if any)
- `git log --oneline -10` — what has already been done
- Open issues in the same phase — what pending tasks depend on this one

Then use **Socratic method** to surface what the task description does NOT say but the project clearly needs:

| Question | Why it matters |
|---|---|
| What does the task explicitly ask for? | Baseline scope |
| What does the project architecture require that the AC doesn't mention? | e.g. Dockerfile, compose entry, env vars |
| What patterns do completed tasks establish that must be followed here? | e.g. file structure, naming, logging |
| What will the next pending tasks depend on from this output? | Avoid creating blockers downstream |
| What can break at QA if I don't address it now? | e.g. missing tests, wrong module resolution, console.log in stdio |
| What decisions require user input before I start coding? | Surface ambiguity early |

**Enter Plan Mode** and produce a written plan with:
1. **Scope** — what is in and out
2. **Gap analysis** — things the AC doesn't mention but are required
3. **File list** — every file to create or modify, with one-line description
4. **Implementation order** — sequence with dependencies called out
5. **Open questions** — anything needing user input before starting

Present the plan to the user. **Wait for explicit approval before proceeding to step 12.**

### 12. Implementation — use the recommended agent

Only after the plan is approved in step 11, delegate implementation to the agent listed in step 10 for this phase.

Pass the approved plan to the agent as context so it does not re-derive scope from scratch.

### 13. Mandatory QA

**Do not skip. Do not run /complete-task until this passes.**

Invoke the project's QA agent (or run the checks manually) with this brief:

> "Validate <<TASK_PREFIX>>-XXX on branch `feature/task-XXX-...`. Run: build, typecheck, tests. For phases that ship a container also: build the Docker image, run a smoke test, and verify `docker compose build <service>` exits 0. Report pass/fail per check. Fix any failure before signing off."

The QA step must confirm **all of the following** before this skill is done:

| Check | Required for |
|---|---|
| `<test command>` exits 0 | all phases |
| `<typecheck command>` — zero errors | all phases |
| Tests pass | all phases |
| Docker image builds | phases that ship a container |
| Container smoke test responds correctly | phases that ship a container |
| `docker compose build <service>` exits 0 | phases that ship a container |

If any check fails, fix it and re-run. Only after a clean run proceed to `/complete-task`.

## Guardrails

- Never commit or branch off `<<DEFAULT_BRANCH>>` with uncommitted changes
- Never skip the WIP limit check
- Never create a branch without pulling latest `<<DEFAULT_BRANCH>>` first
- Always update issue status through the tracker CLI — never edit a static board file
- Use `--add-assignee` not `--assignee` when calling `gh issue edit`
