# PatchPilot VPS Deployment

This folder is the clean deployment profile for the hackathon PatchPilot bot.
It must not be mixed with the company-detector/OpenClaw VPS.

## Target Isolation

- Dedicated VPS name: `patchpilot-openclaw`
- Dedicated Linux user: `patchpilot`
- Dedicated app directory: `/opt/patchpilot`
- Dedicated Docker Compose project: `patchpilot`
- Dedicated OpenClaw data volume: `patchpilot_openclaw`
- Dedicated workspace volume: `patchpilot_workspace`
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

## First Deploy Flow

1. Create a fresh VPS.
2. Create or provide SSH access.
3. Run `scripts/preflight-vps.sh` to inspect the box.
4. Run `scripts/bootstrap-vps.sh` to install Docker and create the app user.
5. Copy this repository's `deploy/` directory to `/opt/patchpilot`.
6. On the VPS:

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

- `TELEGRAM_BOT_TOKEN`
- `GITLAB_TOKEN`
- `ELASTICSEARCH_URL`
- `ELASTICSEARCH_API_KEY`
- `OPENCLAW_API_KEY` or the model-provider secret selected during OpenClaw setup

Use a separate Telegram bot, separate GitLab token, and separate Elastic index
from any company-detector environment.

## Port Policy

OpenClaw should stay on localhost:

```txt
127.0.0.1:18889 -> patchpilot-openclaw:18889
```

If dashboard access is needed, use SSH tunnel:

```bash
ssh -L 18889:127.0.0.1:18889 patchpilot@<VPS_IP>
```

Do not expose the OpenClaw control UI directly to the public internet.

## Resource Policy

This Compose profile caps the OpenClaw container:

- Memory: `768m`
- CPU: `1.50`

PatchPilot should use remote services for heavy work:

- Elastic Cloud for policy search
- GitLab CI for Flutter build/test
- GitLab API for branch/commit/MR operations

## Separation Rules

- Do not reuse the company-detector VPS.
- Do not reuse `/home/nunuopc/.openclaw`.
- Do not reuse company Telegram token.
- Do not reuse company GitLab token.
- Do not expose ports `3001`, `3002`, or `18789` for PatchPilot.
- Do not run PatchPilot from the company OpenClaw gateway.
