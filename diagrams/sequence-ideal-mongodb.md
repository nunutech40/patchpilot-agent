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
        participant AgentBuilder as Agent Builder: patchpilot-runtime
        participant Backend as Cloud Run Tool Backend
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
        participant Secrets as Secret Manager
    end

    Dev->>Repo: Maintains Flutter repository
    Dev->>AgentBuilder: Input or update GitLab repository list
    AgentBuilder->>Backend: Request repository registration/check
    Backend->>Secrets: Read MongoDB / GitLab / Elastic / Antigravity config
    Backend->>Mongo: Save repository list by user account
    Backend->>Mongo: Load user's GitLab repository list when check starts

    Backend->>Elastic: Query indexed policy updates for relevant native changes
    Elastic->>Backend: Return structured update description

    alt No relevant update
        AgentBuilder->>Dev: Send no-MR-needed result
    else Relevant update found
        loop For each target repository
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
        end
        MR->>Reviewer: Request human review
        Reviewer->>MR: Approve, merge, or request changes
    end
```
