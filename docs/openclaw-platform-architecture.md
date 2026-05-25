# OpenClaw Platform Architecture

PatchPilot runs inside one isolated OpenClaw runtime with two dedicated agents.
The split keeps user-facing GitLab automation separate from policy-context
maintenance.

## Agent Topology

```txt
OpenClaw Gateway
├── patchpilot-runtime
│   ├── Telegram /check
│   ├── Elastic read query
│   ├── GitLab clone / branch / commit / MR
│   ├── Antigravity CLI coding worker
│   └── Telegram result notification
│
└── policy-context
    ├── Scheduled/manual policy ingestion
    ├── Curated source registry
    ├── Official docs fetcher
    ├── AI extraction/classification
    ├── Elastic write/upsert
    └── Crawl audit log
```

## High-Level Flows

### Policy Context Flow

```txt
Policy Context Agent
-> curated official source list
-> fetch Google / Apple / Flutter docs
-> clean content
-> AI summarize/classify/extract requirements
-> validate normalized record
-> upsert Elastic platform_policy_updates
```

### Runtime MR Flow

```txt
Telegram /check
-> Runtime MR Agent
-> query Elastic platform_policy_updates
-> clone GitLab repo
-> build Antigravity coding task payload
-> Antigravity edits cloned workspace
-> Runtime MR Agent inspects diff
-> commit/push branch
-> create GitLab MR
-> Telegram MR link
```

## Required Technologies

| Layer | Technology | Purpose |
|---|---|---|
| Agent platform | OpenClaw Gateway | Hosts `patchpilot-runtime` and `policy-context` agents. |
| User channel | OpenClaw Telegram channel | Receives `/check` and sends result messages. |
| Coding worker | Antigravity CLI | Edits cloned Flutter repos using structured policy context. |
| Policy search | Elasticsearch / Elastic Agent Builder | Stores and retrieves normalized policy updates. |
| Source control | GitLab API or Git CLI | Clone repo, create branch, commit diff, create MR. |
| Policy ingestion | Web crawler/fetcher | Fetches curated official Google / Apple / Flutter sources. |
| AI extraction | Model provider through OpenClaw/Elastic flow | Summarizes, classifies, extracts requirements, affected files, and generic coding guidance. |
| Optional persistence | MongoDB | Stores repo lists in ideal account-based mode. |
| Runtime isolation | Docker Compose | Runs PatchPilot separately from company systems. |

## Tool Boundaries

| Agent | Allowed | Blocked |
|---|---|---|
| `patchpilot-runtime` | Telegram, Elastic read, GitLab, Antigravity CLI, workspace filesystem, git/exec | Elastic write/upsert, policy crawling |
| `policy-context` | Curated web fetch/crawl, AI extraction, Elastic write/upsert, audit log | GitLab token, repo clone, Antigravity CLI, MR creation |

## Secret Boundaries

```env
# Runtime MR Agent
TELEGRAM_BOT_TOKEN=
GITLAB_TOKEN=
ELASTIC_READ_API_KEY=
ANTIGRAVITY_API_KEY=

# Policy Context Agent
ELASTIC_WRITE_API_KEY=
POLICY_CRAWL_ALLOWED_DOMAINS=

# Shared
ELASTICSEARCH_URL=
ELASTICSEARCH_INDEX=platform_policy_updates
OPENCLAW_API_KEY=
```

## OpenClaw Agent IDs

```env
PATCHPILOT_RUNTIME_AGENT_ID=patchpilot-runtime
POLICY_CONTEXT_AGENT_ID=policy-context
```

## Safety Rules

- The runtime agent must not crawl policy docs during `/check`.
- The policy agent must not receive GitLab credentials.
- Antigravity must edit only inside the cloned workspace path.
- Runtime MR Agent must inspect the diff boundary before commit.
- GitLab MR is the final output; no auto-merge.
