# TRD - AI Native Compliance Automation for Flutter Repositories

**Version:** 2.0  
**Date:** 2026-05-23  
**Primary implementation:** Google Cloud Agent Builder / Gemini Enterprise Agent Platform Telegram MVP without MongoDB
**Scalable implementation:** Account-based mode with MongoDB

## 1. Technical summary

The system uses Google Cloud Agent Builder / Gemini Enterprise Agent Platform
as the primary hackathon agent platform, with Cloud Run as the custom tool
backend and Secret Manager for credentials. The PatchPilot Runtime MR Agent is
user-facing through Telegram and creates GitLab Merge Requests. The Policy
Context Agent is internal/background and maintains Elastic policy context.
Antigravity CLI is the coding worker invoked only by the Runtime MR Agent
through the Cloud Run backend. Elastic is the platform-policy context layer, and
GitLab is the source-code and Merge Request system. The hackathon MVP avoids
MongoDB by receiving repo URLs directly through Telegram and processing them as
runtime input. The ideal mode adds MongoDB to persist repository lists by user
account.

## 2. Architecture principles

For a concise platform view, see
[`docs/google-cloud-agent-platform-architecture.md`](docs/google-cloud-agent-platform-architecture.md).

1. **Google Cloud primary architecture.** Agent Builder / Gemini Enterprise Agent Platform is the primary agent layer; Cloud Run hosts the custom tool backend.
2. **Elastic owns policy context.** Google / Apple / Flutter docs are crawled/fetched by the Policy Context Agent and indexed in Elasticsearch.
3. **Runtime MR Agent orchestrates repo remediation.** It receives Telegram messages, calls Cloud Run tools, queries Elastic read-only, invokes Antigravity CLI, inspects the diff, and creates the GitLab MR.
4. **Policy Context Agent maintains Elastic.** It fetches curated official sources, uses AI for extraction/classification, validates records, and upserts Elastic.
5. **Antigravity CLI Coding Worker owns repository edits.** It reads repo files and generates code changes inside a cloned workspace; Runtime MR Agent handles branch, commit, push, and MR creation.
6. **GitLab owns source control and review.** Output is GitLab Merge Request, never direct merge.
7. **Secrets stay outside source code.** Tokens and API keys are split by agent role and stored as environment/runtime secrets.

## 3. Sequence diagrams

### 3.0 Google Cloud platform architecture - two-agent runtime

```txt
Gemini Enterprise Agent Platform / Agent Builder
├── Agent 1: PatchPilot Runtime MR Agent
│   ├── Telegram webhook/API entrypoint
│   ├── Agent Builder Extensions / custom tool calls
│   ├── Cloud Run runtime tool backend
│   ├── Elastic read/query
│   ├── GitLab clone/API operations
│   ├── Antigravity CLI execution
│   └── GitLab MR notification flow
│
└── Agent 2: Policy Context Agent
    ├── Cloud Scheduler/manual crawl trigger
    ├── Cloud Run ingestion backend or Agent Runtime job
    ├── Curated source registry
    ├── Policy fetcher / cleaner
    ├── Gemini extraction/classification
    ├── Elastic write/upsert tool
    └── Crawl audit log
```

Agent separation:

| Agent | Trigger | Responsibilities | Allowed secrets/tools | Must not do |
|---|---|---|---|---|
| PatchPilot Runtime MR Agent | Telegram `/check`, future dashboard/API scan | Query Elastic, call Cloud Run tools, clone repo, build Antigravity payload, invoke Antigravity, inspect diff, create MR, notify Telegram | Telegram token, GitLab token, Elastic read key, Antigravity auth, Cloud Run runtime backend, Secret Manager | Crawl policy docs, write Elastic policy records |
| Policy Context Agent | Schedule, manual admin trigger | Crawl official sources, clean text, extract/classify requirements, validate records, upsert Elastic, write audit logs | Elastic write key, curated source registry, web fetch/crawler, Gemini extraction model, Cloud Run ingestion backend | Clone user repos, invoke Antigravity, create GitLab MRs |

