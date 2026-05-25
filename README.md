# PatchPilot Agent

PatchPilot is an AI agent that turns mobile platform policy updates into GitLab Merge Requests for Flutter teams.

The MVP flow is intentionally simple: a developer sends one or more GitLab Flutter repository URLs to a Telegram bot, PatchPilot checks indexed Google / Apple / Flutter policy context through Elastic, then Antigravity CLI acts as the coding worker that updates the repository and prepares a GitLab Merge Request for human review.

PatchPilot never auto-merges code.

## What It Does

- Accepts GitLab repository URLs through Telegram.
- Uses Elastic as the platform-policy context layer.
- Lets OpenClaw orchestrate the agent workflow.
- Uses Antigravity CLI as the dedicated coding agent for repository inspection, edits, and validation.
- Inspects Flutter native project files such as Android Gradle config, manifests, Podfiles, and iOS plist files.
- Creates a branch, commits safe native-compliance changes, and opens a GitLab Merge Request.
- Sends the MR result back to the developer.

## MVP Architecture

```txt
Flutter Developer
  -> Telegram Bot
  -> OpenClaw / AI Platform
  -> Elastic Context Layer
  -> Antigravity CLI Coding Worker
  -> GitLab Branch + Merge Request
  -> Human Reviewer
```

The final output is a GitLab Merge Request reviewed by a human, not an automatic merge.

## Main Stack

| Area | Tool |
|---|---|
| Agent orchestration | OpenClaw |
| Coding worker | Antigravity CLI |
| User input | Telegram Bot |
| Policy context | Elastic / Elasticsearch |
| Source control | GitLab |
| Target repositories | Flutter apps |
| Optional persistence | MongoDB, ideal mode only |

## Product Modes

### Telegram MVP

The hackathon/demo mode does not use MongoDB. The repository list is submitted at runtime through Telegram:

```txt
/check
https://gitlab.com/company/flutter-app-1
https://gitlab.com/company/flutter-app-2
```

### Ideal Account Mode

The scalable version stores repository lists per user account in MongoDB, then supports future scheduled checks and scan history.

## Repository Docs

Start here:

| Document | Purpose |
|---|---|
| [BUILDING_PLAN.md](BUILDING_PLAN.md) | Step-by-step implementation plan, phases, checklist, and hackathon path. |
| [PRD_AI_Native_Compliance_Automation_Refactored.md](PRD_AI_Native_Compliance_Automation_Refactored.md) | Product requirements, users, goals, flows, success metrics, and risks. |
| [TRD_AI_Native_Compliance_Automation_Refactored.md](TRD_AI_Native_Compliance_Automation_Refactored.md) | Technical requirements, architecture, data models, command design, and integration details. |
| [deploy/README.md](deploy/README.md) | Docker-first VPS deployment plan for PatchPilot. |
| [.env.example](.env.example) | Local/runtime environment variable template. |
| [deploy/.env.patchpilot.example](deploy/.env.patchpilot.example) | VPS-specific environment template. |

External architecture references:

| Reference | Purpose |
|---|---|
| [Antigravity CLI overview](https://antigravity.google/docs/cli-overview) | Coding-worker surface used by PatchPilot. |
| [Antigravity CLI features](https://antigravity.google/docs/cli-features) | Subagents, tools, approvals, and coding workflow capabilities. |
| [OpenClaw tools](https://docs.openclaw.ai/tools) | Orchestration tools, skills, runtime, messaging, and session capabilities. |

Reference document exports:

| File | Notes |
|---|---|
| [PRD_AI_Native_Compliance_Automation_Refactored.docx](PRD_AI_Native_Compliance_Automation_Refactored.docx) | Word export of the PRD. |
| [TRD_AI_Native_Compliance_Automation_Refactored.docx](TRD_AI_Native_Compliance_Automation_Refactored.docx) | Word export of the TRD. |

Deployment helpers:

| Script | Purpose |
|---|---|
| [scripts/preflight-vps.sh](scripts/preflight-vps.sh) | Checks OS, disk, RAM, ports, Docker, firewall, and reboot status on a fresh VPS. |
| [scripts/bootstrap-vps.sh](scripts/bootstrap-vps.sh) | Installs Docker, creates the `patchpilot` user, prepares `/opt/patchpilot`, and enables basic firewall rules. |

## Deployment Rule

PatchPilot must run in its own VPS or isolated Docker environment.

Do not deploy PatchPilot into an existing company OpenClaw runtime. Keep these separate:

- VPS
- Linux user
- Docker Compose project
- Docker network
- Docker volumes
- OpenClaw gateway port
- Antigravity CLI auth/config
- Telegram bot token
- GitLab token
- Elastic index and API key

Recommended target:

```txt
VPS name: patchpilot-openclaw
Linux user: patchpilot
App dir: /opt/patchpilot
Gateway: 127.0.0.1:18889
Compose project: patchpilot
```

## Fresh VPS Flow

After a new Linux VPS and SSH access are available:

```bash
./scripts/preflight-vps.sh
sudo ./scripts/bootstrap-vps.sh
```

Then copy the deployment files to the VPS:

```bash
cd /opt/patchpilot
cp .env.patchpilot.example .env
# Fill real secrets in .env on the VPS only.
docker compose up -d --build
docker compose ps
```

See [deploy/README.md](deploy/README.md) for the full deployment notes.

## Required Secrets

Never commit real secrets. Use `.env.example` only for documentation.

Required for MVP:

```env
TELEGRAM_BOT_TOKEN=
GITLAB_TOKEN=
ELASTICSEARCH_URL=
ELASTICSEARCH_API_KEY=
OPENCLAW_API_KEY=
ANTIGRAVITY_API_KEY=
```

Optional for ideal mode:

```env
MONGODB_URI=
```

## Safety Principles

- Human review is always required before merge.
- Antigravity should make minimal code changes inside the cloned repository workspace only.
- Elastic policy source URLs should be included in MR descriptions.
- Secrets must stay in runtime environment variables.
- PatchPilot should not run heavy Elasticsearch or Flutter builds on a small VPS.
- GitLab CI should handle heavier validation when possible.

## Current Status

This repository currently contains planning docs and deployment preparation for the MVP. The next implementation steps are:

1. Build the Telegram `/check` command handler.
2. Configure Elastic policy index and query flow.
3. Implement the OpenClaw PatchPilot orchestrator skill.
4. Integrate Antigravity CLI as the coding worker.
5. Implement GitLab read, branch, commit, and MR creation.
6. Deploy to a fresh VPS using the Docker-first plan.
