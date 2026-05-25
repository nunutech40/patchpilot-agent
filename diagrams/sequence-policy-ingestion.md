# Sequence Diagram - Policy Ingestion Flow

This flow runs separately from user-submitted repository checks. It crawls
official platform policy sources, normalizes them, and stores searchable records
in Elastic. It should run on a schedule or by manual admin trigger, not every
time a developer sends `/check`.

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Admin / Scheduler
    participant Ingest as Policy Ingestion Worker
    participant Docs as Official Policy Sources
    participant AI as Extraction / Classification AI
    participant Elastic as Elastic Index
    participant Audit as Crawl Audit Log

    Admin->>Ingest: Trigger scheduled or manual crawl
    Ingest->>Docs: Fetch curated Google / Apple / Flutter URLs
    Docs->>Ingest: Return policy, release, and changelog content
    Ingest->>Ingest: Clean text and capture metadata
    Ingest->>AI: Summarize, classify, extract requirements
    AI->>Ingest: Return normalized update record
    Ingest->>Elastic: Upsert into platform_policy_updates
    Ingest->>Audit: Store crawl timestamp, source URL, checksum, result

    alt Source changed or new requirement found
        Ingest->>Elastic: Mark record active and searchable
    else No meaningful change
        Ingest->>Audit: Record no-op crawl result
    end
```
