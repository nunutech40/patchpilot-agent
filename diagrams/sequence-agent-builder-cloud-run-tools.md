# Sequence Diagram - Runtime Agent Tool Execution

This is the detailed runtime sequence for Agent 1, `patchpilot-runtime`.

It sits inside the high-level Telegram MVP flow, exactly at this part:

```txt
Telegram Bot
-> Cloud Run Telegram Webhook
-> Agent Builder / patchpilot-runtime
-> Agent Builder Extension / Tool API
-> Cloud Run Tool Backend
-> Elastic / GitLab / Antigravity / Telegram
```

The key boundary is simple:

- Agent Builder decides what should happen next.
- Agent Builder Extension / Tool API is the callable bridge.
- Cloud Run Tool Backend performs side-effecting work.
- External systems are Elastic, GitLab, Antigravity, Secret Manager, and
  Telegram.

```mermaid
sequenceDiagram
    autonumber

    box User Channel
        actor Dev as Flutter Developer
        participant Telegram as Telegram Bot
    end

    box Google Cloud Entry Area
        participant Webhook as Cloud Run Telegram Webhook
    end

    box Agent Area
        participant Agent as Agent Builder: patchpilot-runtime
        participant Extension as Extension / Custom Tool API
    end

    box Execution Area
        participant Backend as Cloud Run Tool Backend
    end

    box Secure Config
        participant Secrets as Secret Manager
    end

    box External Systems
        participant Elastic as Elastic policy index
        participant GitLab as GitLab Repo + MR API
        participant Antigravity as Antigravity CLI
    end

    rect rgb(245, 248, 255)
        Note over Dev,Backend: Entry: user submits repo URL through Telegram
        Dev->>Telegram: Send /check with GitLab repo URL
        Telegram->>Webhook: Deliver webhook update
        Webhook->>Agent: Start patchpilot-runtime session with repo URL
        Agent->>Agent: Validate input and choose first tool
    end

    rect rgb(245, 255, 248)
        Note over Agent,Elastic: Tool 1: read policy context from Elastic
        Agent->>Extension: query_policy(repo_url, platform hints)
        Extension->>Backend: POST /elastic/query-policy
        Backend->>Secrets: Read Elastic read secret
        Backend->>Elastic: Query indexed policy records
        Elastic->>Backend: Return policy_context and coding_guidance
        Backend->>Extension: Return structured policy payload
        Extension->>Agent: Tool result
    end

    alt No relevant policy update
        rect rgb(255, 250, 240)
            Note over Agent,Telegram: Exit: no code changes are needed
            Agent->>Extension: send_telegram_result(no_action)
            Extension->>Backend: POST /runtime/result
            Backend->>Secrets: Read Telegram secret
            Backend->>Telegram: Send no-MR-needed message
        end
    else Relevant update found
        rect rgb(248, 245, 255)
            Note over Agent,GitLab: Tool 2: prepare isolated repo workspace
            Agent->>Extension: prepare_workspace(repo_url)
            Extension->>Backend: POST /gitlab/prepare-workspace
            Backend->>Secrets: Read GitLab secret
            Backend->>GitLab: Clone/fetch repo into isolated workspace
            GitLab->>Backend: Workspace ready
            Backend->>Extension: Return workspace_path and repo_facts
            Extension->>Agent: Tool result
        end

        rect rgb(245, 255, 255)
            Note over Agent,Antigravity: Tool 3: run coding worker inside workspace
            Agent->>Agent: Build coding task from policy_context + repo_facts
            Agent->>Extension: run_antigravity(task_payload)
            Extension->>Backend: POST /antigravity/run
            Backend->>Secrets: Read Antigravity auth/config
            Backend->>Antigravity: Run CLI inside workspace_path
            Antigravity->>Backend: Return changed files, summary, validation status
            Backend->>Backend: Inspect diff boundary
            Backend->>Extension: Return safe diff summary
            Extension->>Agent: Tool result
        end

        rect rgb(255, 245, 248)
            Note over Agent,Telegram: Tool 4: create MR and notify user
            Agent->>Extension: create_merge_request(mr_payload)
            Extension->>Backend: POST /gitlab/create-merge-request
            Backend->>GitLab: Create branch, commit diff, open MR
            GitLab->>Backend: Return MR URL
            Backend->>Secrets: Read Telegram secret
            Backend->>Telegram: Send MR link and summary
            Backend->>Extension: Return MR URL
            Extension->>Agent: Tool result
        end
    end
```

## Tool Boundary

Agent Builder should not clone repositories, execute Antigravity, commit code,
or hold long-lived partner secrets directly. Those actions belong in Cloud Run.

Cloud Run endpoints should return structured JSON so Agent Builder can reason
over tool results without needing filesystem access.

## Cloud Run Tool Endpoints

| Endpoint | Called by | Purpose |
|---|---|---|
| `POST /elastic/query-policy` | `query_policy` tool | Read indexed policy context from Elastic. |
| `POST /gitlab/prepare-workspace` | `prepare_workspace` tool | Clone/fetch repo and return `workspace_path` plus repo facts. |
| `POST /antigravity/run` | `run_antigravity` tool | Run Antigravity CLI inside the prepared workspace. |
| `POST /gitlab/create-merge-request` | `create_merge_request` tool | Create branch, commit diff, open GitLab MR. |
| `POST /runtime/result` | `send_telegram_result` tool | Send no-action or failure result to Telegram. |