### 3.1 Policy ingestion - scheduled crawl to Elastic

This flow is separate from Telegram `/check`. It crawls curated official
Google / Apple / Flutter sources, uses AI only for extraction/classification,
validates the normalized record, and stores it in Elastic.

[Standalone diagram](diagrams/sequence-policy-ingestion.md)

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Admin / Cloud Scheduler
    participant Ingest as Agent 2: policy-context
    participant Backend as Cloud Run Ingestion Backend
    participant Registry as Curated Source Registry
    participant Fetcher as Policy Fetcher
    participant Docs as Official Policy Sources
    participant Cleaner as Content Cleaner
    participant AI as Extraction / Classification AI
    participant Validator as Record Validator
    participant Elastic as Elastic Index
    participant Audit as Crawl Audit Log

    Admin->>Ingest: Trigger scheduled or manual crawl
    Ingest->>Backend: Start ingestion job
    Backend->>Registry: Load curated Google / Apple / Flutter source list
    Registry->>Fetcher: Send source URL, platform, source type, crawl priority
    Fetcher->>Docs: Fetch official policy / release / changelog page
    Docs->>Fetcher: Return HTML, metadata, and last-modified hints
    Fetcher->>Cleaner: Send raw content
    Cleaner->>Cleaner: Extract readable text, headings, links, dates, checksums
    Cleaner->>AI: Send cleaned text + source metadata
    AI->>AI: Summarize, classify, extract requirements, affected files, and coding guidance
    AI->>Validator: Return normalized update candidate with recommended action
    Validator->>Validator: Check required fields, source URL, confidence, dates
    Validator->>Elastic: Upsert validated policy_update record
    Validator->>Audit: Store crawl timestamp, source URL, checksum, result

    alt Source changed or new requirement found
        Validator->>Elastic: Mark record active and searchable
    else No meaningful change
        Validator->>Audit: Record no-op crawl result
    end
```

### 3.2 Ideal mode - with MongoDB repository persistence

[Standalone diagram](diagrams/sequence-ideal-mongodb.md)

```mermaid
sequenceDiagram
    autonumber
    box Human Area
        actor Dev as Flutter Developer
        actor Reviewer as Human Reviewer
    end
    box AI Platform Area
        participant AgentBuilder as Agent Builder: patchpilot-runtime
        participant Backend as Cloud Run Tool Backend
        participant Agent as Antigravity CLI Coding Worker
    end
    box Elastic Context Layer
        participant Elastic as Elastic Index + Agent Builder
    end
    box Data Storage Area
        participant Mongo as MongoDB
    end
    box GitLab Area
        participant Repo as GitLab Repository
        participant MR as GitLab Merge Request
    end
    box Secret / Runtime Config
        participant Secrets as Secret Manager
    end

    Dev->>Repo: Maintains Flutter repository
    Dev->>AgentBuilder: Input GitLab repository list
    AgentBuilder->>Backend: Request repository registration/check
    Backend->>Secrets: Read MongoDB URI / GitLab token / Elastic key
    Backend->>Mongo: Save repository list by user account
    Backend->>Mongo: Get user's GitLab repository list

    Backend->>Elastic: Query already-indexed native app policy updates
    Elastic->>Backend: Return structured update description

    alt No relevant update
        AgentBuilder->>Dev: No Merge Request needed
    else Relevant update found
        Backend->>Repo: Clone/fetch target repo into isolated workspace
        Backend->>Agent: Send workspace path + Elastic context + repo facts
        loop Until code diff is ready
            Agent->>Repo: Read repository files in cloned workspace
            Agent->>Agent: Analyze affected Flutter / Android / iOS code
            Agent->>Agent: Generate code changes
        end
        Backend->>Repo: Create branch and commit generated diff
        Backend->>MR: Create GitLab Merge Request
        MR->>Reviewer: Request human review
        Reviewer->>MR: Approve, merge, or request changes
    end
