---
description: "Analyze changes, generate commit message, push to feature branch, and open a PR"
tools: ['read', 'execute', 'todo']
---

# Commit and Push Changes

Analyze workspace changes, generate a commit message following the project format, push to a feature branch, and open a Pull Request that passes all CI validations.

> **Adapter note (read first):** the placeholders below are wrapped in `<<...>>`. Replace each one with the value that fits the receiving project before this skill is usable.
>
> | Placeholder | What it represents | Example |
> |---|---|---|
> | `<<TASK_PREFIX>>` | The bracket prefix CI enforces in commits / PR titles | `TASK`, `JIRA`, `TICKET` |
> | `<<TASK_REGEX>>` | Regex CI validates against | `^\[TASK-[0-9]+\]` |
> | `<<DEFAULT_BRANCH>>` | The repository default branch | `main`, `master`, `trunk` |
> | `<<PROJECT_PATHS>>` | Top-level dirs the diff might touch (mono-repo); single repo: just `.` | `apps/api/`, `packages/web/` |
> | `<<CI_WORKFLOW_PATH>>` | Path to the CI workflow that enforces title/body | `.github/workflows/pr-checks.yml` |
> | `<<COAUTHOR_LINE>>` | Co-author trailer the project uses (or omit if not used) | `Co-Authored-By: Claude <noreply@anthropic.com>` |
> | `<<ISSUE_TRACKER>>` | Tracker integration in use | `gh` (GitHub Issues), `jira`, `linear`, `none` |

## Input

- **branch-name** (OPTIONAL): Override the branch to use. Leave blank — the skill will infer everything from the diff and current branch state.

${input:branch-name:Feature branch name — leave blank to auto-detect}

## Pre-Commit Validation

Ensure all tests pass before continuing:
```bash
# Replace with the receiving project's test command
npm test
```

If any tests fail, **STOP** and fix issues before committing.

## Instructions

### 1. Read the Diff First

Before making any branch or message decisions, read what actually changed:

```bash
git status
git diff
git diff --cached
```

From the diff, extract:
- **Which files changed** and in which subproject (`<<PROJECT_PATHS>>`)
- **What the changes do** — new features, bug fixes, docs, tests
- **Any task/ticket references** in file contents, comments, or paths (e.g. `<<TASK_PREFIX>>-014`, `[<<TASK_PREFIX>>-014]`)

### 2. Infer the Task and Detect Context Switches

**Step 2a — Gather signals**:

| Signal | How to read it |
|---|---|
| Task ID in diff content | References inside changed files (comments, route names, test descriptions, variable names) |
| Current branch name | `feature/task-014-something` → `<<TASK_PREFIX>>-014` |
| Recent commits on branch | `git log --oneline -5` — look for `[<<TASK_PREFIX>>-XXX]` patterns |
| `branch-name` input | Parse task ID from it if provided |

**Step 2b — Cross-check for context switch**:

After collecting signals, compare the **task implied by the diff content** against the **task implied by the branch/commits**:

- **They agree** (or only one signal exists) → proceed with that task ID, no question needed.
- **They disagree** → the user may have switched tasks without creating a new branch. Ask:
  > "The changes look like **<<TASK_PREFIX>>-XXX** (based on the files modified) but the current branch is `feature/task-YYY-...`. Are we still working on <<TASK_PREFIX>>-YYY, or did we switch?"
- **No signal at all** → ask:
  > "Which task are you working on? (e.g. <<TASK_PREFIX>>-014)"

Do NOT guess or invent a task ID.

**Step 2c — Validate Task ID format**:

The CI regex is `<<TASK_REGEX>>` — labels like `[FIX]`, `[DOCS]`, `[CHORE]` will fail CI if they don't match it.

If the inferred task ID does NOT match the regex:
1. (If `<<ISSUE_TRACKER>>` is GitHub) Check if an issue already exists:
   ```bash
   gh issue list --search "<keywords from diff>" --state all --json number,title --limit 5
   ```
2. If no issue exists, create one before proceeding:
   ```bash
   gh issue create --title "[<<TASK_PREFIX>>-NNN] Short description" --body "..." --label "status: in-progress"
   ```
3. Use the resulting issue number as the task ID.

**STOP and do NOT create the PR** until a valid `<<TASK_PREFIX>>-<digits>` number is confirmed.

> ⚠️ Context switch on `<<DEFAULT_BRANCH>>`: if you are on the default branch, do not reuse any task ID from previous merged commits — those belong to merged work. The only valid signal is what the current diff content says.

### 3. Detect or Create Branch

```bash
git branch --show-current
```

**Case A — Already on a feature branch (not `<<DEFAULT_BRANCH>>`)**:
- Use the current branch as-is.
- If `branch-name` input was also provided and differs, warn the user and confirm.

**Case B — On `<<DEFAULT_BRANCH>>`**:
- Determine the branch name with this priority:
  1. `branch-name` input if provided.
  2. Derive from the inferred task ID + short description from the diff (e.g. `feature/task-014-short-description`).
  3. If neither is available, **STOP and ask**.
- Create and switch:
  ```bash
  git checkout -b <branch-name>
  ```

**NEVER commit to `<<DEFAULT_BRANCH>>`.**

Acceptable branch name formats:
- `feature/task-001-short-description`
- `fix/task-015-issue-summary`
- `docs/task-020-readme-refresh`

