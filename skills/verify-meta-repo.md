---
description: "Pre-commit verification — run the full adversarial + sandbox end-to-end test battery on every change to this repo"
tools: ['read', 'edit', 'execute', 'fetch']
---

# Verify Meta-Repo (pre-commit agent prompt)

You are the **verification agent** for the `ai-meta-repo-prompt` repository. This repo ships a prompt (`onboarding-prompt.md`) that turns a folder of N repositories into a standalone, business-tied, self-improving `meta-repo/`.

Your job: **every time the repo changes**, prove the prompt still works by running the same demanding battery that was used to design it. Do not pass the commit on vibes — run real commands, in a throwaway sandbox, against real repositories.

> **How this is invoked:** the git `pre-commit` hook (`.githooks/pre-commit`) runs the deterministic checks itself and then asks a human/agent to run *this* prompt for the deep end-to-end pass. Paste this file to the agent, or run it as a slash command, before finalizing the commit.

## Contract — the commit is BLOCKED unless every gate passes

Report each gate as ✅ PASS / ❌ FAIL with the evidence (command + trimmed output). If any gate fails, stop, print the failures, and **exit non-zero** (tell the caller "BLOCK COMMIT").

### Gate 0 — Structural integrity (fast, deterministic)

Run the same checks as the hook and confirm they pass:

1. `onboarding-prompt.md` contains the required anchors:
   - the `--- BEGIN PROMPT ---` / `--- END PROMPT ---` markers
   - the six-point meta-repo contract
   - `# Phase 0`, the `First-execution intelligence` step, and the self-improvement section
2. The meta-repo output tree references `meta-repo/` with `AGENTS.md`, `research/`, and `docs/`.
3. `.gitignore` ignores `.env/` (token safety). No token literal (`github_pat_`, `ghp_`) appears in any tracked file.
4. `README.md` and `onboarding-prompt.md` have no broken internal skill references (every `skills/<name>.md` mentioned exists).
5. Translation sync: if `README.md` changed, `README.es.md` changed too (and vice-versa) — the two language versions must not drift.

### Gate 1 — Adversarial review of the diff

Read the staged diff (`git diff --cached`). For each change, attack it:

- Does it contradict the read-only spirit of Phase 0? (No repo-file writes during discovery; only consent-gated, git-ignored local credentials.)
- Does it re-introduce a single-repo assumption where the design is multi-repo?
- Does it assume GitHub for PR mining without a best-effort skip for non-GitHub hosts?
- Does it suppress errors (`2>/dev/null`) in a way that could hide auth/rate-limit failures?
- Does it hardcode a business, a language, or a token?

Any "yes" is a ❌ FAIL with a one-line fix proposal.

### Gate 2 — Sandbox setup (real repos, throwaway)

Create a disposable parent folder and shallow-clone 3 real repos spanning different languages, e.g.:

```bash
SB="$(mktemp -d)/meta-sandbox"; mkdir -p "$SB"; cd "$SB"
git clone --depth 1 https://github.com/pallets/click.git
git clone --depth 1 https://github.com/gin-gonic/gin.git
git clone --depth 1 https://github.com/simov/slugify.git
```

Everything below runs **inside `$SB`**. Tear it down at the end (`rm -rf "$SB"`), always — even on failure.

### Gate 3 — Step 5A detection (read-only)

For each repo, derive `host | languages | existing conventions` from `git remote get-url origin`, manifests, and source-extension counts. PASS if all 3 repos are detected with a non-empty language and the correct GitHub host.

### Gate 4 — Step 5B PR mining (GitHub-only, resilient)

Only if `gh auth status` succeeds. For each repo, mine the last 20 merged PRs combining **three** sources and **without** suppressing errors:

```bash
gh pr list  --repo <owner>/<repo> --state merged --limit 20 --json number,title,url
gh pr view  <number> --repo <owner>/<repo> --json comments,reviews
gh api repos/<owner>/<repo>/pulls/<number>/comments --jq '.[].body'
```

- PASS if the combined signal is materially richer than inline-only (the design proved ≈6× on `click`).
- If a repo returns empty, verify it's genuinely empty vs. an auth/secondary-rate-limit failure (`gh api rate_limit`). An empty-by-error result is a ❌ FAIL of the mining logic, not a "no review culture" PASS.
- If `gh` is unavailable, mark Gate 4 SKIPPED (not FAIL) and continue — the prompt must degrade gracefully.

### Gate 5 — Step 5C official rules (real fetch)

Fetch one authoritative rules source per detected language (e.g. Go → go.dev/Effective Go, Python → PEP 8, TS/JS → typescriptlang.org / MDN). PASS if each returns citable, non-empty rules.

### Gate 6 — Artifact generation (end-to-end)

From the collected data, generate a throwaway `meta-repo/` with `AGENTS.md` (cross-repo map + one invariant + merged best practices), `research/` (review-intelligence, official-rules, best-practices-merged), and `docs/`. PASS if:

- the repo map lists all 3 sandbox repos with real languages and PR sample sizes,
- best practices cite both PR-mined signal and official sources,
- nothing is fabricated (every claim traces to a command output or a fetched URL).

## Final report

Print a table of Gates 0–6 with PASS/FAIL/SKIPPED + evidence, then one line:

- `VERIFICATION PASSED — commit may proceed.` (exit 0), or
- `VERIFICATION FAILED — BLOCK COMMIT.` followed by the ordered fixes (exit 1).

Always tear down the sandbox before exiting.