```

### 3.3 Hackathon MVP - Telegram input, no MongoDB

[Standalone diagram](diagrams/sequence-telegram-mvp.md)

```mermaid
sequenceDiagram
    autonumber
    box Human Area
        actor Dev as Flutter Developer
        actor Reviewer as Human Reviewer
    end
    box Telegram Input Area
        participant Telegram as Telegram Bot
    end
    box AI Platform Area
        participant AgentBuilder as Agent Builder: patchpilot-runtime
        participant Backend as Cloud Run Tool Backend
        participant Agent as Antigravity CLI Coding Worker
    end
    box Elastic Context Layer
        participant Elastic as Elastic Index + Agent Builder
    end
    box GitLab Area
        participant Repo as GitLab Repository
        participant MR as GitLab Merge Request
    end
    box Secret / Runtime Config
        participant Secrets as Secret Manager
    end

    Dev->>Repo: Maintains Flutter repository
    Dev->>Telegram: Send GitLab repo list to Telegram Bot
    Telegram->>Backend: Forward repo list as runtime input
    Backend->>AgentBuilder: Invoke Agent 1 with repo list
    Backend->>Secrets: Read Elastic / GitLab / Telegram secrets

    Backend->>Elastic: Query already-indexed native app policy updates
    Elastic->>Backend: Return structured update description

    alt No relevant update
        Backend->>Telegram: Send "No Merge Request needed"
        Telegram->>Dev: Notify no relevant update found
    else Relevant update found
        Backend->>Repo: Clone/fetch target repo into isolated workspace
        Backend->>Agent: Send workspace path + Elastic context + repo facts
        loop Until code diff is ready
            Agent->>Repo: Read repository files in cloned workspace
            Agent->>Agent: Analyze affected Flutter / Android / iOS code
            Agent->>Agent: Generate code changes
        end
        Backend->>Repo: Create branch and commit generated diff
        Backend->>MR: Create GitLab Merge Request
        Backend->>Telegram: Send MR link to developer
        Telegram->>Dev: Notify GitLab MR is ready
        MR->>Reviewer: Request human review
        Reviewer->>MR: Approve, merge, or request changes
    end
