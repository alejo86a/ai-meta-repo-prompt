---
description: "Generate a demo SPA that animates a microservice diagram while a real backend flow runs (chat-driven, SSE-streamed)"
tools: ['read', 'edit', 'execute', 'todo']
---

# Generate Demo Frontend

Generate a single-page demo app that:

1. Lets the user pick one of N pre-defined **flows** (sidebar).
2. Sends a chat message to a small **demo backend**.
3. The backend emits a stream of structured `step` events over SSE (Server-Sent Events) describing each architectural hop the flow takes.
4. The SPA animates those hops on a **microservice diagram** (the active node glows, the active edge flows) and renders tool calls / final reply in a chat panel.
5. The animation looks "artificial" (paced, cinematic, pretty) but every event corresponds to a **real** call the backend just made — the diagram is a faithful X-ray of what really happened.

This is the same pattern used in `projects/demo` — extracted as a reusable recipe.

## When NOT to use this skill

- The project doesn't have a backend that can emit per-hop events. (Add a thin orchestrator first.)
- The user just wants a static architecture poster. (Use a Mermaid diagram in markdown instead.)
- The microservice topology is unstable or not yet modeled. (Run the discovery phase below first; do not guess nodes.)

## Phase 0 — Understand the project BEFORE writing anything

> ⚠️ This phase is the most important one. The single most common failure mode is generating a beautiful diagram of a topology the agent invented. Do not skip.

The agent must produce, in writing, a short discovery document that the **user explicitly approves** before any code is generated. Save it under `docs/demo-discovery.md` (or wherever the project keeps design notes).

The discovery document must answer these questions, with citations to the actual repo (file paths + line numbers) wherever possible:

### 0.1 Project pitch (3 sentences max)

- What does this project do?
- Who uses it?
- What is the one capability the demo should showcase?

### 0.2 Microservice topology

List **every** node that should appear on the diagram. For each:

| Node id | Display label | Sub-label | Emoji | Where it lives in the repo |
|---|---|---|---|---|
| `user` | User | browser chat | 👤 | (always present) |
| ... | ... | ... | ... | path or "external" |

**Rules**:
- Use kebab-case, lowercase IDs. They become string literals in TypeScript.
- 4 to 8 nodes total. More than 8 → the diagram becomes unreadable; collapse some.
- External services (e.g. Anthropic API, Stripe, OpenAI) count as nodes — represent them.
- Databases count as nodes only if a flow shows the DB hop separately from the service that owns it.

### 0.3 Edges (data flows)

| Edge id | From | To | Triggered by which flows | Direction (one-way / round-trip) |
|---|---|---|---|---|
| `user-backend` | user | backend | every flow | round-trip |
| ... | ... | ... | ... | ... |

If two services talk both ways but always synchronously, model it as one edge.

### 0.4 Flows (the sidebar list)

The demo backend exposes one endpoint per flow OR one chat endpoint that internally routes by message. Pick the simpler one for this project.

For each flow, fill in:

```
id:            create-something
title:         "Create something"
emoji:         🪄
description:   one-line user-facing explanation
examplePrompt: "Make me a thing called Foo with discount 20%"
expectedTool:  create-something          # tool name the backend will report
resultHint:
  kind:        web | chat                # 'web' = the user can verify in another URL; 'chat' = the chat reply already proves it
  url:         http://localhost:3001/...  # only when kind=web
  label:       "Open the storefront"
  description: "Refresh and the new price shows up."
hops: [                                  # the ordered list of (nodeId, edgeId, description) pairs the backend will emit
  { nodeId: 'user',         edgeId: 'user-backend',     description: 'Message received: ...' },
  { nodeId: 'demo-backend', edgeId: 'backend-claude',   description: 'Backend asks the LLM which tool to use' },
  { nodeId: 'claude',       edgeId: 'backend-claude',   description: 'LLM picked tool: create-something' },
  ...
]
```

The `hops` list is the source of truth for the animation.

### 0.5 Modes

The demo runs in one of two modes — both must drive the **same** animation:

- **Real mode** — an LLM (or other "intelligent" component) actually picks the tool from the chat message. Set when its API key is in env.
- **Scripted mode** — the backend keyword-matches the user message against the flow registry and runs the same real tool. Used in air-gapped demos and local dev without API credits. The diagram animation is identical; only the chat reply differs.

The mode badge appears in the sidebar and is decided at boot from env.

### 0.6 Reset semantics (optional but recommended)

Demos accumulate state. Decide:

- What does "reset" undo? (e.g. deactivate created records, disable feature flags, clear test data)
- Which side-effect systems must be touched? (DB direct, admin APIs, etc.)

The reset endpoint is the **only** place that bypasses the normal flow path — it does direct cleanup so a fresh demo run looks fresh. Document this trade-off explicitly in the discovery doc.

### Discovery checkpoint

**Stop here.** Show the discovery doc to the user. Ask:

> "Does this match the project? Anything missing, mislabeled, or wrong direction on an edge?"

Iterate until the user approves. **Only then proceed to Phase 1.**

## Phase 1 — Generate the backend

