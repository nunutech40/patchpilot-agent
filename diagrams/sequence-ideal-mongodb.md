# Sequence Diagram - Ideal Mode with MongoDB and Antigravity

This is the scalable runtime product flow. Repository lists are stored by
user/account and can be reused for future manual or scheduled checks.

This flow queries policy records that were already indexed by the separate
[policy ingestion flow](sequence-policy-ingestion.md). It should not crawl the
internet for every repository scan.

```mermaid
sequenceDiagram
    autonumber
    box Human Area
        actor Dev as Flutter Developer
        actor Reviewer as Human Reviewer
    end
    box Orchestration Area
        participant OpenClaw as OpenClaw Orchestrator
    end
    box Data Storage Area
        participant Mongo as MongoDB
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
        participant Secrets as Env Secrets
    end

    Dev->>Repo: Maintains Flutter repository
    Dev->>OpenClaw: Input or update GitLab repository list
    OpenClaw->>Secrets: Read MongoDB / GitLab / Elastic / Antigravity config
    OpenClaw->>Mongo: Save repository list by user account
    OpenClaw->>Mongo: Load user's GitLab repository list when check starts

    OpenClaw->>Elastic: Query indexed policy updates for relevant native changes
    Elastic->>OpenClaw: Return structured update description

    alt No relevant update
        OpenClaw->>Dev: Send no-MR-needed result
    else Relevant update found
        loop For each target repository
            OpenClaw->>Repo: Clone/fetch target repo into isolated workspace
            OpenClaw->>Antigravity: Send workspace path + Elastic update description
            loop Until code diff is ready
                Antigravity->>Repo: Read repository files in cloned workspace
                Antigravity->>Antigravity: Analyze affected Flutter / Android / iOS code
                Antigravity->>Repo: Generate minimal native-compliance changes
                Antigravity->>Antigravity: Run lightweight validation if available
            end
            Antigravity->>OpenClaw: Report changed files and validation status
            OpenClaw->>OpenClaw: Inspect diff boundary and prepare MR description
            OpenClaw->>Repo: Create branch and commit generated diff
            OpenClaw->>MR: Create GitLab Merge Request
        end
        MR->>Reviewer: Request human review
        Reviewer->>MR: Approve, merge, or request changes
    end
```