```

## 4. Technology inventory and responsibilities

### 4.1 Google Cloud Agent Platform

Google Cloud Agent Builder / Gemini Enterprise Agent Platform is the primary
PatchPilot agent platform. Cloud Run hosts the custom tool backend for actions
that need filesystem, GitLab, Elastic, Telegram, or Antigravity access. The
agents share Google Cloud infrastructure but do not share responsibilities or
secrets.

| Capability / tool | Function in this project | Notes |
|---|---|---|
| Agent Builder / Gemini Enterprise Agent Platform | Hosts or fronts `patchpilot-runtime` and the policy-context flow. | Primary hackathon-aligned agent layer. |
| Agent Builder Extensions / custom tools | Lets agents invoke typed backend actions. | Runtime and policy tools must be separated. |
| Cloud Run runtime backend | Runs Telegram webhook, Elastic read, GitLab operations, Antigravity CLI, and diff inspection. | Used by Agent 1. |
| Cloud Run ingestion backend or Agent Runtime job | Runs scheduled/manual crawl, cleaning, extraction, validation, and Elastic write/upsert. | Used by Agent 2. |
| Secret Manager | Stores GitLab, Telegram, Elastic, Antigravity, and model-provider credentials. | Prefer over plain env secrets for the primary demo. |
| Cloud Scheduler | Triggers scheduled policy ingestion. | Manual admin trigger is also acceptable for hackathon. |
| Cloud Logging / Trace | Observability for tool backend and agent execution. | Useful for demo and debugging. |
| Agent workspace | Temporary working directory for cloned GitLab repos in Cloud Run volume/container filesystem. | Clean up after MR creation. |

### 4.1.1 Runtime MR Agent

| Responsibility | Detail |
|---|---|
| Trigger | Telegram `/check` with one or more GitLab repo URLs. |
| Elastic access | Read/query only. |
| GitLab access | Clone/fetch repo, create branch, commit, push, create MR. |
| Antigravity access | Invoke CLI inside cloned workspace only. |
| Output | No-action Telegram response or GitLab MR link. |

### 4.1.2 Policy Context Agent

| Responsibility | Detail |
|---|---|
| Trigger | Schedule, manual admin command, or deployment-time ingestion command. |
| Source access | Curated official Google / Apple / Flutter URLs only. |
| Elastic access | Write/upsert validated policy records. |
| AI role | Summarize, classify, extract requirements, define generic coding guidance, score relevance. |
| Output | `platform_policy_updates` records and crawl audit logs. |

### 4.2 Elastic

| Component / tool | Function in this project | Notes |
|---|---|---|
| Elastic Web Crawler or Open Crawler | Crawls/fetches platform policy docs from Google / Apple / Flutter. | Elastic docs describe web crawler as discovering, extracting, and indexing searchable web content. |
| Elasticsearch Index | Stores cleaned platform policy documents and summaries. | Suggested index: `platform_policy_updates`. |
| Elastic Agent Builder | Searches indexed docs and returns structured update descriptions. | AI may summarize, classify, extract requirements, define coding guidance, and score relevance. It must not modify repos or create MRs. |
| Custom search / ES query tool | Finds latest relevant policy update by platform and date. | Could be semantic, keyword, or hybrid query. |
| Enrichment pipeline | Normalizes crawled docs into `platform`, `requirement`, `affected_files`, `severity`, `source_url`. | Can be simple script for MVP. |
| Elastic read/write API keys | Programmatic access to Elastic APIs / Agent Builder. | Keep read and write credentials split by agent role. |

### 4.3 GitLab

| GitLab capability / API | Function in this project | Notes |
|---|---|---|
| GitLab Repository | Source of Flutter project code. | Repos are maintained by Flutter Developer. |
| Personal Access Token / Project Access Token | Authenticates read/write operations. | Use minimum required scope; keep secret. |
| Repository clone / file read | Lets Antigravity CLI Coding Worker inspect `pubspec.yaml`, `android/`, `ios/`, CI config. | Can use `git clone` or GitLab repository/file APIs. |
| Branches API / git branch | Creates feature branch for remediation. | Branch name example: `ai/native-compliance-<date>`. |
| Commits API / git commit | Commits generated code changes. | Commit message should mention PatchPilot native compliance update. |
| Merge Requests API | Creates GitLab MR with title, description, source branch, target branch. | GitLab API supports MR automation and code-review integrations. |
| Merge Request approvals | Human reviewer can approve or request changes. | Automation must not auto-approve itself. |
| CI pipeline, optional | Validates `flutter analyze`, `flutter test`, or build commands. | MVP can include status in MR if available. |

### 4.4 Telegram

| Telegram capability | Function in this project | Notes |
|---|---|---|
| Telegram Bot | Main hackathon input channel. | Developer sends repo list. |
| Bot token | Authenticates bot access. | Store as `TELEGRAM_BOT_TOKEN` env secret. |
| DM or group chat | Input surface for `/check` command. | Use allowlist for safety. |
| Message send | Sends no-action result or MR link. | Can be sent by the Cloud Run Telegram webhook or another configured channel. |
| Allowed sender IDs | Restricts who can trigger code automation. | Enforced in the Telegram webhook/backend before invoking Agent 1. |

### 4.5 MongoDB - ideal mode only

| MongoDB component | Function in this project | Notes |
|---|---|---|
| `repositories` collection | Stores GitLab repo URLs by user account. | Used only in ideal account-based mode. |
| `users` collection, optional | Maps Telegram or platform user to account. | Not required in hackathon MVP. |
| Connection string | Connects Cloud Run/backend helper to database. | Store as `MONGODB_URI`; do not commit. |
| Query by user account | Loads registered repositories for a specific user. | Replaces Telegram runtime repo list in ideal mode. |

### 4.6 Antigravity CLI Coding Worker

| Capability | Function |
|---|---|
| Understand structured update context | Receives Elastic policy description and cloned repo workspace path. |
| Inspect repo | Reads project files in the cloned workspace and identifies native config impact. |
| Generate changes | Updates files such as `android/app/build.gradle`, `AndroidManifest.xml`, `ios/Podfile`, `Info.plist`, or CI config if relevant. |
| Validation loop | Runs or requests lightweight validation when available. |
| Diff output | Leaves a reviewable working-tree diff for the Cloud Run backend / Runtime MR Agent to inspect. |
| Scope control | Operates only inside the cloned target repository workspace. |

## 5. Data models

### 5.1 Elastic index: `platform_policy_updates`

```json
{
  "source": "google_android | apple_ios | flutter_docs",
  "platform": "android | ios | flutter",
  "title": "Target API level requirements for Google Play apps",
  "url": "https://developer.android.com/...",
  "content": "Cleaned text from policy document",
  "summary": "Short normalized update description",
  "detected_requirement": "targetSdk update required",
  "affected_files": ["android/app/build.gradle", "ios/Info.plist"],
  "recommended_action": "Inspect the affected native config and update only when compatibility is clear.",
  "coding_guidance": {
    "goal": "Bring the native project config into compliance with the policy requirement.",
    "likely_actions": ["Inspect current SDK/tool values", "Update native config if safe"],
    "do_not_change": ["Do not modify app business logic"]
  },
  "severity": "info | warning | publishing_blocker",
  "last_crawled_at": "2026-05-23T00:00:00Z"
}
```

### 5.2 MongoDB ideal-mode collection: `repositories`

```json
{
  "user_id": "telegram:123456789",
  "provider": "gitlab",
  "repo_url": "https://gitlab.com/company/flutter-app",
  "default_branch": "main",
  "platforms": ["android", "ios"],
  "created_at": "2026-05-23T00:00:00Z"
}
```

## 6. Telegram command design

### 6.1 MVP command

```text
/check
https://gitlab.com/company/flutter-app-1
https://gitlab.com/company/flutter-app-2
```

### 6.2 Optional structured command

```text
/check native-compliance
repos:
- https://gitlab.com/company/flutter-app-1
- https://gitlab.com/company/flutter-app-2
platforms:
- android
- ios
```

### 6.3 Expected bot responses

```text
No relevant native platform update found. No Merge Request needed.
```

or:

```text
GitLab Merge Request created:
https://gitlab.com/company/flutter-app/-/merge_requests/123
Human review required before merge.
```

## 7. GitLab MR template

```markdown
# Native Compliance Update

