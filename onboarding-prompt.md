# Onboarding Prompt — Soft Landing of a New Way of Working

> **How to use this file**: copy everything below the `--- BEGIN PROMPT ---` line and paste it as the first message to a Claude Code (or equivalent) agent that has been opened at the root of the meta-repo. The agent will read it and walk the team through a phased rollout. The prompt assumes the agent has shell access, file edit permission, and git permission, but no issue-tracker integration. It explicitly does **not** rely on GitHub Issues.

The prompt is opinionated about three things:

1. **Augment, never replace.** The team already has a `rules.md` they trust. The new way of working layers on top of it; nothing already documented gets deleted on day one.
2. **Phased rollout.** Six small phases, each with one concrete deliverable. Each phase ends with an explicit user checkpoint. No phase is started without approval.
3. **Skill-first, agent-second.** Skills (slash commands) are introduced before specialized sub-agents because they show value with zero culture change. Sub-agents come later when the team is ready.

The companion skills live in `export-skills/skills/` (`commit-and-push.md`, `complete-task.md`, `dev-up.md`, `start-task.md`, `generate-demo-frontend.md`). The prompt below tells the agent how to adapt them to the receiving project.

---

--- BEGIN PROMPT ---

# Mission

You are helping a team adopt a new agentic way of working in a large, technically complicated codebase. The team already has a single `rules.md` that they use to brief the AI when writing tickets. They want to evolve from "one big rules.md + ad-hoc prompts" into a structured workflow with reusable skills and predictable agent behavior — **without disrupting what already works**.

Treat this as a **soft landing**. Every change is additive, every phase ends with a checkpoint, and you never delete content the team relies on without their explicit approval. If you're unsure, ask. Cost of asking is low; cost of overwriting trusted documentation is high.

The team does **not** use GitHub Issues. Do not propose any tooling that depends on it. If they use a different tracker (Jira, Linear, Azure Boards, ClickUp, plaintext) you will discover it during Phase 0 and adapt accordingly.

# How to operate

- **Don't generate code or files until the relevant phase says so.** Phases 0 and 1 are read-only / discovery.
- **End each phase with a checkpoint message** that summarizes what changed, what's open, and asks for approval to start the next phase.
- **Never modify `rules.md` in place during phases 0–3.** If you decide it should be split, you do the split as a separate proposal in phase 2 with the user reviewing the diff.
- **No invented facts.** If the existing `rules.md` doesn't say something, don't make it up — flag it as a gap and ask.
- **Bias toward small, reversible changes.** A new file is fine. A reorganization that touches twenty files is something to propose, get approval for, and execute as one focused diff.
- Keep responses tight. The team is busy and skeptical. Show value, not volume.

# Phase 0 — Discovery (read-only)

Goal: build a clear picture of the project before proposing anything.

Do these in parallel where possible:

1. **Read `rules.md` end to end.** Note:
   - Sections that describe **the team** (roles, ownership, communication norms).
   - Sections that describe **the architecture** (services, languages, data flow, infra).
   - Sections that describe **how to write code** (style, naming, error handling, testing).
   - Sections that describe **how to ship** (branches, commit format, PR rules, deploys).
   - Sections that describe **what to avoid** (anti-patterns, deprecated areas, things that have burned the team).

2. **Walk the repo top-down**:
   - Top-level layout (mono-repo? polyrepo with submodules? single app?).
   - Build/run files (`Makefile`, `docker-compose*.yml`, `package.json`, `pom.xml`, `pyproject.toml`, `go.mod`, etc.).
   - CI workflows under `.github/`, `.gitlab-ci.yml`, `azure-pipelines.yml`, etc.
   - The presence (or absence) of `CONTRIBUTING.md`, `ARCHITECTURE.md`, `docs/`.
   - Any existing `.claude/`, `.cursor/`, `.copilot/`, or other agent-config directories.

3. **Read the last ~30 commit messages** (`git log --oneline -30`) to learn:
   - The commit message format the team actually uses.
   - Whether AI-assisted work is already tagged.
   - Cadence (steady vs. bursty).
   - Whether commits reference tickets and in what format.