Stack: **Node.js + Express + TypeScript** (matching the proven recipe in `projects/demo/backend`). Adapt the language if the receiving project's backend is in a different stack — but keep the SSE protocol identical.

### 1.1 Files to create

```
projects/demo/backend/
├── src/
│   ├── index.ts          ← Express bootstrap + CORS + /api/health
│   ├── chat.ts           ← /api/chat handler: real-mode + scripted-mode + SSE writer
│   ├── tools.ts          ← Tool definitions (one per flow; mirrors of the real downstream tools)
│   ├── tool-handlers.ts  ← Local fallback handlers (only used when downstream is unreachable)
│   ├── use-cases.ts      ← Flow registry consumed by the SPA sidebar
│   ├── reset.ts          ← /api/reset — direct DB / admin-API cleanup
│   └── types.ts          ← Shared event/use-case types
├── Dockerfile            ← Single-stage tsx runtime
└── package.json
```

### 1.2 SSE protocol — KEEP THIS IDENTICAL across projects

`POST /api/chat` returns `Content-Type: text/event-stream`. Each frame is one JSON event terminated by `\n\n`:

```ts
type DemoEvent =
  | { type: 'step'; step: number; total: number; nodeId: NodeId; edgeId?: EdgeId; description: string }
  | { type: 'tool_use'; toolName: string; input: Record<string, unknown> }
  | { type: 'tool_result'; toolName: string; result: string; ok: boolean }
  | { type: 'assistant_text'; text: string }
  | { type: 'error'; message: string }
  | { type: 'done' };
```

`NodeId` and `EdgeId` are string-literal unions derived from the discovery doc (Phase 0.2 / 0.3). Generate them as TypeScript types in both `backend/src/types.ts` and `frontend/src/types.ts` — they must stay in sync.

### 1.3 Step emission rules

- One `step` per architectural hop the flow takes. Never more, never fewer — the legend reads weird if hops are skipped or duplicated.
- `step` events come BEFORE the actual call they predict (animation precedes effect by ~200ms feel).
- `total` may grow during the run (the backend re-estimates once it knows which tool was picked). The frontend handles this gracefully.
- `description` is one short English sentence in present tense ("Backend forwards the call to the API").
- `tool_use` and `tool_result` are paired by `toolName`. Emit `tool_use` right after the LLM (or scripted matcher) decides on the tool.
- `assistant_text` is the final user-facing reply. Exactly one per run.
- `done` is the sentinel. Always send it last, even on error paths (after `error`).

### 1.4 Other endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/health` | GET | Boot probe; returns `{ ok, mode, ...env-derived flags, timestamp }` |
| `/api/use-cases` | GET | Returns the flow registry + current `mode` for the sidebar |
| `/api/chat` | POST | The SSE stream described above; body: `{ message: string }` |
| `/api/reset` | POST | Returns `{ ok, ...counts, errors[] }` — plain JSON, not SSE |

## Phase 2 — Generate the frontend

Stack: **React 18 + Vite + TypeScript + Tailwind + Framer Motion**. This is the recipe with the lowest friction; resist the urge to swap parts unless the user asks.

### 2.1 Files to create

```
projects/demo/frontend/
├── src/
│   ├── main.tsx
│   ├── App.tsx                              ← Layout glue (sidebar + chat panel + diagram panel)
│   ├── api.ts                               ← fetch + SSE parsing
│   ├── types.ts                             ← Shared with backend (keep in sync!)
│   ├── hooks/
│   │   └── useChat.ts                       ← Buffered playback engine
│   ├── components/
│   │   ├── Sidebar.tsx                      ← Flow list + mode pill + reset button
│   │   ├── ChatPanel.tsx                    ← Messages (user / assistant / tool / error) + composer
│   │   ├── ArchitectureDiagram.tsx          ← SVG nodes + edges + Framer Motion glows
│   │   ├── Legend.tsx                       ← Step description + result hint
│   │   └── PlaybackControls.tsx             ← Prev / Play-Pause / Next / Replay
│   └── index.css                            ← Tailwind + a few keyframes for line-flowing
├── tailwind.config.js
├── vite.config.ts                           ← proxy /api → demo-backend
└── Dockerfile                               ← multi-stage: build → vite preview at :5173
```

### 2.2 Diagram component — what makes it feel "real"

- **SVG with a fixed `viewBox`** (e.g. `760×520`) so the diagram scales but node positions stay legible.
- **Node positions are hardcoded** in a `Record<NodeId, { x, y, w, h, label, sub, emoji }>`. Lay them out logically (caller on top-left, downstream services flowing top→bottom). 4–8 nodes max.
- **Edges are pre-computed `<path d>`s** between anchor points on the node bounding boxes. Use straight lines for the obvious flows and Bezier curves only for edges that would otherwise cross other nodes.
- **Active node** glows green with a Framer Motion `scale: 1.04` and a pulsing dot. **Active edge** uses a brighter stroke + a CSS `line-flowing` keyframe (animated `stroke-dashoffset`) + a glow filter.
- **Trail**: the previous 3–4 active nodes keep a faint cyan border so the user can read the path even after the active node moves on.
- Everything else stays muted (`#22294a` borders, `#0f1424` fills).

