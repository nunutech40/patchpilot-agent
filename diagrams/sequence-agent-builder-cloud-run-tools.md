# Sequence Diagram - Agent Builder to Cloud Run Tools

This sequence shows the detailed runtime tool boundary. Agent Builder owns
reasoning and tool selection. Cloud Run owns side-effecting execution: Elastic
queries, GitLab workspace operations, Antigravity CLI execution, MR creation,
and Telegram notification.

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Flutter Developer
    participant Telegram as Telegram Bot
    participant Webhook as Cloud Run Telegram Webhook
    participant Agent as Agent Builder: patchpilot-runtime
    participant Extension as Agent Builder Extension / Tool API
    participant Backend as Cloud Run Tool Backend
    participant Secrets as Secret Manager
    participant Elastic as Elastic platform_policy_updates
    participant GitLab as GitLab Repository / MR API
    participant Antigravity as Antigravity CLI Coding Worker

    Dev->>Telegram: Send /check with GitLab repo URL
    Telegram->>Webhook: Deliver webhook update
    Webhook->>Agent: Start patchpilot-runtime session with repo URL
    Agent->>Agent: Validate intent and decide required tools

    Agent->>Extension: call query_policy(repo_url, platform hints)
    Extension->>Backend: POST /elastic/query-policy
    Backend->>Secrets: Read ELASTICSEARCH_URL and ELASTIC_READ_API_KEY
    Backend->>Elastic: Query indexed policy records
    Elastic->>Backend: Return policy_context and coding_guidance
    Backend->>Extension: Return structured policy payload
    Extension->>Agent: Tool result

    alt No relevant policy update
        Agent->>Extension: call send_telegram_result(no_action)
        Extension->>Backend: POST /runtime/check result
        Backend->>Secrets: Read TELEGRAM_BOT_TOKEN
        Backend->>Telegram: Send no-MR-needed message
    else Relevant update found
        Agent->>Extension: call prepare_workspace(repo_url)
        Extension->>Backend: POST /gitlab/prepare-workspace
        Backend->>Secrets: Read GITLAB_TOKEN
        Backend->>GitLab: Clone/fetch repo into isolated workspace
        GitLab->>Backend: Workspace ready
        Backend->>Extension: Return workspace_path and repo_facts
        Extension->>Agent: Tool result

        Agent->>Agent: Build Antigravity task from policy_context + repo_facts
        Agent->>Extension: call run_antigravity(task_payload)
        Extension->>Backend: POST /antigravity/run
        Backend->>Secrets: Read ANTIGRAVITY auth/config
        Backend->>Antigravity: Run CLI inside workspace_path
        Antigravity->>Backend: Return changed files, summary, validation status
        Backend->>Backend: Inspect diff boundary
        Backend->>Extension: Return safe diff summary
        Extension->>Agent: Tool result

        Agent->>Extension: call create_merge_request(mr_payload)
        Extension->>Backend: POST /gitlab/create-merge-request
        Backend->>GitLab: Create branch, commit diff, open MR
        GitLab->>Backend: Return MR URL
        Backend->>Telegram: Send MR link and summary
        Backend->>Extension: Return MR URL
        Extension->>Agent: Tool result
    end
```

## Tool Boundary

Agent Builder should not clone repositories, execute Antigravity, commit code,
or hold long-lived partner secrets directly. Those actions belong in Cloud Run.

Cloud Run endpoints should return structured JSON so Agent Builder can reason
over tool results without needing filesystem access.