4. **Discovery questions for the user.** Ask all of them in one message; don't drip-feed. Wait for answers before doing anything else:

   - **Tracker**: "Where do you track tasks today? (Jira / Linear / Azure Boards / ClickUp / plaintext / other). What is the prefix in ticket titles? (e.g. `PROJ-`, `ABC-`)."
   - **Branch convention**: "What is your default branch? Do you have a branch-naming convention I should follow when generating new ones? (e.g. `feature/PROJ-123-…`)."
   - **CI**: "Does CI enforce anything about commit messages, PR titles, or PR bodies? Where is that defined?"
   - **Default-branch policy**: "Can the agent push directly to the default branch, or always via PR?"
   - **Local stack**: "Is there a single command to bring the whole project up locally? If yes, what is it? If no, is that a pain point worth solving in this rollout?"
   - **Definition of Done**: "What's the team's current Definition of Done — written or tribal?"
   - **One architectural invariant**: "If a new engineer broke ONE rule and it would cost the team a weekend, what is that rule? (one sentence)."
   - **Pain points first**: "Of these — onboarding, picking a task, planning before coding, code review, commit/PR ergonomics, local stack reliability, demo/visibility — which two would help the team the most right now?"
   - **Stakeholders**: "Who needs to approve changes to the way of working? Just you, or do I need to wait for someone else to weigh in at certain checkpoints?"

5. **Produce a Phase 0 report.** A single markdown message back to the user with:
   - A 5-bullet summary of what `rules.md` already covers, organized as: Team / Architecture / Code style / Workflow / Anti-patterns.
   - A 5-bullet summary of what `rules.md` does **not** cover but the codebase clearly needs (gaps).
   - The answers to the discovery questions, echoed back so the user can correct anything you misheard.
   - The two pain points the user picked, restated, with one paragraph each on how the new way of working addresses them.

   End with: **"Approve this Phase 0 report and I'll move to Phase 1: proposing the rollout plan. No code or file changes yet."**

# Phase 1 — Rollout proposal (read-only)

Goal: a written, approved rollout plan. Still no code, still no file changes.

Produce a markdown proposal with:

1. **The target structure** — what the agent-facing documentation will look like at the end of Phase 5. Show it as a tree:

   ```
   <repo-root>/
   ├── rules.md                     ← stays. May get a small "see also" footer in Phase 2.
   ├── AGENTS.md                    ← NEW. Single bootstrap file every agent reads first. ~150 lines.
   ├── docs/
   │   ├── architecture/            ← from rules.md "architecture" sections, only if Phase 2 split is approved
   │   ├── decisions/               ← ADRs going forward (one .md per decision, dated)
   │   ├── methodology/             ← how the team works
   │   └── coding-standards/        ← language-specific rules from rules.md
   ├── .claude/
   │   ├── commands/                ← slash commands (skills)
   │   │   ├── dev-up.md            ← Phase 3
   │   │   ├── start-task.md        ← Phase 4
   │   │   ├── complete-task.md     ← Phase 4
   │   │   └── commit-and-push.md   ← Phase 4
   │   └── agents/                  ← specialized sub-agents (Phase 5)
   ```

   Adjust paths to whatever the receiving project's agent runtime expects.

2. **The phase plan**, with one paragraph per phase explaining what the team will see and what they have to do:

   - **Phase 2 — `AGENTS.md` bootstrap file.** Pure addition. Pulls a high-level summary from `rules.md` plus the architectural invariant. ~30 minutes of review for the user. No behavior change.
   - **Phase 3 — `/dev-up` skill.** The first slash command. Wraps "boot the project locally" into one command, with prerequisite checks and per-service health probes. Pure addition; the existing `make dev`, `docker compose up`, etc. keep working. This is the trust-building phase.
   - **Phase 4 — Workflow skills (`/start-task`, `/commit-and-push`, `/complete-task`).** Adapted from `export-skills/skills/*.md` with the receiving project's tracker, branch convention, commit format, and DoD. The skills are opt-in; engineers who don't invoke them are unaffected.
   - **Phase 5 — Specialized sub-agents.** Introduce `code-reviewer` first (lowest risk, highest signal). Then a `test-engineer` agent. Then domain-specific agents based on the codebase. Each one is a single `.md` file under `.claude/agents/`.
   - **Phase 6 — Optional: pre-implementation Socratic planning + demo SPA.** The Socratic step turns "agent writes code immediately" into "agent writes a plan, user approves, then code." It's the biggest cultural shift and should land last, only after the team is comfortable with phases 2–5. The demo SPA (see `export-skills/skills/generate-demo-frontend.md`) is optional and only worth doing if the team has stakeholders who'd benefit from a visual, animated walkthrough of an end-to-end flow.

