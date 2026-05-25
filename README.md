# PatchPilot Agent

PatchPilot is an AI agent that turns mobile platform policy updates into GitLab Merge Requests for Flutter teams.

The MVP flow is intentionally simple: a developer sends one or more GitLab
Flutter repository URLs to a Telegram bot, the PatchPilot Runtime Agent on
Google Cloud checks indexed Google / Apple / Flutter policy context through
Elastic, then Antigravity CLI acts as the coding worker that updates the
repository and prepares a GitLab Merge Request for human review.

PatchPilot never auto-merges code.

## What It Does

- Accepts GitLab repository URLs through Telegram.
- Uses Elastic as the platform-policy context layer.
- Uses Google Cloud Agent Builder / Gemini Enterprise Agent Platform as the
  primary hackathon agent platform.
- Uses Cloud Run tool backends for Telegram webhook handling, GitLab operations,
  Antigravity execution, and policy ingestion.
- Uses two bounded agents/services:
  - PatchPilot Runtime Agent for Telegram `/check`, Antigravity, GitLab, and MR creation.
  - Policy Context Agent for scheduled/manual crawl, extraction, and Elastic indexing.
- Uses Antigravity CLI as the dedicated coding agent for repository inspection, edits, and validation.
- Inspects Flutter native project files such as Android Gradle config, manifests, Podfiles, and iOS plist files.
- Creates a branch, commits safe native-compliance changes, and opens a GitLab Merge Request.
- Sends the MR result back to the developer.

## MVP Architecture

```txt
Flutter Developer
  -> Telegram Bot
  -> Agent 1: patchpilot-runtime / Runtime MR Agent
  -> Cloud Run Tool Backend
  -> Elastic Context Layer
  -> Antigravity CLI Coding Worker
  -> GitLab Branch + Merge Request
  -> Human Reviewer
```

The final output is a GitLab Merge Request reviewed by a human, not an automatic merge.

## Two-Agent Split

| Agent | ID | Owns | Must Not Do |
|---|---|---|---|
| Agent 1 | `patchpilot-runtime` | Telegram `/check`, Elastic read/query, Cloud Run tool calls, GitLab workspace/branch/commit/MR, Antigravity CLI invocation, Telegram result | Crawl policy docs, write Elastic policy records |
| Agent 2 | `policy-context` | Scheduled/manual policy crawl, curated Google / Apple / Flutter source fetch, Gemini extraction, coding guidance definition, Elastic write/upsert, crawl audit | Clone user repos, use GitLab token, invoke Antigravity, create MRs |

Elastic is the handoff point. Agent 2 writes normalized policy records and
generic coding guidance into Elastic. Agent 1 reads those records during
`/check`, adds repo-specific facts, and sends a concrete coding task to
Antigravity.

## Main Stack

| Area | Tool |
|---|---|
| Agent platform | Google Cloud Agent Builder / Gemini Enterprise Agent Platform |
| Runtime user-facing agent | PatchPilot Runtime MR Agent |
| Background context agent | Policy Context Agent |
| Tool backend | Cloud Run |
| Secrets | Secret Manager |
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
| [docs/google-cloud-hackathon-resources.md](docs/google-cloud-hackathon-resources.md) | Devpost and Google Cloud resource map used by the hackathon plan. |
| [docs/google-cloud-agent-platform-architecture.md](docs/google-cloud-agent-platform-architecture.md) | Primary Google Cloud Agent Builder architecture, high-level flows, technology stack, and tool boundaries. |
| [docs/openclaw-platform-architecture.md](docs/openclaw-platform-architecture.md) | Legacy/local OpenClaw fallback notes. |
| [docs/policy-crawl-plan.md](docs/policy-crawl-plan.md) | Curated official sources to crawl and how Elastic should normalize policy context. |
| [deploy/README.md](deploy/README.md) | Docker-first VPS deployment plan for PatchPilot. |
| [diagrams/sequence-policy-ingestion.md](diagrams/sequence-policy-ingestion.md) | Background policy crawl/index flow, separate from repo checks. |
| [diagrams/sequence-elastic-context-to-coding-agent.md](diagrams/sequence-elastic-context-to-coding-agent.md) | How indexed Elastic records become the Antigravity coding task payload. |
| [diagrams/sequence-telegram-mvp.md](diagrams/sequence-telegram-mvp.md) | Telegram MVP sequence diagram with Antigravity as coding worker. |
| [diagrams/sequence-ideal-mongodb.md](diagrams/sequence-ideal-mongodb.md) | Ideal MongoDB sequence diagram with Antigravity as coding worker. |
| [.env.example](.env.example) | Local/runtime environment variable template. |
| [deploy/.env.patchpilot.example](deploy/.env.patchpilot.example) | VPS-specific environment template. |

