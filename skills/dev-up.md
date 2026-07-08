---
description: "Start the full local development stack with health checks"
tools: ['execute']
---

# Start Local Development Stack

Start the project's local stack using Docker Compose. Verifies and installs prerequisites automatically and brings up every service the project expects.

> **Adapter note (read first):** the placeholders below are wrapped in `<<...>>`. Replace each one with values that fit the receiving project before this skill is usable.
>
> | Placeholder | What it represents | Example |
> |---|---|---|
> | `<<COMPOSE_FILE>>` | Path to `docker-compose.yml` (relative to repo root) | `docker-compose.yml`, `infra/compose.yml` |
> | `<<COMPOSE_ROOT>>` | Directory the `docker compose` commands must run from | repo root |
> | `<<SERVICES>>` | Ordered list of service names + ports + healthcheck strategies (fill in the table below) | — |
> | `<<MAIN_IMAGE>>` | Image tag the smart `up` mode uses to detect first-run | `myproject-api:latest` |
> | `<<PRIMARY_URL>>` | The URL the user should open at the end | `http://localhost:5173` |
> | `<<OPTIONAL_ENV>>` | Optional env vars that change behavior at boot (and what happens when unset) | see template below |

## Input

- **mode** (OPTIONAL): `up` (default), `rebuild`, `down`, `status`

${input:mode:Run mode — up (default) | rebuild (teardown + rebuild image) | down | status}

## Instructions

### 1. Check prerequisites

#### 1a. Homebrew (macOS)

```bash
which brew
```

If not found:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 1b. Docker CLI

```bash
which docker
```

If not found:
```bash
brew install docker
```

#### 1c. Docker runtime (Docker Desktop or Colima)

```bash
docker info > /dev/null 2>&1
```

If Docker daemon is **not running**:

1. Check if Colima is installed:
   ```bash
   which colima
   ```
   - **Colima found but not running** → `colima start`. Wait up to 30s for `docker info` to succeed.
   - **Colima not found** → `brew install colima && colima start`.

2. If after starting Colima `docker info` still fails, tell the user:
   > "Docker daemon is unreachable even after starting Colima. Try `colima delete && colima start` or restart Docker Desktop."
   Stop here.

#### 1d. (Optional) Tracker CLI — only if the project's task workflow uses it

```bash
which gh
```

If not found:
```bash
brew install gh
```
Then:
```bash
gh auth status
```
If not authenticated:
```bash
gh auth login
```

### 2. (Optional) Verify project-specific seed assets

If the project ships with seed assets (placeholder images, fixtures, sample data) that must exist before the stack boots, validate them here. Replace this block with the project's own check, e.g.:

```bash
# Example: 60 placeholder images expected
test -d path/to/assets && \
  test "$(ls path/to/assets/*.jpg 2>/dev/null | wc -l | tr -d ' ')" = "60" && \
  echo "ok: assets present" || \
  echo "missing: regenerate with <project's regenerate command>"
```

If missing, regenerate with the project's idempotent generator before continuing.

### 3. Surface optional env keys (`<<OPTIONAL_ENV>>`)

For each optional env var, warn the user if unset and explain the degraded behavior. Template:

```bash
if [ -z "$VAR_NAME" ]; then
  echo "ℹ VAR_NAME not set — <feature> will run in degraded mode."
  echo "   To enable <feature>, export it before running this skill."
fi
```

If the user only sets the var after the stack is up, restart the affected service:
```bash
docker compose up -d <service>
```

### 4. Execute based on mode

All `docker compose` commands must run from `<<COMPOSE_ROOT>>`.

**`status`** — show current container state and exit:
```bash
docker compose ps
```

**`down`** — stop the stack (data preserved):
```bash
docker compose down
```

**`rebuild`** — teardown + full image rebuild:
```bash
docker compose down
docker compose up -d --build
```

**`up`** (default) — smart start:
```bash
docker images <<MAIN_IMAGE>> --format "{{.Repository}}"
```
- Image exists → `docker compose up -d`
- Image does NOT exist → `docker compose up -d --build` (first run, detected automatically)

### 5. Poll for health (skip for `down` and `status`)

Check every 5 seconds, timeout 90s per service. Print a live status line while waiting. Services come up in dependency order; only start polling each one once its dependencies are healthy.

For each service in `<<SERVICES>>`, run the appropriate probe. Common patterns:

| Probe type | Command |
|---|---|
| Compose healthcheck (most reliable) | `docker inspect --format='{{.State.Health.Status}}' <container> 2>/dev/null \| grep -q healthy` |
| Postgres ready | `docker exec <container> pg_isready -U <user> > /dev/null 2>&1` |
| HTTP health endpoint | `curl -sf http://localhost:<port>/health > /dev/null 2>&1` |
| Plain HTTP root | `curl -sf http://localhost:<port> > /dev/null 2>&1` |

> **Why prefer the compose healthcheck over `curl localhost`**: some services bind to the container's external interface, not 127.0.0.1, so `docker exec ... curl localhost:<port>` always fails even when the service is ready. The compose-level healthcheck (defined in `<<COMPOSE_FILE>>`) is the source of truth.

Fill in this table for the receiving project:

| Service | Container name | Host port | Probe |
|---|---|---|---|
| (e.g. database) | | | |
| (e.g. backend) | | | |
| (e.g. frontend) | | | |

### 6. Print final status table

```
Prerequisites    Status
──────────────── ─────────
docker           ✅ ready
colima           ✅ running  (or Docker Desktop)
gh               ✅ authenticated as <user>   (if applicable)

Service          Status     URL
──────────────── ─────────  ─────────────────────────────────────
<service-1>      ✅ UP      http://localhost:<port-1>
<service-2>      ✅ UP      http://localhost:<port-2>
<service-3>      ✅ UP      <<PRIMARY_URL>>      ← open this
```

Tell the user explicitly:

> **Open <<PRIMARY_URL>> to use the app.**

If a service failed:
```bash
docker compose logs --tail=40 <service>
```
Show the output and suggest the most likely fix based on the error.

## Guardrails

- Always run `docker compose` from `<<COMPOSE_ROOT>>`
- `down` preserves data — only a separate reset/clean skill should delete volumes
- If `mode=rebuild`, warn the user it will cause brief downtime before proceeding
- Never skip the prerequisites check — a missing dependency will break the task workflow commands
- Project-specific seed asset checks should be non-fatal but recommended before `up`
