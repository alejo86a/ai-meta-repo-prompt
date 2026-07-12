# export-skills

[![verify](https://github.com/alejo86a/ai-meta-repo-prompt/actions/workflows/verify.yml/badge.svg)](https://github.com/alejo86a/ai-meta-repo-prompt/actions/workflows/verify.yml)

📖 **Léelo en:** [English](README.md) · Español (este archivo)

Skills portables de Claude Code extraídas de `the-hybrids-planning-project`, listas para llevar a cualquier otro proyecto. Los nombres específicos del proyecto original (YugaStore, MCP, Unleash, YugabyteDB) se reemplazaron por `<<PLACEHOLDERS>>` que el agente receptor debe completar antes de ejecutar las skills.

## ¿Acabas de clonar este repo? Haz esto primero

```bash
# 1. Activa el hook de verificación (bloquea commits inválidos localmente)
git config core.hooksPath .githooks
```

Ese es el único paso de configuración. La red de seguridad del lado servidor (una GitHub Action que vuelve a correr los chequeos estructurales en cada push/PR) ya está cableada en `.github/workflows/verify.yml` y no necesita configuración. Para más adelante subir tus propios cambios con un token fine-grained, mira [Contribuir](#contribuir-git--token-fine-grained).

## Crea tu meta-repo (prompt de arranque óptimo)

**Dónde clonar.** Clona este repo dentro de la carpeta que ya contiene todos los proyectos que quieres mapear — los repos a estudiar deben ser **carpetas hermanas** bajo un padre común. Luego abre un agente de código (Claude Code, Copilot o cualquier CLI) **en esa carpeta padre**, no dentro de un solo proyecto.

**El prompt de arranque.** Pega esto al agente:

```text
Lee y ejecuta ai-meta-repo-prompt/onboarding-prompt.md sobre cada repositorio de esta
carpeta padre. Trátame como el aprobador: corre la Fase 0 de descubrimiento sobre todos
los repos hermanos (detecta stack, lenguajes y convenciones existentes de cada uno) y
luego —con mi consentimiento— mina los últimos 20 PRs de cada repo de GitHub y fusiónalos
con las reglas oficiales de cada lenguaje. Produce el reporte de Fase 0 y detente para mi
aprobación antes de escribir nada. El resultado final debe ser una carpeta nueva
meta-repo/ cuyo AGENTS.md sea un hub de contexto cross-repo. Nunca modifiques los
repositorios estudiados.
```

Versión corta (si el agente ya tiene este repo en contexto):

```text
Lee y ejecuta onboarding-prompt.md sobre todos los repositorios de esta carpeta y genera el meta-repo/.
```

**Dale feedback mientras corre.** No será perfecto en la primera pasada — eso es lo esperado. Cuando el reporte de descubrimiento o un archivo generado esté mal, **dile qué está mal y deja que lo corrija** (no edites el resultado a mano). El feedback es lo que ajusta el resultado a tu negocio, y mientras más lo corrijas al inicio, más afinado queda el meta-repo.

## Cuando ya existe el meta-repo — el bucle de trabajo

Una vez que apruebes el `meta-repo/` generado:

1. **Retira el creador.** Borra la carpeta clonada `ai-meta-repo-prompt/` para que no se confunda con un proyecto más. De aquí en adelante trabajas **desde el meta-repo**, cuyo `AGENTS.md` (o `CLAUDE.md`) es tu hub de contexto cross-repo.

2. **Inicia una sesión de CLI nueva para cada tarea.** Abre una sesión de agente **nueva** que cargue primero el `AGENTS.md` del meta-repo. Haz esto cada vez que cambies de tarea — una sesión de larga duración acumula contexto obsoleto y sus respuestas se degradan. Sesión fresca = contexto limpio y preciso.

3. **Corre un bucle de dos terminales programar/revisar.** Mantén **una** terminal de agente para *escribir* código y **otra separada** para *revisarlo*:
   - La Terminal A implementa el cambio.
   - La Terminal B (contexto fresco) revisa el diff contra los estándares del meta-repo.
   - Vuelves a A para atender la revisión, vuelves a B para re-revisar.
   - Itera hasta que **B apruebe** — el revisor, no el autor, es el gate.

   Separar autor y revisor en sesiones distintas evita que el modelo apruebe su propio trabajo sin criterio.

4. **Déjalo mejorar a medida que avanzas.** El meta-repo se auto-mejora: cuando el agente encuentre una regla que falta, es ambigua o está mal, señálalo y deja que proponga una actualización pequeña y aprobada de vuelta en `AGENTS.md`/`docs/`. Las correcciones se acumulan — el setup se afina mientras más construyes con él. De nuevo: **describe el error, no lo arregles en silencio por el modelo.**

## Creador de meta-repo (qué hace)

`onboarding-prompt.md` es un **creador de meta-repo agnóstico al negocio**. En la primera ejecución (toda la lógica vive en `onboarding-prompt.md`, no en el trigger):

1. **Estudia cada repo de la carpeta padre** — 2, 5, 10, los que sean — detectando stack, lenguajes y convenciones existentes.
2. **Mina los últimos 20 PRs por repo** vía `gh` (con consentimiento, solo GitHub, best-effort; pide un token fine-grained guardado bajo un `.env/` git-ignored si hace falta) para aprender los hábitos de review reales y aplicados del equipo.
3. **Descarga reglas oficiales de cada lenguaje** desde documentación autorizada (Node.js, MDN, TypeScript, Oracle Java, PEP 8, Go, Kotlin…) y las **fusiona** con las prácticas minadas en un estándar específico del negocio.
4. **Genera una carpeta nueva `meta-repo/`** cuyo `AGENTS.md` es un hub de contexto cross-repo. Apunta Copilot o un agente de terminal a él (por ejemplo, cópialo a `.github/copilot-instructions.md`) y preguntar/editar sobre el conjunto de repos se vuelve más rápido y preciso.
5. **Es borrable** después (elimina el creador para que no se confunda con un repo del proyecto) y **auto-mejorable** (cualquier skill posterior que detecte desviaciones propone una actualización aprobada de vuelta al meta-repo).

Los repositorios estudiados nunca se modifican.

## Verificar cambios a este repo (pre-commit)

Cada cambio a `ai-meta-repo-prompt` debe sobrevivir la misma batería exigente que se usó para diseñarlo. Esto se aplica con un git hook más un prompt de agente.

Instala el hook una vez por clon:

```bash
git config core.hooksPath .githooks
```

En cada `git commit` el hook (`.githooks/pre-commit`) corre el **Gate 0** — chequeos rápidos, deterministas y offline (anclas requeridas del prompt, árbol de salida `meta-repo/`, `.env/` git-ignored, sin literales de token en staging, sin referencias rotas a `skills/*.md`) y bloquea el commit si alguno falla.

Para los gates profundos (**revisión adversarial del diff + sandbox real end-to-end**: clonar 3 repos reales, correr los pasos 5A/5B/5C, generar un `meta-repo/` desechable y hacer teardown), corre el prompt de agente `skills/verify-meta-repo.md` — pégalo a tu agente de código en la raíz del repo. Cuando imprima `VERIFICATION PASSED`, reconoce y haz commit:

```bash
VERIFY_AGENT_DONE=1 git commit -m "…"
```

Bypass de emergencia (desaconsejado): `git commit --no-verify`.

**Red del lado servidor:** `.github/workflows/verify.yml` vuelve a correr el Gate 0 en cada push y pull request (`GATE0_ONLY=1 bash .githooks/pre-commit`), así que las regresiones estructurales se atrapan aunque alguien commitee con `--no-verify`. En CI el escaneo de tokens se amplía a todos los archivos versionados, no solo al contenido en staging.

## Qué trae la caja

| Skill | Propósito |
|---|---|
| `skills/start-task.md` | Elegir una tarea del tracker, verificar el límite de WIP, ramificar desde la rama por defecto, forzar un plan socrático antes de escribir código |
| `skills/complete-task.md` | Correr un checklist de Definition-of-Done, mover el issue a `review` |
| `skills/commit-and-push.md` | Validar el diff contra el contexto de la rama, generar un commit `[TASK-XXX]`, hacer push y abrir un PR con criterios de aceptación enlazados |
| `skills/dev-up.md` | Levantar el stack local de Docker Compose con chequeos de prerrequisitos y sondas de salud por servicio |
| `skills/generate-demo-frontend.md` | Generar una SPA demo que anima un diagrama de microservicios mientras corre un flujo real de backend (chat + SSE) |
| `skills/verify-meta-repo.md` | Batería de agente pre-commit — revisión adversarial del diff + prueba sandbox real end-to-end, para cada cambio a este repo |

## Cómo usarlas en otro proyecto

### 1. Copia los archivos

```bash
mkdir -p .claude/commands   # Claude Code lee los slash commands desde aquí
cp export-skills/skills/*.md .claude/commands/
```

(Algunas configuraciones de Claude Code leen desde `.claude/skills/` — revisa la estructura del proyecto receptor y elige el destino correcto.)

### 2. Completa los placeholders

Cada skill empieza con una tabla de "Adapter note". Busca `<<` en cada archivo y reemplaza cada ocurrencia con el valor del proyecto receptor. Los más comunes:

| Placeholder | Valor probable |
|---|---|
| `<<TASK_PREFIX>>` | `TASK`, `JIRA-`, `TICKET` (lo que use tu tracker en los títulos) |
| `<<TASK_REGEX>>` | El regex de CI que fuerza el prefijo (ej. `^\[TASK-[0-9]+\]`) |
| `<<DEFAULT_BRANCH>>` | `main`, `master`, `trunk` |
| `<<ISSUE_TRACKER>>` | `gh`, `jira`, `linear`, `none` |
| `<<COMPOSE_FILE>>` | Ruta a tu `docker-compose.yml` |
| `<<SERVICES>>` | La tabla de health-check de servicios |
| `<<PRIMARY_URL>>` | La URL que el usuario debe abrir al final de `/dev-up` |
| `<<DOCS_FILE>>` | El archivo único que bootstrapea a un agente nuevo (ej. `CLAUDE.md`, `AGENTS.md`) |

Si el proyecto receptor usa Jira/Linear en vez de GitHub Issues, reemplaza cada bloque `gh issue ...` con el CLI equivalente del tracker elegido. La estructura de la skill (cuándo actualizar estado, qué campos leer) se mantiene igual.

### 3. Adapta las partes específicas del proyecto

Algunas secciones de cada skill piden contexto del proyecto que el código fuente no puede inferir. Busca estos marcadores:

- `start-task.md` paso 10 — tabla fase → lista de lectura → agente recomendado
- `complete-task.md` — `<<ARCH_INVARIANT>>` (una frase que describe tu regla arquitectónica)
- `dev-up.md` paso 5 — la tabla de health-check por servicio
- `generate-demo-frontend.md` Fase 0 — el documento de descubrimiento completo

El agente del proyecto receptor puede correr la skill una vez y pedirle al usuario que complete estos datos, luego commitea la versión personalizada resultante.

### 4. (Opcional) Conéctalas como slash commands

Si el host usa Claude Code, no se necesita configuración extra — los archivos en `.claude/commands/` se vuelven `/start-task`, `/complete-task`, etc. automáticamente.

Para otros runtimes de agente, registra cada archivo `.md` como herramienta / prompt según la convención de ese runtime.

## Contribuir (Git + token fine-grained)

Este repositorio se puede subir con un token fine-grained (PAT) de GitHub.

### Configuración local por única vez (solo la primera vez)

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/alejo86a/ai-meta-repo-prompt.git
```

Si `origin` ya existe, actualízalo en vez de agregarlo de nuevo:

```bash
git remote set-url origin https://github.com/alejo86a/ai-meta-repo-prompt.git
```

### Crear un token fine-grained (requerido)

En GitHub: **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.

Usa esta configuración:

- **Resource owner:** `alejo86a`
- **Repository access:** **Only select repositories** → selecciona `ai-meta-repo-prompt`
- **Repository permissions:**
	- **Contents:** `Read and write` (requerido para `git push`)
	- **Metadata:** `Read-only` (normalmente se activa solo)
	- **Workflows:** `Read and write` (requerido para subir cambios bajo `.github/workflows/`, ej. `verify.yml`)
	- **Pull requests:** `Read and write` (opcional, útil para flujos de PR)

Sin **Repository access** apuntando a este repo y **Contents = Read and write**, los push fallan con `403`.

### Push usando token

Usa un placeholder y reemplázalo localmente:

```bash
git push -u "https://x-access-token:INSERTA_AQUI_TU_TOKEN@github.com/alejo86a/ai-meta-repo-prompt.git" main
```

Alternativa más segura (no deja el token en el historial del shell):

```bash
read -s GH_TOKEN
git push -u "https://x-access-token:${GH_TOKEN}@github.com/alejo86a/ai-meta-repo-prompt.git" main
unset GH_TOKEN
```

### Errores comunes

- `403 Write access to repository not granted`: el token existe, pero no tiene `Contents: Read and write` y/o el repo access no apunta a `ai-meta-repo-prompt`.
- `refusing to allow a Personal Access Token to create or update workflow ... without workflow scope`: al token le falta el permiso **Workflows: Read and write**. Agrégalo al token fine-grained y vuelve a hacer push.
- `404 Repository not found`: URL de owner/repo incorrecta, o el token no puede ver ese repositorio.

## Generar la SPA demo

`generate-demo-frontend.md` es la excepción — no es un comando de flujo; es un generador. Se corre una vez por proyecto. Flujo:

1. El agente lee `generate-demo-frontend.md`.
2. **Fase 0 (descubrimiento)** — el agente produce un documento escrito de descubrimiento listando cada nodo, arista y flujo. El usuario revisa y aprueba. **Aún no se escribe código.**
3. **Fase 1 (backend)** — el agente genera el backend demo (Node/Express + SSE).
4. **Fase 2 (frontend)** — el agente genera la SPA de React con el diagrama SVG animado y el motor de reproducción.
5. **Fase 3 (compose)** — el agente conecta los dos servicios nuevos al `docker-compose.yml` del proyecto y actualiza `/dev-up` para sondear su salud.
6. **Fase 4 (smoke test)** — el agente arranca la demo y verifica `/api/health`, `/api/use-cases` y `/api/chat`.

El protocolo entre backend y frontend (formas de eventos SSE, cadencias de reproducción) es fijo entre proyectos — solo cambian la topología y los flujos. Eso mantiene la receta reutilizable.

## Qué NO trae la caja a propósito

- Las skills `kanban`, `standup`, `dev-logs`, `dev-reset`, `new-task` — mantenlas locales al proyecto; están demasiado atadas a convenciones de labels de GitHub Issues o son demasiado delgadas para valer la pena generalizarlas.
- Las definiciones de subagentes (`.claude/agents/*.md`) — referencian stacks específicos del proyecto (TypeScript MCP, YugabyteDB, Unleash) y no generalizan limpiamente. Define los agentes del proyecto receptor desde cero.
- El código real de la SPA demo — `generate-demo-frontend.md` es la receta; genera el código bajo demanda contra la topología del proyecto receptor.

## Chequeo de sanidad antes de entregar

Antes de dárselas a otro agente, busca restos del proyecto original:

```bash
grep -RIn -E "yugastore|mcp-server|unleash|yugabytedb|los híbridos|hybrids" export-skills/ || echo "clean"
```

La salida debe ser `clean`. Si no lo es, esas referencias se filtraron y hay que convertirlas en placeholders.