Generated by PatchPilot Antigravity Coding Worker. Human review required.

## Policy Context
- Source: Elastic indexed Google / Apple / Flutter docs
- Requirement: <requirement summary>
- Severity: <severity>

## Changes
- <file>: <change summary>

## Review Checklist
- [ ] Confirm platform requirement is relevant
- [ ] Review native Android/iOS changes
- [ ] Run CI or local build
- [ ] Merge only after human approval
```

## 8. Security and secret management

Required env secrets:

```env
TELEGRAM_BOT_TOKEN=
GITLAB_TOKEN=
ELASTICSEARCH_URL=
ELASTIC_READ_API_KEY=
ELASTIC_WRITE_API_KEY=
ANTIGRAVITY_API_KEY=
MONGODB_URI= # ideal mode only
```

Rules:

- Never commit real `.env` values.
- Provide only `.env.example` in public repo.
- Mask GitLab CI variables if used.
- Log only token names, never token values.
- Use least-privilege GitLab token.
- Restrict Telegram input via allowlist.
- Keep Antigravity CLI auth/config scoped to the PatchPilot container/user.
- Give Runtime MR Agent only Elastic read access.
- Give Policy Context Agent only Elastic write/upsert access and no GitLab token.

## 9. Implementation plan

### Phase 1 - Telegram MVP

1. Configure Google Cloud project, region, APIs, and Secret Manager.
2. Create or configure Agent Builder / Gemini Enterprise Agent Platform runtime for PatchPilot.
3. Create `policy-context` ingestion service for scheduled/manual Elastic ingestion.
4. Configure curated source registry and Elastic write/upsert flow.
5. Create `patchpilot-runtime` agent for Telegram `/check`.
6. Deploy Cloud Run runtime tool backend and Telegram webhook.
7. Build Elastic read query/tool for Runtime MR Agent.
8. Install and authenticate Antigravity CLI in the Cloud Run runtime backend.
9. Implement Antigravity task prompt generation for Flutter native compliance.
10. Implement diff inspection and safety checks before commit.
11. Implement GitLab read/branch/commit/MR operations.
12. Send final MR link to Telegram.

### Phase 2 - Ideal account-based mode

1. Add MongoDB repository storage.
2. Add user account mapping.
3. Add `get repositories by user account` flow.
4. Add scheduled or manual scans for stored repos.
5. Add scan history if useful.

## 10. Testing strategy

| Test | Expected result |
|---|---|
| Telegram unauthorized user | Bot rejects or ignores request. |
| Policy Context Agent scheduled crawl | Official docs are fetched, normalized, validated, and upserted into Elastic. |
| Valid repo list, no relevant Elastic update | Bot returns no-MR-needed. |
| Valid repo list, relevant Android update | Antigravity creates code diff; Cloud Run backend / Runtime MR Agent commits branch and creates GitLab MR. |
| Invalid repo URL | Bot reports invalid input. |
| Missing GitLab token | Tool fails safely without exposing secret. |
| Elastic unavailable | Bot reports context provider unavailable. |
| Generated MR | Contains policy summary, affected files, human review note. |

## 11. Failure handling

| Failure | Handling |
|---|---|
| Elastic index empty | Return “policy context unavailable” and do not modify repo. |
| Policy crawl fails | Keep last valid Elastic records and write audit failure. |
| GitLab repo inaccessible | Return error to Telegram. |
| Antigravity cannot determine safe fix | Create no MR; return explanation. |
| Antigravity CLI unavailable | Stop before modifying repo and report coding worker unavailable. |
| Commit fails | Stop and report failure. |
| MR creation fails | Keep branch and report branch link if available. |

## 12. Open questions

- Should MVP run CI before MR creation or after MR creation?
- Should Telegram command allow platform filter, such as Android-only?
- Should generated MR be marked Draft by default?
- Should Elastic crawler run scheduled or manually before each demo?
- Should Cloud Run commit through local Git CLI or the GitLab Commits API after Antigravity generates the diff?
- Which Antigravity CLI auth method will be used in the final Cloud Run container?


## References

- Google Cloud Rapid Agent Hackathon resources: https://rapid-agent.devpost.com/resources
- Gemini Enterprise Agent Platform: https://cloud.google.com/products/gemini-enterprise-agent-platform
- Gemini Enterprise agents overview: https://docs.cloud.google.com/gemini/enterprise/docs/agents-overview
- Agent Platform Runtime / Scale agents: https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale
- Cloud Run: https://cloud.google.com/run
- Secret Manager: https://cloud.google.com/security/products/secret-manager
- Antigravity CLI overview: https://antigravity.google/docs/cli-overview
- Antigravity CLI features: https://antigravity.google/docs/cli-features
- Elastic Agent Builder: https://www.elastic.co/docs/explore-analyze/ai-features/elastic-agent-builder
- Elastic Web Crawler: https://www.elastic.co/guide/en/enterprise-search/current/crawler.html
- Elastic Open Crawler: https://github.com/elastic/crawler
- GitLab Merge Requests API: https://docs.gitlab.com/api/merge_requests/
- GitLab Branches API: https://docs.gitlab.com/api/branches/
- GitLab Commits API: https://docs.gitlab.com/api/commits/
- MongoDB databases and collections: https://www.mongodb.com/docs/manual/core/databases-and-collections/
- MongoDB connection strings: https://www.mongodb.com/docs/manual/reference/connection-string/
- Telegram Bot API: https://core.telegram.org/bots/api
