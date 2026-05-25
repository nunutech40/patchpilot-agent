# PatchPilot Deployment

The primary hackathon deployment target is Google Cloud Agent Builder / Gemini
Enterprise Agent Platform with Cloud Run tool backends and Secret Manager.

This folder remains the clean VPS/OpenClaw fallback profile for local prototype
or emergency demo use. It must not be mixed with the company-detector/OpenClaw
VPS.

## Primary Google Cloud Deployment

Use this path for the hackathon submission:

- Agent platform: Google Cloud Agent Builder / Gemini Enterprise Agent Platform.
- Runtime tool backend: Cloud Run.
- Policy ingestion backend: Cloud Run job/service or Agent Runtime.
- Secrets: Secret Manager.
- Policy context: Elastic Cloud or managed Elasticsearch.
- Source control: GitLab.
- Coding worker: Antigravity CLI in the Cloud Run runtime backend.

Agent split:

- Agent 1, `patchpilot-runtime`: user-facing Runtime MR Agent for Telegram
  `/check`, Elastic read queries, Cloud Run tool calls, Antigravity execution,
  and GitLab MR creation.
- Agent 2, `policy-context`: internal Policy Context Agent/service for
  scheduled/manual official docs ingestion, Gemini extraction, coding guidance
  definition, and Elastic upserts.

Antigravity CLI is the coding worker invoked by the Runtime MR Agent. It
inspects cloned GitLab repositories, edits files, and runs lightweight
validation commands.

## Fallback VPS Isolation

- Dedicated VPS name: `patchpilot-openclaw`
- Dedicated Linux user: `patchpilot`
- Dedicated app directory: `/opt/patchpilot`
- Dedicated Docker Compose project: `patchpilot`
- Dedicated OpenClaw data volume: `patchpilot_openclaw`
- Dedicated workspace volume: `patchpilot_workspace`
- Dedicated OpenClaw agent definitions for `patchpilot-runtime` and `policy-context`
- Dedicated Antigravity auth/config inside the PatchPilot container or volume
- Optional dedicated policy ingestion worker for scheduled Elastic updates
- Dedicated gateway port: `18889`
- Bind gateway to localhost only: `127.0.0.1:18889`

## Server Requirements

Minimum:

- Ubuntu 24.04 LTS
- 2 vCPU
- 2 GB RAM
- 20 GB disk
- Docker Engine + Docker Compose plugin

Recommended for smoother demo:

- 2 vCPU
- 4 GB RAM
- 40 GB disk
- 1 GB swap

Do not run Elasticsearch locally on a 2 GB VPS. Use Elastic Cloud or another
managed Elasticsearch endpoint.

## Fallback VPS Deploy Flow

1. Create a fresh VPS.
2. Create or provide SSH access.
3. Run `scripts/preflight-vps.sh` to inspect the box.
4. Run `scripts/bootstrap-vps.sh` to install Docker and create the app user.
5. Confirm the official Antigravity CLI install/auth method for the hackathon account.
6. Add the Antigravity CLI install step to `Dockerfile.openclaw` or install it in a derived image.
7. Copy this repository's `deploy/` directory to `/opt/patchpilot`.
8. On the VPS:

```bash
cd /opt/patchpilot
cp .env.patchpilot.example .env
nano .env
docker compose up -d --build
docker compose ps
docker compose logs -f openclaw
```

## Secrets

Put real secrets only in `/opt/patchpilot/.env` on the VPS.

Required for MVP:

- `GOOGLE_CLOUD_PROJECT`
- `GOOGLE_CLOUD_LOCATION`
- `AGENT_BUILDER_AGENT_ID`
- `CLOUD_RUN_RUNTIME_URL`
- `CLOUD_RUN_POLICY_INGESTION_URL`
- `SECRET_MANAGER_PREFIX`
- `TELEGRAM_BOT_TOKEN`
- `GITLAB_TOKEN`
- `ELASTICSEARCH_URL`
- `ELASTIC_READ_API_KEY`
- `ELASTIC_WRITE_API_KEY`
- `GEMINI_API_KEY` or the model-provider secret selected during Google Cloud setup
- `ANTIGRAVITY_API_KEY` or the Antigravity auth method selected for the CLI

Use a separate Telegram bot, separate GitLab token, and separate Elastic index
from any company-detector environment.

The current `Dockerfile.openclaw` intentionally leaves the Antigravity CLI
install line as a TODO until the final CLI package and auth method are confirmed.

## Fallback Port Policy

Fallback OpenClaw should stay on localhost:

```txt
127.0.0.1:18889 -> patchpilot-openclaw:18889
```

If dashboard access is needed, use SSH tunnel:

```bash
ssh -L 18889:127.0.0.1:18889 patchpilot@<VPS_IP>
```

Do not expose the OpenClaw control UI directly to the public internet.

## Resource Policy

The fallback Compose profile caps the OpenClaw container:

- Memory: `768m`
- CPU: `1.50`

PatchPilot should use remote services for heavy work:

- Elastic Cloud for policy search
- Scheduled policy ingestion for official Google / Apple / Flutter docs
- GitLab CI for Flutter build/test
- GitLab API for branch/commit/MR operations
- Antigravity CLI for code changes inside cloned workspaces only
- Google Cloud Agent Builder / Cloud Run for the primary demo path

## Separation Rules

- Prefer the Google Cloud primary deployment for hackathon judging.
- Do not reuse the company-detector VPS.
- Do not reuse `/home/nunuopc/.openclaw`.
- Do not reuse company Telegram token.
- Do not reuse company GitLab token.
- Do not expose ports `3001`, `3002`, or `18789` for PatchPilot.
- Do not run PatchPilot from the company OpenClaw gateway.
- Do not let Antigravity operate outside `/workspace` or the cloned target repo.
- Do not give Agent 2, `policy-context`, a GitLab token.
- Do not give Agent 1, `patchpilot-runtime`, Elastic write/upsert credentials.