External architecture references:

| Reference | Purpose |
|---|---|
| [Google Cloud Rapid Agent Hackathon resources](https://rapid-agent.devpost.com/resources) | Official hackathon resource page. |
| [Gemini Enterprise Agent Platform](https://cloud.google.com/products/gemini-enterprise-agent-platform) | Primary agent platform for the hackathon architecture. |
| [Gemini Enterprise agents overview](https://docs.cloud.google.com/gemini/enterprise/docs/agents-overview) | Agent Designer, ADK agents, A2A agents, and agent management. |
| [Agent Platform Runtime / Scale agents](https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale) | Managed runtime, deployment, access, tracing, logging, and supported agent frameworks. |
| [Cloud Run](https://cloud.google.com/run) | Custom tool backend hosting. |
| [Secret Manager](https://cloud.google.com/security/products/secret-manager) | Runtime secret storage. |
| [Antigravity CLI overview](https://antigravity.google/docs/cli-overview) | Coding-worker surface used by PatchPilot. |
| [Antigravity CLI features](https://antigravity.google/docs/cli-features) | Subagents, tools, approvals, and coding workflow capabilities. |

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

PatchPilot's primary hackathon deployment should run on Google Cloud:

- Agent Builder / Gemini Enterprise Agent Platform for the agent layer.
- Cloud Run for Telegram webhook, GitLab/Antigravity tool backend, and policy ingestion.
- Secret Manager for runtime secrets.
- Elastic Cloud or managed Elasticsearch for policy context.

The existing VPS/Docker/OpenClaw path is now a fallback or local prototype path.
Do not deploy PatchPilot into an existing company OpenClaw runtime. Keep these separate:

- VPS
- Linux user
- Docker Compose project
- Docker network
- Docker volumes
- OpenClaw gateway port
- OpenClaw agent definitions and tool allowlists
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

## Fallback Fresh VPS Flow

Only use this path for local fallback/prototype deployment. After a new Linux
VPS and SSH access are available:

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
GOOGLE_CLOUD_PROJECT=
GOOGLE_CLOUD_LOCATION=
AGENT_BUILDER_AGENT_ID=
CLOUD_RUN_RUNTIME_URL=
CLOUD_RUN_POLICY_INGESTION_URL=
SECRET_MANAGER_PREFIX=
TELEGRAM_BOT_TOKEN=
GITLAB_TOKEN=
ELASTICSEARCH_URL=
ELASTIC_READ_API_KEY=
ELASTIC_WRITE_API_KEY=
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
- Secrets must stay in Secret Manager or runtime environment variables and be scoped by agent role.
- Runtime MR Agent should have Elastic read access, GitLab access, Telegram access, and Antigravity access.
- Policy Context Agent should have Elastic write/upsert access and no GitLab token.
- PatchPilot should not run heavy Elasticsearch or Flutter builds on a small VPS.
- GitLab CI should handle heavier validation when possible.

## Current Status

This repository currently contains planning docs and deployment preparation for the MVP. The next implementation steps are:

1. Build the Telegram `/check` command handler.
2. Configure Elastic policy index and query flow.
3. Implement Agent 2, `policy-context`, for scheduled/manual Elastic ingestion.
4. Implement Agent 1, `patchpilot-runtime`, for Telegram `/check`.
5. Integrate Antigravity CLI as the coding worker.
6. Implement GitLab read, branch, commit, and MR creation.
7. Deploy the primary demo path on Google Cloud, with VPS/Docker kept as fallback only.
