# Sequence Diagram - Elastic Policy Record to Antigravity Coding Task

This flow runs during `/check`, after the Policy Context Agent has already
crawled official sources and saved normalized policy records in Elastic.

The Policy Context Agent defines the generic policy requirement, likely affected
files, recommended action, source URLs, severity, and guardrail hints. The
Runtime MR Agent adds repo-specific facts, then builds the concrete Antigravity
coding task.

```mermaid
sequenceDiagram
    autonumber
    participant Policy as Agent 2: policy-context
    participant Elastic as Elastic Index + Agent Builder
    participant Runtime as Agent 1: patchpilot-runtime
    participant GitLab as GitLab Repository
    participant Context as Context Builder
    participant Antigravity as Antigravity CLI Coding Worker

    Note over Policy,Elastic: Earlier background ingestion flow
    Policy->>Elastic: Upsert policy_update with requirement, affected files, source URLs, recommended action

    Runtime->>Elastic: Query by repo platform, current date, severity, and source freshness
    Elastic->>Elastic: Retrieve matching policy_update records
    Elastic->>Runtime: Return generic policy context and coding guidance
    Runtime->>GitLab: Clone/fetch repo into isolated workspace
    Runtime->>GitLab: Inspect target files and detect current native config
    Runtime->>Context: Combine policy context + repo facts
    Context->>Context: Build concrete Antigravity task prompt and guardrails
    Context->>Antigravity: Send workspace path + coding task payload
    Antigravity->>Antigravity: Plan minimal native-compliance edits
    Antigravity->>GitLab: Edit cloned workspace files only
    Antigravity->>Runtime: Return changed files, summary, validation status
    Runtime->>Runtime: Inspect diff boundary before commit
```