### 2.3 Playback engine — what makes it feel "paced"

The SPA does **not** apply events as they arrive. It buffers them and reveals them on a fixed cadence:

- `step` events: revealed every **950 ms** by default
- `tool_use` / `tool_result`: revealed **220 ms** after the previous event so the chat panel doesn't fall behind the diagram
- `assistant_text`: revealed at the same 950 ms cadence so the final message lands in sync with the last step

Why: the backend executes in well under a second. Without pacing, the diagram blinks once and the user misses the whole point of the demo. With pacing, the demo reads at human speed and feels deliberate.

`PlaybackControls` lets the user pause autoplay, scrub forward / backward (events are immutable; the playhead is just an index), and replay from event 0. The diagram and chat are both derived from `events.slice(0, head + 1)`, so scrubbing back unwinds tool messages and the assistant reply along with the diagram lights — internal consistency at any playhead position.

### 2.4 Sidebar — what makes the demo "obvious"

- **Flow list**: one button per flow. Each button shows emoji + title + 1-line description. Clicking a flow:
  1. Prefills the composer with `examplePrompt`.
  2. Resets the playback state.
  3. Highlights the selected flow.
- **Mode pill**: `real` (green) when `mode === 'real'`, `scripted` (amber) when `mode === 'scripted'`.
- **Connectivity badges**: small pills showing whether the downstream services are reachable (read from `/api/health`).
- **Reset button**: calls `POST /api/reset`, shows a toast with the counts of things cleaned up. After a successful reset, also `reset()` the playback state so the next run starts fresh.

### 2.5 Result hint (the "now go look at this" moment)

After the run, the legend shows the flow's `resultHint`:

- `kind: 'web'` → render a button "Open <label>" linking to `url`. Tells the user where the side-effect is visible.
- `kind: 'chat'` → render "✅ The chat reply has the result" so the user knows nothing else needs to be checked.

This is what makes the demo land — the user sees the diagram animate, then sees the actual change in the system. Without this, the diagram looks like decoration.

## Phase 3 — Wire it into the stack

### 3.1 Compose entries

Add two services to `<<COMPOSE_FILE>>`:

```yaml
demo-backend:
  build: ./projects/demo/backend
  environment:
    # required env from discovery 0.5: API keys for real-mode, downstream URLs, etc.
  ports:
    - "4001:4000"      # host:container — pick a host port that isn't already used
  depends_on:
    - <downstream services from the discovery doc>

demo-frontend:
  build: ./projects/demo/frontend
  ports:
    - "5173:5173"
  depends_on:
    - demo-backend
```

### 3.2 Update `dev-up`

Add the two services to the health-check polling table in the project's `dev-up` skill so the user gets a green tick when the demo is ready, and tell them which URL to open at the end:

```
demo-backend     ✅ UP      http://localhost:4001/api  (mode=$DEMO_MODE)
demo-frontend    ✅ UP      http://localhost:5173      ← open this for the demo
```

### 3.3 README.md inside `projects/demo/`

Three sections:
1. **What it does** — list the flows in plain English.
2. **Running** — `docker compose up -d --build demo-backend demo-frontend`, then open http://localhost:5173.
3. **Architecture** — embed the discovery topology as a small Mermaid diagram so a reader gets the picture before opening the SPA.

## Phase 4 — Smoke test

Before reporting the skill as done, the agent must:

1. `docker compose up -d --build demo-backend demo-frontend` succeeds.
2. `curl http://localhost:4001/api/health` returns `{ ok: true, mode: ... }`.
3. `curl http://localhost:4001/api/use-cases` returns the flow registry.
4. Open `http://localhost:5173` and (using the user's browser, since the agent can't see it) confirm:
   - The sidebar shows every flow.
   - Clicking a flow prefills the composer.
   - Sending a message triggers the diagram animation and ends with an assistant reply.
   - The result hint appears and points to the right place.

If the agent cannot drive a browser, say so explicitly in the report. Do not claim success on UI behavior the agent didn't actually verify.

## Guardrails

- ❌ Do not invent nodes or edges. Every node on the diagram must correspond to a real service the backend can call.
- ❌ Do not skip Phase 0. Generating before discovery produces beautiful but wrong demos.
- ❌ Do not use stdio MCP transport here — the SPA cannot speak it. If the project has an MCP server, the demo backend is a thin HTTP orchestrator that forwards `tool_use` events to the real MCP server (Streamable HTTP transport). The MCP server itself stays untouched.
- ❌ Do not let the diagram and the actual call diverge. If you change the order of hops in `chat.ts`, update the `hops` list in `use-cases.ts` to match. The demo's value is in being a faithful X-ray.
- ✅ Keep the SSE protocol identical to the spec in section 1.2. The frontend recipe assumes those exact event shapes.
- ✅ Keep the playback cadence (950 ms / 220 ms) unless the user asks otherwise. The defaults were tuned with real audiences.
- ✅ Always offer a scripted mode. It saves the demo when the API key is missing or the room has no internet.
