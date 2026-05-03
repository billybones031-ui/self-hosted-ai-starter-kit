# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

A Docker Compose template for spinning up a local, privacy-first AI workflow environment. There is no application code to build or test — all changes are to Docker Compose configuration, environment setup, and n8n demo data (credentials + workflows as JSON).

## Starting the Stack

Always copy `.env.example` to `.env` before first run. The `.env` file is gitignored and required.

```bash
cp .env.example .env
```

Then start with the appropriate profile for the host hardware:

```bash
# CPU only
docker compose --profile cpu up

# Nvidia GPU
docker compose --profile gpu-nvidia up

# AMD GPU (Linux)
docker compose --profile gpu-amd up

# Mac / Apple Silicon (Ollama in Docker, no GPU passthrough)
docker compose up
```

## Upgrading

```bash
# Example for CPU profile — swap profile name as needed
docker compose --profile cpu pull
docker compose create && docker compose --profile cpu up
```

## Architecture

The entire stack is defined in `docker-compose.yml` using YAML anchors to avoid repetition:

- `&service-n8n` — shared n8n config (image, env, network)
- `&service-ollama` — shared Ollama config (image, volumes, ports)
- `&init-ollama` — one-shot init container that pulls `llama3.2` from the running Ollama service

**Services:**

| Service | Port | Role |
|---|---|---|
| `n8n` | 5678 | Workflow UI and engine |
| `postgres` | — (internal) | n8n's backing database |
| `n8n-import` | — | One-shot seeder; imports demo credentials and workflows on first run only |
| `ollama-{cpu,gpu,gpu-amd}` | 11434 | LLM inference; only one starts depending on the active profile |
| `ollama-pull-llama-{cpu,gpu,gpu-amd}` | — | One-shot init; pulls `llama3.2` after Ollama is ready |
| `qdrant` | 6333 | Vector store |

All services share a single Docker network named `demo`.

**Startup ordering:** `postgres` (healthcheck) → `n8n-import` (completes successfully) → `n8n`.

**n8n-import idempotency:** The import service checks `n8n list:workflow --onlyId` before importing, so it skips the import if workflows already exist. This prevents overwriting user data on restart.

**Mac / local Ollama:** When Ollama runs on the Mac host instead of in Docker, set `OLLAMA_HOST=host.docker.internal:11434` in `.env` and update the "Local Ollama service" credential URL in the n8n UI.

## Demo Data

`n8n/demo-data/` contains the pre-seeded data imported by `n8n-import`:

- `credentials/` — encrypted credential blobs for the Qdrant API and local Ollama service
- `workflows/srOnR8PAY3u4RSwb.json` — the demo workflow: Chat Trigger → Basic LLM Chain → Ollama Chat Model (llama3.2)

When modifying or adding demo workflows/credentials, export them from n8n as JSON and place them in the appropriate subdirectory. The import command uses `--separate`, so each file must be a single object (not an array).

## Local File Access

n8n can read/write host files via the shared volume mounted at `/data/shared` inside the container (maps to `./shared/` in the repo root). Use this path in n8n nodes like "Read/Write Files from Disk" or "Execute Command".

## Contribution Scope

Per `CONTRIBUTING.md`, this project is intentionally minimal. Do **not** add:

- Reverse proxies, SSL/TLS, load balancers, or monitoring
- Alternative tech stacks (different vector DBs, different workflow engines, etc.)
- Enterprise features (auth systems, multi-tenancy, access controls)
- Advanced networking or multi-environment setups

PRs must be focused on a single feature or fix. The guiding principle is: **fastest path from zero to working local AI workflows**, not a production-grade platform.