### 4. Generate Commit Message

Use the project commit format (enforced by CI — see `<<CI_WORKFLOW_PATH>>`):

```
[<<TASK_PREFIX>>-XXX] Short descriptive message [AI-assisted]
```

**Guidelines**:
- Use present tense ("Add" not "Added")
- Be specific — mention the module, tool, or component
- Keep under 72 characters before the optional `[AI-assisted]` tag

If AI-assisted, include co-author in the commit body:
```
<<COAUTHOR_LINE>>
```

### 5. Stage Changes

Prefer staging specific files over `git add .` to avoid committing `.env` or generated files:

```bash
git add path/to/specific/file.ts
# Or stage by subproject directory if applicable
git add <<PROJECT_PATHS>>
```

### 6. Commit

```bash
git commit -m "[<<TASK_PREFIX>>-XXX] Your message [AI-assisted]" \
  -m "<<COAUTHOR_LINE>>"
```

### 7. Pre-Push Review — WAIT FOR CONFIRMATION

Before pushing, show a summary and **wait for explicit user confirmation**:

```
📦 Ready to push

  Branch:  feature/task-014-short-description
  Commits: 1 new commit
  Title:   [<<TASK_PREFIX>>-014] Add feature X [AI-assisted]

  Files staged:
    - path/to/file.ts
    - path/to/other.ts

  PR title (CI check): [<<TASK_PREFIX>>-014] Add feature X ✅

Push to origin and open PR? (y/n)
```

**Do NOT push until the user confirms.**

### 8. Push to Remote

Only after confirmation:

```bash
# First push for new branch
git push -u origin <branch-name>

# Subsequent pushes to existing branch
git push origin <branch-name>
```

### 9. Open Pull Request (if `<<ISSUE_TRACKER>>` is `gh`)

#### 9a. Find the linked issue

```bash
TASK_ID="<<TASK_PREFIX>>-030"  # replace with detected ID
ISSUE_NUMBER=$(gh issue list \
  --search "[${TASK_ID}]" \
  --state all \
  --json number,title \
  --jq '.[0].number' 2>/dev/null)
```

If `gh` is not installed or `ISSUE_NUMBER` is empty, proceed without issue linking.

#### 9b. Extract acceptance criteria from the issue

```bash
ACCEPTANCE_CRITERIA=$(gh issue view "$ISSUE_NUMBER" \
  --json body --jq '.body' \
  | awk '/^## Acceptance Criteria/{found=1; next} /^## /{found=0} found && /^- \[/{print}')
```

#### 9c. Validate PR title before creating

```bash
PR_TITLE="[<<TASK_PREFIX>>-XXX] Your description"
if ! echo "$PR_TITLE" | grep -qE '<<TASK_REGEX>>'; then
  echo "❌ PR title must match <<TASK_REGEX>>"
  echo "   Got: $PR_TITLE"
  exit 1
fi
echo "✅ PR title format valid"
```

If a PR already exists for the current branch — update, do NOT create a new one:

```bash
EXISTING_PR=$(gh pr list --head "$(git branch --show-current)" --json number,url --jq '.[0].url' 2>/dev/null)
```

If `EXISTING_PR` is non-empty, run `gh pr edit "$EXISTING_PR" --title ... --body ...`. Otherwise:

```bash
gh pr create \
  --title "[<<TASK_PREFIX>>-XXX] Your description" \
  --body "$(cat <<EOF
## Summary
- <bullet: what changed and why>
- <bullet: any relevant context or decisions>

## Changes
- \`path/to/file.ts\` — description of change

## Acceptance Criteria (from #${ISSUE_NUMBER})
${ACCEPTANCE_CRITERIA}

## Checklist
- [ ] PR title follows format: \`[<<TASK_PREFIX>>-XXX] Description\`
- [ ] All CI checks passing
- [ ] Code reviewed by at least one team member
- [ ] Documentation updated (if applicable)

Closes #${ISSUE_NUMBER}
EOF
)" \
  --base <<DEFAULT_BRANCH>>
```

`Closes #N` tells GitHub to **automatically close the issue when this PR is merged** — do not remove that line.

### 10. Confirm and Report

```bash
git status
git log --oneline -3
gh pr view --web   # optional: open in browser
```

Report:
- ✅ Branch used or created
- ✅ Files staged and committed
- ✅ Commit message used
- ✅ Branch pushed to remote
- ✅ PR URL

## Guardrails

### Always Do
✅ Check current branch before creating a new one
✅ Use `[<<TASK_PREFIX>>-XXX]` format in commit AND PR title
✅ Include a non-empty PR body
✅ Target `<<DEFAULT_BRANCH>>` as PR base branch
✅ Run tests before committing
✅ Stage specific files when possible

### Never Do
❌ Commit to `<<DEFAULT_BRANCH>>` branch
❌ Commit `.env` files or credentials
❌ Skip tests before committing
❌ Create a PR with an empty body
❌ Use `--no-verify` to skip hooks
❌ Create a PR before validating the title format locally

## Error Handling

**Push rejected (remote has changes)**:
```bash
git pull origin <branch-name> --rebase
git push origin <branch-name>
```

**Branch already exists with conflicts**:
```bash
git fetch origin
git rebase origin/<<DEFAULT_BRANCH>>
```

**`gh` CLI not authenticated**:
```bash
gh auth login
```
