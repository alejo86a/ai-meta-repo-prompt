#!/usr/bin/env bash
#
# sandbox-e2e.sh — deterministic smoke test for the meta-repo creator pipeline.
#
# It reproduces the core of the demanding battery from skills/verify-meta-repo.md
# in an automatable way:
#   - clones 3 real repos spanning different languages into a throwaway folder
#   - Gate 3 (5A): detects host + dominant language per repo
#   - Gate 4 (5B): mines recent PR review signal via gh (best-effort, GitHub-only)
#   - always tears the sandbox down
#
# The deep gates (adversarial diff review, official-rules fetch, artifact
# generation) still need the agent prompt; this script covers the mechanical,
# repeatable parts so CI and humans can run a real smoke test on demand.
#
# Usage:
#   scripts/sandbox-e2e.sh            # full smoke test
#   PR_LIMIT=5 scripts/sandbox-e2e.sh # mine fewer PRs (faster)
#
set -euo pipefail

PR_LIMIT="${PR_LIMIT:-10}"
REPOS=(
  "https://github.com/pallets/click.git"
  "https://github.com/gin-gonic/gin.git"
  "https://github.com/simov/slugify.git"
)

SB="$(mktemp -d)/meta-sandbox"
mkdir -p "$SB"
cleanup() { rm -rf "$(dirname "$SB")"; }
trap cleanup EXIT

fail=0
hr() { printf '─────────────────────────────────────────────\n'; }
ok()  { printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad() { printf '  \033[31m✗\033[0m %s\n' "$*"; fail=1; }

hr; printf ' sandbox-e2e · meta-repo creator smoke test\n'; hr

# ── Gate 2 — clone real repos ────────────────────────────────────────────────
printf '\nGate 2 — clone real repos into %s\n' "$SB"
cd "$SB"
for url in "${REPOS[@]}"; do
  name="$(basename "$url" .git)"
  if git clone --depth 1 --quiet "$url" "$name" 2>/dev/null; then
    ok "cloned $name"
  else
    bad "failed to clone $name ($url)"
  fi
done

# ── Gate 3 — 5A detection (host + dominant language) ─────────────────────────
printf '\nGate 3 — 5A detection (host + dominant language)\n'
detect_lang() {
  # crude but deterministic: pick the most common recognized source extension
  local dir="$1"
  git -C "$dir" ls-files 2>/dev/null \
    | grep -oE '\.(py|go|js|ts|tsx|java|kt|rb|rs|c|cpp|cs|php)$' \
    | sort | uniq -c | sort -rn | head -1 | awk '{print $2}'
}
for d in "$SB"/*/; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  host="$(git -C "$d" remote get-url origin 2>/dev/null | sed -E 's#https?://([^/]+)/.*#\1#; s#git@([^:]+):.*#\1#')"
  lang="$(detect_lang "$d")"
  if [[ -n "$host" && -n "$lang" ]]; then
    ok "$name → host=$host lang=$lang"
  else
    bad "$name → incomplete detection (host='$host' lang='$lang')"
  fi
done

# ── Gate 4 — 5B PR mining (GitHub-only, resilient, best-effort) ──────────────
printf '\nGate 4 — 5B PR mining (last %s merged PRs, 3 sources)\n' "$PR_LIMIT"
if ! command -v gh >/dev/null 2>&1; then
  printf '  \033[33m⤳\033[0m SKIPPED — gh not installed (pipeline must degrade gracefully)\n'
elif ! gh auth status >/dev/null 2>&1; then
  printf '  \033[33m⤳\033[0m SKIPPED — gh not authenticated\n'
else
  for d in "$SB"/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    slug="$(git -C "$d" remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/]{1}([^/]+/[^/]+)(\.git)?#\1#; s#\.git$##')"
    [[ -n "$slug" ]] || { bad "$name → could not resolve owner/repo"; continue; }
    # NOTE: errors are surfaced, not piped to /dev/null (resilience rule).
    lines=0
    while IFS= read -r n; do
      [[ -n "$n" ]] || continue
      body="$(gh pr view "$n" --repo "$slug" --json comments,reviews 2>/dev/null || true)"
      inline="$(gh api "repos/$slug/pulls/$n/comments" --jq '.[].body' 2>/dev/null || true)"
      lines=$(( lines + $(printf '%s\n%s\n' "$body" "$inline" | grep -c . || true) ))
    done < <(gh pr list --repo "$slug" --state merged --limit "$PR_LIMIT" --json number --jq '.[].number' 2>/dev/null || true)
    if [[ "$lines" -gt 0 ]]; then
      ok "$name ($slug) → mined signal: $lines lines"
    else
      # empty could be genuine or an API failure — flag, don't silently pass.
      remaining="$(gh api rate_limit --jq '.resources.core.remaining' 2>/dev/null || echo '?')"
      bad "$name ($slug) → empty signal (rate_limit remaining=$remaining) — verify it's genuine, not an API failure"
    fi
  done
fi

hr
if [[ "$fail" -ne 0 ]]; then
  printf ' \033[31mSMOKE TEST FAILED\033[0m — see ✗ items above.\n'; hr
  exit 1
fi
printf ' \033[32mSMOKE TEST PASSED\033[0m\n'; hr
