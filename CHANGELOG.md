# Changelog

All notable changes to this project are documented here. The format is loosely
based on [Keep a Changelog](https://keepachangelog.com/), and the project aims
to keep the meta-repo creator model-agnostic and reproducible.

## [Unreleased]

### Added
- Model-agnostic runtime mapping table (Copilot / Cursor / Claude / generic) for where the generated `AGENTS.md` context hub is read from.
- `scripts/sandbox-e2e.sh`: deterministic smoke test that clones 3 real repos and runs the 5A detection + 5B PR-mining gates (best-effort, resilient).
- `LICENSE` (MIT) and this `CHANGELOG.md`.
- `CONTRIBUTING.md` pointing to the pre-commit verification flow.

### Changed
- README now leads with the **meta-repo creator** narrative (renamed from the `export-skills` framing) in both English and Spanish.
- Canonical bootstrap file for the generated meta-repo is **`AGENTS.md`** (model-agnostic); dropped `CLAUDE.md`-first wording.
- Pre-commit hook: restored clean check/cross glyphs and hardened the README translation-sync check when no previous commit exists.

## [0.3.0]

### Added
- Bilingual docs: `README.es.md` with a language switcher, plus a Gate 0 check that keeps `README.md` and `README.es.md` in sync.

## [0.2.0]

### Added
- Pre-commit verification system: `.githooks/pre-commit` (Gate 0), the agent battery prompt `skills/verify-meta-repo.md`, and a CI workflow `.github/workflows/verify.yml`.

## [0.1.0]

### Added
- `onboarding-prompt.md` reframed as a multi-repo, business-agnostic meta-repo creator: studies every repo in a parent folder, mines the last 20 PRs per GitHub repo (consent-gated), merges with official language rules, outputs a standalone `meta-repo/`, and is deletable + self-improving.
- Portable skills bundle under `skills/` and initial project scaffolding.
