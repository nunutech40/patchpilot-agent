# Sequence Diagram - Policy Ingestion Flow

This flow runs separately from user-submitted repository checks. It crawls
official platform policy sources, normalizes them, and stores searchable records
in Elastic. It should run on a schedule or by manual admin trigger, not every
time a developer sends `/check`.

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Admin / Scheduler
    participant Ingest as Policy Context Agent
    participant Registry as Curated Source Registry
    participant Fetcher as Policy Fetcher
    participant Docs as Official Policy Sources
    participant Cleaner as Content Cleaner
    participant AI as Extraction / Classification AI
    participant Validator as Record Validator
    participant Elastic as Elastic Index
    participant Audit as Crawl Audit Log

    Admin->>Ingest: Trigger scheduled or manual crawl
    Admin->>Registry: Load curated Google / Apple / Flutter source list
    Registry->>Fetcher: Send source URL, platform, source type, crawl priority
    Fetcher->>Docs: Fetch official policy / release / changelog page
    Docs->>Fetcher: Return HTML, metadata, and last-modified hints
    Fetcher->>Cleaner: Send raw content
    Cleaner->>Cleaner: Extract readable text, headings, links, dates, checksums
    Cleaner->>AI: Send cleaned text + source metadata
    AI->>AI: Summarize, classify, extract requirements and affected files
    AI->>Validator: Return normalized update candidate
    Validator->>Validator: Check required fields, source URL, confidence, dates
    Validator->>Elastic: Upsert validated policy_update record
    Validator->>Audit: Store crawl timestamp, source URL, checksum, result

    alt Source changed or new requirement found
        Validator->>Elastic: Mark record active and searchable
    else No meaningful change
        Validator->>Audit: Record no-op crawl result
    end
```
