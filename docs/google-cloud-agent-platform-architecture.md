# Google Cloud Agent Platform Architecture

PatchPilot's primary hackathon architecture uses Google Cloud Agent Builder /
Gemini Enterprise Agent Platform as the agent layer, with Cloud Run tool
backends for code execution and partner integrations.

OpenClaw is no longer the primary runtime for the hackathon plan. It can remain
as a local fallback or prototype path, but the submitted architecture should
lead with Google Cloud.

## Agent Topology

```txt
Gemini Enterprise Agent Platform / Agent Builder
├── Agent 1: patchpilot-runtime
│   ├── Telegram webhook or web/API entrypoint
│   ├── Agent Builder Extensions / custom tool calls
│   ├── Cloud Run runtime tool backend
│   ├── Elastic read query
│   ├── GitLab clone / branch / commit / MR
│   ├── Antigravity CLI coding worker
│   └── Telegram result notification
│
└── Agent 2: policy-context
    ├── Cloud Scheduler or manual admin trigger
    ├── Cloud Run ingestion backend or Agent Runtime job
    ├── Curated source registry
    ├── Official docs fetcher
    ├── Gemini extraction/classification
    ├── Elastic write/upsert
    └── Crawl audit log
```

## High-Level Flows

### Policy Context Flow

```txt
Cloud Scheduler / admin trigger
-> Agent 2: policy-context
-> Cloud Run ingestion backend
-> curated official source list
-> fetch Google / Apple / Flutter docs
-> clean content
-> Gemini summarize/classify/extract requirements and coding guidance
-> validate normalized record
-> upsert Elastic platform_policy_updates
```

### Runtime MR Flow

```txt
Telegram /check
-> Telegram webhook or API endpoint on Cloud Run
-> Agent 1: patchpilot-runtime
-> Elastic read query for platform_policy_updates
-> Cloud Run tool backend prepares GitLab workspace
-> build Antigravity coding task payload
-> Antigravity edits cloned workspace
-> Agent 1 / tool backend inspects diff
-> commit/push branch
-> create GitLab MR
-> Telegram MR link
```

## Required Technologies

| Layer | Technology | Purpose |
|---|---|---|
| Agent platform | Gemini Enterprise Agent Platform / Agent Builder | Hosts or fronts PatchPilot agents and aligns the project with the hackathon resources. |
| Custom tool backend | Cloud Run | Runs Telegram webhook, GitLab operations, Antigravity CLI execution, Elastic clients, and ingestion endpoints. |
| Tool integration | Agent Builder Extensions or custom tool APIs | Lets the managed agent call PatchPilot backend actions. |
| Agent runtime option | Agent Runtime / ADK | Code-first path for custom agent behavior if the low-code path is not enough. |
| Secrets | Secret Manager | Stores Telegram, GitLab, Elastic, Antigravity, and model-provider secrets. |
| User channel | Telegram Bot via Cloud Run webhook | Receives `/check` and sends result messages. |
| Coding worker | Antigravity CLI | Edits cloned Flutter repos using structured policy context. |
| Policy search | Elasticsearch / Elastic Agent Builder | Stores and retrieves normalized policy updates. |
| Source control | GitLab API or Git CLI | Clone repo, create branch, commit diff, create MR. |
| Policy ingestion | Cloud Run job/service, scheduler, web fetcher | Fetches curated official Google / Apple / Flutter sources. |
| AI extraction | Gemini through Agent Builder, Agent Runtime, or backend model call | Summarizes, classifies, extracts requirements, affected files, and generic coding guidance. |
| Optional persistence | MongoDB | Stores repo lists in ideal account-based mode. |
| Fallback deployment | VPS / Docker / OpenClaw | Local prototype only, not the primary hackathon architecture. |

## Tool Boundaries

| Agent | Allowed | Blocked |
|---|---|---|
| `patchpilot-runtime` | Telegram/API entrypoint, Elastic read, GitLab, Antigravity CLI through Cloud Run, workspace filesystem, diff inspection | Elastic write/upsert, policy crawling |
| `policy-context` | Curated web fetch/crawl, Gemini extraction, Elastic write/upsert, audit log | GitLab token, repo clone, Antigravity CLI, MR creation |

## Secret Boundaries

```env
# Agent 1: patchpilot-runtime
TELEGRAM_BOT_TOKEN=
GITLAB_TOKEN=
ELASTIC_READ_API_KEY=
ANTIGRAVITY_API_KEY=

# Agent 2: policy-context
ELASTIC_WRITE_API_KEY=
POLICY_CRAWL_ALLOWED_DOMAINS=

# Google Cloud
GOOGLE_CLOUD_PROJECT=
GOOGLE_CLOUD_LOCATION=
AGENT_BUILDER_AGENT_ID=
AGENT_BUILDER_DATA_STORE_ID=
CLOUD_RUN_RUNTIME_URL=
CLOUD_RUN_POLICY_INGESTION_URL=
SECRET_MANAGER_PREFIX=

# Shared
ELASTICSEARCH_URL=
ELASTICSEARCH_INDEX=platform_policy_updates
```

## Safety Rules

- Runtime checks must not crawl policy docs during `/check`.
- The policy-context agent/service must not receive GitLab credentials.
- Antigravity must edit only inside the cloned workspace path.
- The runtime agent or Cloud Run backend must inspect the diff boundary before commit.
- GitLab MR is the final output; no auto-merge.
- Secrets must live in Secret Manager or deployment environment variables, never source code.