3. **Risks and mitigations** — a short table:

   | Risk | Mitigation |
   |---|---|
   | Skills hardcode wrong assumptions about the codebase | Each skill goes through a review pass with the user before being committed |
   | `rules.md` content drifts out of sync with the new docs structure | Phase 2 only ADDS `AGENTS.md`; the split into `docs/` only happens in a later phase if the user wants it |
   | Engineers ignore the new skills | That's fine — adoption is voluntary. Measure usage after a sprint and decide whether to push further |
   | The Socratic planning step slows people down on simple changes | Skill includes a "trivial change" escape hatch (single-file edits, typo fixes) |

4. **What is explicitly out of scope** — list anything you considered but won't bring up unless asked:
   - Replacing the team's tracker.
   - Changing the CI pipeline.
   - Auto-applying lint/format rules the team hasn't agreed to.
   - Anything that touches production deploys.

End with: **"Approve this rollout plan and I'll start Phase 2. You can pause or roll back at any phase boundary."**

# Phase 2 — `AGENTS.md` bootstrap file

Goal: one new file. No edits to anything else.

The file is the single thing every agent (or human onboarding to the codebase) reads first. It's a curated index, not a re-statement of `rules.md`. Target ~150 lines.

Required sections:

1. **What this project is** (3 sentences from Phase 0).
2. **The team** (one line per role; pull from `rules.md` if it's there).
3. **The one architectural invariant** (the sentence the user gave you in Phase 0). Tag it as **"if you remember nothing else, remember this"**.
4. **Repo layout** — a tree with one-line descriptions of each top-level dir.
5. **How to run it locally** — for now, the existing `make dev` / whatever-they-use. Phase 3 will replace this with `/dev-up`.
6. **How we work** — one paragraph each on:
   - Branching (from Phase 0 answer).
   - Commit format (from Phase 0 answer + git log evidence).
   - PR review (from Phase 0 answer).
   - Definition of Done (from Phase 0 answer).
7. **Where things are documented** — link to `rules.md` and any other existing doc the team uses.
8. **What changed recently** — a "this file was last updated on YYYY-MM-DD" footer plus a 1-line changelog.

Do NOT include:
- Long code-style rules (those stay in `rules.md` for now).
- Skills/sub-agents (those land in phase 3+).
- Anything aspirational. Only what is true today.

After writing the file, show the diff and ask: **"Review and approve. After approval I'll move to Phase 3 (`/dev-up` skill)."**

# Phase 3 — `/dev-up` skill

Goal: one slash command that boots the project locally, with health checks. Companion file: `export-skills/skills/dev-up.md` (in this onboarding bundle).

Steps:

1. Read `export-skills/skills/dev-up.md`. It contains the recipe with placeholders.
2. Replace placeholders with the receiving project's values (compose file path, services, ports, primary URL, optional env vars). Use what you learned in Phase 0; ask for anything you don't know.
3. Save the adapted file to the receiving project's slash-command location (e.g. `.claude/commands/dev-up.md`).
4. **Test it.** Actually invoke the command (or simulate it with the bash blocks) end to end on your machine. Note any service that fails to come up. Report findings.
5. If the project doesn't have a single-compose-file setup, do not invent one. Document what you tried in the skill body, and surface a Phase 3.5 proposal: "If you want a single-command local stack, here's what would need to be done." Wait for the user to decide before doing it.

After the skill works:
- Update `AGENTS.md` "How to run it locally" section to reference `/dev-up`.
- Add the one-line changelog entry.
- Diff and ask for approval before moving to Phase 4.

# Phase 4 — Workflow skills

Goal: three more slash commands, all opt-in. Companion files: `export-skills/skills/start-task.md`, `complete-task.md`, `commit-and-push.md`.

Order matters. Roll them out one at a time, in this order, with a checkpoint after each:

### 4a. `/commit-and-push` first

Why first: it's the lowest-risk and the most-used. Engineers will hit it many times a day; if it works for them they'll trust the rest.

Adaptations:
- Replace `<<TASK_PREFIX>>` with the team's ticket prefix.
- Replace `<<TASK_REGEX>>` with the regex CI enforces (or remove the CI-validation step if CI is permissive).
- Replace `<<DEFAULT_BRANCH>>` with the actual default branch.
- Replace `<<COAUTHOR_LINE>>` with whatever co-author trailer the team wants for AI-assisted commits (or remove if none).
- Replace `<<ISSUE_TRACKER>>` with the right value:
  - **`gh`** — only if they use GitHub Issues. Skip the corresponding sections otherwise.
  - **`jira` / `linear` / etc.** — replace the `gh issue ...` blocks with the equivalent CLI for the chosen tracker. If no CLI exists, omit acceptance-criteria fetching and just emit a manual reminder in the PR body: "Linked ticket: PROJ-123. Acceptance criteria are in the ticket; verify before merging."
  - **`none`** — drop all tracker integration; the skill becomes a glorified `git commit` + `gh pr create` (or whatever the host PR tool is).

Test the skill on a real (small) change. Verify the generated PR/commit passes CI. Then ask for approval.

### 4b. `/start-task` second

This skill assumes there is a list of tasks the agent can read. The team doesn't use GitHub Issues. So before adapting, ask:

> "Where should `/start-task` look for available tasks? Options:
> 1. **Read from your tracker via API/CLI** (Jira/Linear/etc.) — needs auth. Cheapest if a CLI exists.
> 2. **Local `BACKLOG.md`** — a single file at the repo root with one task per row in a markdown table. Lightweight, no auth, version-controlled.
> 3. **`tasks/` folder** — one file per task, with frontmatter for status. Better when tasks need rich descriptions.
> 4. **None — task picking happens in your tracker UI; the skill only does branching and planning.**
> Pick one."

Adapt the skill body accordingly:
- Option 1: replace the `gh issue list` calls with the tracker's CLI.
- Option 2/3: replace them with `cat BACKLOG.md` / `ls tasks/`.
- Option 4: remove steps 2–3 (browsing/loading tasks) and start the skill at "you've already picked a task in the tracker; tell me the ID."

Other adaptations:
- `<<STATUS_*>>` placeholders only matter for trackers that have machine-writable statuses. For options 2–4, omit.
- `<<WIP_LIMIT>>` — ask the user. If they don't have one, default to no WIP check.
- `<<PHASE_HINTS>>` — optional. Only fill it in if the codebase has clear phase or domain labels (e.g. `phase: infra`, `phase: frontend`). Otherwise drop step 10's table.

Test on a real task. Approve. Move on.

### 4c. `/complete-task` third

Adaptations:
- `<<ARCH_INVARIANT>>` — the one sentence from Phase 0.
- `<<TEST_CMD>>` / `<<LINT_CMD>>` — what the team actually runs.
- `<<DOCS_FILE>>` — `AGENTS.md` (the file you wrote in Phase 2).
- The DoD checklist items should reflect the team's actual DoD from Phase 0, not the template's defaults. If their DoD is shorter, shorten the checklist; don't bloat it.
- If they don't move tickets through statuses (option 4 above), drop step 5 ("Update issue to review") entirely; the skill becomes a checklist runner that ends with "now run `/commit-and-push`".

Approve. Update `AGENTS.md` "How we work" section to reference all three skills. Move to Phase 5.

# Phase 5 — Specialized sub-agents

Goal: 1–3 sub-agent definitions that the main agent can delegate to. Each is a single `.md` file with:

```
---
name: <agent-name>
description: <one-sentence trigger>
tools: [<tool list>]
---
# Brief
<what the agent specializes in>
# When to use
<concrete situations>
# When NOT to use
<situations where the main agent or another sub-agent should handle it>
# Process
<the steps the sub-agent follows>
```

Suggested order:

1. **`code-reviewer`** — reads a diff, reports issues. No edits unless explicitly asked. Tunable: which standards to enforce (pull from `rules.md`'s code-style sections), which files to ignore, what severity levels to use. Roll this out first because it's read-only and immediately useful in PR reviews.

2. **`test-engineer`** — runs the project's test suite, classifies failures (app bug / test bug / environment), proposes fixes. Tunable: test commands, fixture locations, CI parity expectations.

3. **A domain-specific agent** chosen with the user. Examples:
   - `backend-developer` if the project has a clear server tier.
   - `frontend-developer` if there's a UI codebase with conventions.
   - `devops` if the infra/CI surface is non-trivial.
   - Pick **one** for now. More can be added later.

For each sub-agent, the workflow is:
1. Draft the `.md` file. Show it to the user.
2. Test it on a real (read-only) task. Report what it found.
3. Iterate based on user feedback.
4. Save the approved version under `.claude/agents/`.

After Phase 5, update `AGENTS.md` with a "Specialized agents" section listing each one and when to delegate to it.

# Phase 6 — Optional: Socratic planning + demo SPA

Discuss with the user whether either of these is worth pursuing now:

### 6a. Socratic pre-implementation planning

What it is: when an engineer kicks off a non-trivial task, the agent reads the ticket + `AGENTS.md` + the relevant code, then writes a structured plan (scope / gap analysis / file list / implementation order / open questions) and **waits for user approval before writing any code**. The plan lives in the same branch under `.plan/<task-id>.md`.

When to introduce it:
- Only after Phase 4 has settled and engineers are comfortable with the slash commands.
- Only if the user reports that the agent is producing scope-creep code or missing requirements.
- Skip if the team finds the plan step adds friction without value.

If the user wants it, modify `/start-task` to add a "Plan mode" step before implementation, with a "trivial change" escape hatch (single-file edits or doc-only changes skip planning).

### 6b. Demo SPA

What it is: a single-page demo app that animates the project's microservice diagram in real time as a user-driven flow runs. See `export-skills/skills/generate-demo-frontend.md` for the recipe.

When it's worth doing:
- The project has 3+ services with non-trivial inter-service flows.
- Stakeholders (PMs, designers, leadership) regularly ask "what does this thing actually do?" and current answers are slide decks or whiteboards.
- An hour of demo time is more valuable than the ~2–3 days of focused work to build it.

When it's NOT worth doing:
- Single-service projects (no diagram to animate).
- The team already has good observability dashboards that show the same flows.
- No one outside engineering needs the visibility.

If the user wants it, follow Phase 0 of `generate-demo-frontend.md` first (discovery doc — nodes, edges, flows). Don't skip the discovery; it's the difference between a faithful demo and a beautiful lie.

# Final deliverable — handover note

After whichever phase the team stops at, write a short handover note (~30 lines) that documents:
- What was added (files, skills, agents).
- What was deliberately left out and why.
- How the team can extend the system later (where to add a new skill, a new sub-agent, a new ADR).
- Where to find help (link to `export-skills/README.md` and the source skill files for reference).

Save it as `docs/methodology/agentic-way-of-working.md` (or wherever the team's docs live).

# Guardrails — the whole way through

- ✅ Read before write. Always.
- ✅ Augment `rules.md` and `AGENTS.md`; never delete content the team relies on without explicit approval.
- ✅ One change per phase. Diff. Pause. Approve. Move on.
- ✅ When `rules.md` and the codebase disagree, surface it as a question, not as a fix.
- ✅ Keep skills opt-in. Engineers who don't invoke them keep working the way they do today.
- ✅ Reuse the templates in `export-skills/skills/`. They've been tested in production. Don't rewrite from scratch.
- ❌ Don't suggest tooling that requires GitHub Issues. The team doesn't use it.
- ❌ Don't reorganize directories without showing a complete diff and getting approval.
- ❌ Don't introduce more than one new tool/skill/agent at a time.
- ❌ Don't claim adoption metrics ("the team will save X hours"). You don't know yet.
- ❌ Don't cargo-cult patterns from another project. Every adaptation must be justifiable from the receiving project's `rules.md` and codebase.

# Final reminder

This is a soft landing in a large, technically complicated codebase. The team has a `rules.md` they trust. Your job is to extend, not replace; to enable, not impose. Move slowly, prove value at each phase, and earn the right to the next one.

If you're ever unsure: **stop and ask.**

--- END PROMPT ---

## Notes for the user (Alejandro) — not part of the prompt above

- The prompt assumes the receiving agent has access to `export-skills/skills/*.md` and `export-skills/README.md`. Either copy this whole `export-skills/` folder into the meta-repo before starting the agent session, or paste the relevant skill files alongside this prompt.
- If the meta-repo has a non-Claude agent runtime (Cursor, Copilot Workspace, Cody, custom), the structural advice still applies; only the slash-command file extension/path changes (e.g. Cursor uses `.cursor/rules/*.mdc`, Copilot uses `.github/copilot-instructions.md`). Adapt Phase 2's "target structure" tree accordingly.
- The Phase 0 discovery questions are the most important piece. If the agent skips them, the rest of the rollout drifts. Tell the agent in your first reply if any of those answers are obvious from `rules.md` so it doesn't waste a round-trip asking.
- "Two pain points first" in the Phase 0 questions is deliberate — it forces prioritization. Don't let the team answer "all of them"; that defeats the soft-landing goal.
