# export-skills

Portable Claude Code skills extracted from `the-hybrids-planning-project`, ready to drop into any other project. Project-specific names (YugaStore, MCP, Unleash, YugabyteDB) have been replaced with `<<PLACEHOLDERS>>` that the receiving agent must fill in before the skills run.

## Meta-repo creator (start here)

`onboarding-prompt.md` is a **business-agnostic meta-repo creator**. Clone this folder next to the repositories you want it to study, then point an agent at it:

```text
Lee y ejecuta onboarding-prompt.md sobre los repositorios de esta carpeta.
```

What it does on the first run (all logic lives in `onboarding-prompt.md`, not in the trigger):

1. **Studies every repo in the parent folder** — 2, 5, 10, however many — detecting stack, languages, and existing conventions.
2. **Mines the last 20 PRs per repo** via `gh` (consent-gated, GitHub-only, best-effort; asks for a fine-grained token stored under a git-ignored `.env/` if needed) to learn the team's real, enforced review habits.
3. **Fetches official language rules** from authoritative docs (Node.js, MDN, TypeScript, Oracle Java, PEP 8, Go, Kotlin…) and **merges** them with the mined practices into a business-specific standard.
4. **Outputs a new `meta-repo/` folder** whose `AGENTS.md` is a cross-repo context hub. Point Copilot or a terminal agent at it (e.g. copy to `.github/copilot-instructions.md`) and questions/edits across the repo set become faster and more accurate.
5. **Is deletable** afterwards (remove the creator so it isn't mistaken for a project repo) and **self-improving** (any later skill that spots drift proposes an approved update back to the meta-repo).

The studied repositories are never modified.

## What's in the box

| Skill | Purpose |
|---|---|
| `skills/start-task.md` | Pick a task from the issue tracker, check WIP limit, branch off default, force a Socratic plan before any code is written |
| `skills/complete-task.md` | Run a Definition-of-Done checklist, move the issue to `review` |
| `skills/commit-and-push.md` | Validate diff vs. branch context, generate a `[TASK-XXX]` commit, push, and open a PR with linked acceptance criteria |
| `skills/dev-up.md` | Bring up the local Docker Compose stack with prerequisite checks and per-service health probes |
| `skills/generate-demo-frontend.md` | Generate a demo SPA that animates a microservice diagram while a real backend flow runs (chat + SSE) |

## How to use these in a different project

### 1. Copy the files

```bash
mkdir -p .claude/commands   # Claude Code reads slash commands from here
cp export-skills/skills/*.md .claude/commands/
```

(Some Claude Code setups read from `.claude/skills/` instead — check the receiving project's structure and pick the right destination.)

### 2. Fill in the placeholders

Every skill starts with an "Adapter note" table. Search each file for `<<` and replace each occurrence with the receiving project's value. The most common ones:

| Placeholder | Likely value |
|---|---|
| `<<TASK_PREFIX>>` | `TASK`, `JIRA-`, `TICKET` (whatever your tracker uses in titles) |
| `<<TASK_REGEX>>` | The CI regex enforcing the prefix (e.g. `^\[TASK-[0-9]+\]`) |
| `<<DEFAULT_BRANCH>>` | `main`, `master`, `trunk` |
| `<<ISSUE_TRACKER>>` | `gh`, `jira`, `linear`, `none` |
| `<<COMPOSE_FILE>>` | Path to your `docker-compose.yml` |
| `<<SERVICES>>` | The service health-check table |
| `<<PRIMARY_URL>>` | Whatever URL the user should open at the end of `/dev-up` |
| `<<DOCS_FILE>>` | The single file that bootstraps a new agent (e.g. `CLAUDE.md`, `AGENTS.md`) |

If the receiving project uses Jira/Linear instead of GitHub Issues, replace every `gh issue ...` block with the equivalent CLI for the chosen tracker. The structure of the skill (when to update status, what fields to read) stays the same.

### 3. Adapt project-specific bits

Some sections in each skill ask for project context that the source code can't infer. Look for these markers:

- `start-task.md` step 10 — phase → reading-list → recommended-agent table
- `complete-task.md` — `<<ARCH_INVARIANT>>` (one sentence describing your architectural rule)
- `dev-up.md` step 5 — the per-service health-check table
- `generate-demo-frontend.md` Phase 0 — the entire discovery doc

The agent in the receiving project can run the skill once and ask the user to fill these in, then commit the resulting personalized version.

### 4. (Optional) Wire them as slash commands

If the host uses Claude Code, no extra config is needed — files in `.claude/commands/` become `/start-task`, `/complete-task`, etc. automatically.

For other agent runtimes, register each `.md` file as a tool / prompt according to that runtime's convention.

## Contributing (Git + Fine-grained token)

This repository can be pushed with a GitHub fine-grained personal access token (PAT).

### One-time local setup (first time only)

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/alejo86a/ai-meta-repo-prompt.git
```

If `origin` already exists, update it instead of adding it again:

```bash
git remote set-url origin https://github.com/alejo86a/ai-meta-repo-prompt.git
```

### Create a fine-grained token (required)

In GitHub: **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.

Use these settings:

- **Resource owner:** `alejo86a`
- **Repository access:** **Only select repositories** → select `ai-meta-repo-prompt`
- **Repository permissions:**
	- **Contents:** `Read and write` (required for `git push`)
	- **Metadata:** `Read-only` (usually auto-enabled)
	- **Pull requests:** `Read and write` (optional, useful for PR workflows)

Without **Repository access** set to this repo and **Contents = Read and write**, pushes fail with `403`.

### Push using token

Use a placeholder and replace it locally:

```bash
git push -u "https://x-access-token:INSERTA_AQUI_TU_TOKEN@github.com/alejo86a/ai-meta-repo-prompt.git" main
```

Safer alternative (does not leave token in shell history):

```bash
read -s GH_TOKEN
git push -u "https://x-access-token:${GH_TOKEN}@github.com/alejo86a/ai-meta-repo-prompt.git" main
unset GH_TOKEN
```

### Common errors

- `403 Write access to repository not granted`: token exists, but does not have `Contents: Read and write` and/or repo access is not set to `ai-meta-repo-prompt`.
- `404 Repository not found`: wrong owner/repo URL, or token cannot see that repository.

## Generating the demo SPA

`generate-demo-frontend.md` is the odd one out — it's not a workflow command; it's a generator. Run it once per project. Workflow:

1. The agent reads `generate-demo-frontend.md`.
2. **Phase 0 (discovery)** — the agent produces a written discovery doc listing every node, edge, and flow. The user reviews and approves. **No code is written yet.**
3. **Phase 1 (backend)** — the agent generates the demo backend (Node/Express + SSE).
4. **Phase 2 (frontend)** — the agent generates the React SPA with the animated SVG diagram and the playback engine.
5. **Phase 3 (compose)** — the agent wires the two new services into the project's `docker-compose.yml` and updates `/dev-up` to poll their health.
6. **Phase 4 (smoke test)** — the agent boots the demo and verifies `/api/health`, `/api/use-cases`, and `/api/chat`.

The protocol between backend and frontend (SSE event shapes, playback cadences) is fixed across projects — only the topology and the flows change. That keeps the recipe reusable.

## What's intentionally NOT in the box

- `kanban`, `standup`, `dev-logs`, `dev-reset`, `new-task` skills — keep those project-local; they're either too tied to GitHub Issues label conventions or too thin to be worth genericizing.
- Subagent definitions (`.claude/agents/*.md`) — those reference project-specific stacks (TypeScript MCP, YugabyteDB, Unleash) and don't generalize cleanly. Define the receiving project's agents from scratch.
- The actual demo SPA source — `generate-demo-frontend.md` is the recipe; it generates the source on demand against the receiving project's topology.

## Sanity check before handing off

Before giving these to another agent, grep for leftovers from the source project:

```bash
grep -RIn -E "yugastore|mcp-server|unleash|yugabytedb|los híbridos|hybrids" export-skills/ || echo "clean"
```

The output should be `clean`. If it isn't, those references leaked through and need to be turned into placeholders.
