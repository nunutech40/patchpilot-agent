# Sequence Diagram - Elastic Context to Antigravity Coding Task

This flow defines how already-indexed Elastic policy records become the coding
task that Antigravity receives. It runs during `/check`, after policy ingestion
has already populated Elastic.

```mermaid
sequenceDiagram
    autonumber
    participant OpenClaw as Runtime MR Agent
    participant Elastic as Elastic Index + Agent Builder
    participant GitLab as GitLab Repository
    participant Context as Context Builder
    participant Antigravity as Antigravity CLI Coding Worker

    OpenClaw->>Elastic: Query by repo platform, current date, severity, and source freshness
    Elastic->>Elastic: Retrieve matching policy_update records
    Elastic->>OpenClaw: Return structured policy context payload
    OpenClaw->>GitLab: Clone/fetch repo into isolated workspace
    OpenClaw->>GitLab: Inspect target files and detect current native config
    OpenClaw->>Context: Combine policy context + repo facts
    Context->>Context: Build Antigravity task prompt and guardrails
    Context->>Antigravity: Send workspace path + coding task payload
    Antigravity->>Antigravity: Plan minimal native-compliance edits
    Antigravity->>GitLab: Edit cloned workspace files only
    Antigravity->>OpenClaw: Return changed files, summary, validation status
    OpenClaw->>OpenClaw: Inspect diff boundary before commit
```
