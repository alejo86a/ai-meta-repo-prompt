---
description: "Complete a task — run the DoD checklist, move issue to review, and prepare for PR"
tools: ['execute', 'read']
---

# Complete Task

Run the Definition of Done checklist, update the issue tracker to `status: review`, and prepare for PR creation.

> **Adapter note (read first):** the placeholders below are wrapped in `<<...>>`. Replace each one with the value that fits the receiving project before this skill is usable.
>
> | Placeholder | What it represents | Example |
> |---|---|---|
> | `<<TASK_PREFIX>>` | Bracket prefix used in branches/issues | `TASK`, `JIRA`, `TICKET` |
> | `<<ISSUE_TRACKER>>` | Tracker integration | `gh`, `jira`, `linear`, `none` |
> | `<<STATUS_IN_PROGRESS>>` | Label/status meaning "actively working" | `status: in-progress` |
> | `<<STATUS_REVIEW>>` | Label/status meaning "awaiting review" | `status: review` |
> | `<<ARCH_INVARIANT>>` | One sentence describing the project's architectural rule that must hold | e.g. "service A never accesses DB directly — must go through the API gateway" |
> | `<<TEST_CMD>>` | Test command | `npm test`, `pytest`, `go test ./...` |
> | `<<LINT_CMD>>` | Lint/typecheck command | `npm run lint`, `tsc --noEmit`, `ruff check` |
> | `<<DOCS_FILE>>` | Project context file the agent must update on pattern changes | `CLAUDE.md`, `README.md`, `docs/architecture.md` |

## Input

- **issue-number** (OPTIONAL): Issue tracker number. Leave blank to detect from current branch.

${input:issue-number:Issue number — leave blank to auto-detect from branch name}

## Instructions

### 1. Verify prerequisites (if `<<ISSUE_TRACKER>>` is `gh`)

```bash
which gh
```

If not found → install (e.g. `brew install gh`). Authenticate:
```bash
gh auth status
```
If not authenticated → `gh auth login`, then re-run.

### 2. Detect active issue

If `issue-number` was NOT provided:

```bash
git branch --show-current
```

Extract the issue/task number from the branch name pattern `feature/task-XXX-...`.

If `<<ISSUE_TRACKER>>` is `gh`, search GitHub for the matching issue:
```bash
gh issue list --label "<<STATUS_IN_PROGRESS>>" --json number,title \
  | jq '.[] | select(.title | test("<<TASK_PREFIX>>-XXX"))'
```

Confirm with the user which issue they are completing.

### 3. Load issue details

```bash
gh issue view <number> --json number,title,body,labels
```

Display title and acceptance criteria so the user can review them while completing the checklist.

### 4. Run the Definition of Done checklist

Present each item and ask `y` / `n`:

```
📋 Definition of Done — #<number>: <title>
────────────────────────────────────────────

Architecture & Code
  [ ] Scope implemented per acceptance criteria in the issue
  [ ] Architecture invariant holds: <<ARCH_INVARIANT>>
  [ ] No hardcoded secrets or .env values in committed code

Quality
  [ ] Tests written and passing for the changed scope
  [ ] Lint/build/format checks passing (<<LINT_CMD>> / <<TEST_CMD>>)
  [ ] Quality Loop completed: implement → review → fix → re-validate (≥2 passes)

Documentation
  [ ] Relevant .md files updated (if applicable)
  [ ] <<DOCS_FILE>> updated if new patterns emerged
  [ ] API contracts updated (if new/changed endpoints)

Readiness
  [ ] All changes committed to feature branch
  [ ] No merge conflicts with default branch (run: git fetch origin && git diff origin/<default-branch>)
```

If any item is `n`, list what's pending and ask:
> "There are N incomplete items. Continue to review anyway, or keep working? (review / keep)"

Only proceed if the user chooses `review`.

### 5. Update issue to review

If `<<ISSUE_TRACKER>>` is `gh`:

```bash
gh issue edit <number> \
  --remove-label "<<STATUS_IN_PROGRESS>>" \
  --add-label "<<STATUS_REVIEW>>"
```

For other trackers, invoke their equivalent CLI / API.

### 6. Remind about PR

```
✅ Issue #<number> → <<STATUS_REVIEW>>

Next step: create a Pull Request.
Run /commit-and-push to stage, commit, push, and open the PR.

The PR body MUST include:
  Closes #<number>

This will automatically close the issue when the PR is merged.
```

## Guardrails

- Never move an issue directly to `done` — only `<<STATUS_REVIEW>>`; the PR merge closes it
- Never skip the DoD checklist even if the user asks to
- If the tracker CLI fails, tell the user how to authenticate
