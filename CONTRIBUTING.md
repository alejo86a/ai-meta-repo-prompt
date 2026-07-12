# Contributing

Thanks for improving `ai-meta-repo-prompt`. Every change must survive the same
demanding verification battery used to design it.

## Setup (once per clone)

```bash
git config core.hooksPath .githooks
```

## Before you commit

1. **Keep both READMEs in sync.** If you edit `README.md`, mirror the change in
   `README.es.md` (and vice-versa). Gate 0 blocks a drifting pair.
2. **Run the deterministic smoke test** when you touch the creator pipeline:
   ```bash
   scripts/sandbox-e2e.sh          # or: PR_LIMIT=5 scripts/sandbox-e2e.sh
   ```
3. **Run the deep agent battery** for non-trivial changes: paste
   `skills/verify-meta-repo.md` to your coding agent at the repo root and wait
   for `VERIFICATION PASSED`.

## Committing

Gate 0 runs automatically on `git commit`. For changes verified by the agent
battery, acknowledge it:

```bash
VERIFY_AGENT_DONE=1 git commit -m "…"
```

Emergency bypass (discouraged): `git commit --no-verify`. The CI workflow
(`.github/workflows/verify.yml`) re-runs Gate 0 on every push/PR as a safety net.

## Conventions

- Keep the meta-repo creator **business-agnostic and model-agnostic**. The
  canonical context-hub file is `AGENTS.md`; don't hardcode a specific agent,
  language, or business.
- Never commit secrets. `.env/` is git-ignored and Gate 0 rejects token literals.
- Update `CHANGELOG.md` under `[Unreleased]` for user-visible changes.

See the [README](README.md) for the full verification details.
