# Sequence Diagram - Telegram MVP with Antigravity

This is the hackathon MVP runtime flow. Repository input is provided at runtime
through Telegram. No MongoDB persistence is required.

This flow queries policy records that were already indexed by the separate
[policy ingestion flow](sequence-policy-ingestion.md). It should not crawl the
internet on every `/check` request.

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
    box Orchestration Area
        participant AgentBuilder as Agent Builder: patchpilot-runtime
        participant Backend as Cloud Run Tool Backend
    end
    box Elastic Context Layer
        participant Elastic as Elastic Index + Agent Builder
    end
    box Coding Worker Area
        participant Antigravity as Antigravity CLI Coding Worker
    end
    box GitLab Area
        participant Repo as GitLab Repository
        participant MR as GitLab Merge Request
    end
    box Secret / Runtime Config
        participant Secrets as Secret Manager
    end

    Dev->>Repo: Maintains Flutter repository
    Dev->>Telegram: Send /check with GitLab repo URLs
    Telegram->>Backend: Forward repo list as runtime input
    Backend->>AgentBuilder: Invoke Agent 1 with repo list
    Backend->>Secrets: Read Telegram / Elastic / GitLab / Antigravity config

    Backend->>Elastic: Query indexed policy updates for relevant native changes
    Elastic->>Backend: Return structured update description

    alt No relevant update
        Backend->>Telegram: Send no-MR-needed result
        Telegram->>Dev: Notify no relevant update found
    else Relevant update found
        Backend->>Repo: Clone/fetch target repo into isolated workspace
        Backend->>Antigravity: Send workspace path + Elastic context + repo facts
        loop Until code diff is ready
            Antigravity->>Repo: Read repository files in cloned workspace
            Antigravity->>Antigravity: Analyze affected Flutter / Android / iOS code
            Antigravity->>Repo: Generate minimal native-compliance changes
            Antigravity->>Antigravity: Run lightweight validation if available
        end
        Antigravity->>Backend: Report changed files and validation status
        Backend->>Backend: Inspect diff boundary and prepare MR description
        Backend->>Repo: Create branch and commit generated diff
        Backend->>MR: Create GitLab Merge Request
        Backend->>Telegram: Send MR link to developer
        Telegram->>Dev: Notify GitLab MR is ready
        MR->>Reviewer: Request human review
        Reviewer->>MR: Approve, merge, or request changes
    end
```
