# Google Cloud Rapid Agent Hackathon Resources

This document captures the Google Cloud resources referenced by the Rapid Agent
Hackathon resource page so PatchPilot planning can stay aligned with the event.

Primary hackathon page:

- Google Cloud Rapid Agent Hackathon resources:
  https://rapid-agent.devpost.com/resources

## Deadline

- Submission deadline: June 11, 2026 at 2:00 PM PDT.

## Core Google Cloud Resources

The Devpost page groups the resources into five phases:

| Devpost phase | PatchPilot interpretation |
|---|---|
| Phase 1: Core Frameworks & Environment | Choose Agent Builder / Gemini Enterprise Agent Platform, SDK, and starter pack. |
| Phase 2: Action Mechanisms & Data Connectivity | Use Extensions/custom tools for actions and Data Stores/Elastic for grounding. |
| Phase 3: Partner Integration & Infrastructure | Use Elastic, GitLab, and optional MongoDB partner integrations. |
| Phase 4: Reasoning, State, & Logic Hosting | Use Agent Runtime, Cloud Run, and Secret Manager for custom logic and stateful execution. |
| Phase 5: Deployment & Safety | Deploy via Agent Builder/Cloud Run and configure safety/guardrails. |

| Hackathon resource | Purpose for PatchPilot | Link |
|---|---|---|
| Gemini Enterprise Agent Platform / Agent Builder | Primary agent platform for building, scaling, governing, and optimizing PatchPilot agents. | https://cloud.google.com/products/gemini-enterprise-agent-platform |
| Agent Builder Guide | Low-code path for managed orchestration, grounding, and enterprise data stores. | https://rapid-agent.devpost.com/resources |
| Gemini Enterprise Agent Platform SDK for Python | Developer SDK path for custom agent logic and tool calls. | https://rapid-agent.devpost.com/resources |
| Agent Starter Pack | Starter templates for agent projects. | https://github.com/GoogleCloudPlatform/agent-starter-pack |
| Agent Builder Extensions | Tool/action mechanism for connecting managed agents to external APIs. | https://rapid-agent.devpost.com/resources |
| Agent Builder Data Stores | Knowledge/grounding layer for indexed websites, PDFs, BigQuery, and other source-of-truth data. | https://rapid-agent.devpost.com/resources |
| Agent Runtime | Managed runtime for custom agents, including ADK, LangChain, LangGraph, LlamaIndex, A2A, and related patterns. | https://docs.cloud.google.com/gemini-enterprise-agent-platform/scale |
| Secret Manager | Secure storage for GitLab, Telegram, Elastic, and Antigravity secrets. | https://cloud.google.com/security/products/secret-manager |
| Cloud Run | Custom backend/tool server hosting for GitLab, Antigravity, Elastic, Telegram webhook, and ingestion endpoints. | https://cloud.google.com/run |
| Gemini safety settings | Safety and guardrail configuration for Gemini-powered agents. | https://rapid-agent.devpost.com/resources |

## Partner Resources

The Devpost resources page links partner-specific information for:

- Elastic
- GitLab
- MongoDB
- Fivetran
- Arize
- Dynatrace

PatchPilot uses the following partner-aligned services:

| Partner | PatchPilot use |
|---|---|
| Elastic | Platform policy context index, search, and retrieval. |
| GitLab | Source repository, branch, commit, and Merge Request output. |
| MongoDB | Optional ideal-mode persistence for account-based repository lists. |

## Architecture Implication

PatchPilot should present Google Cloud as the primary hackathon platform:

```txt
Google Cloud Agent Builder / Gemini Enterprise Agent Platform
  -> Agent 1: patchpilot-runtime
     -> Cloud Run tool backend
     -> Elastic read/query
     -> GitLab clone/branch/commit/MR
     -> Antigravity CLI coding worker

Cloud Scheduler / Cloud Run / Agent Runtime
  -> Agent 2: policy-context
     -> curated official docs fetch
     -> Gemini extraction/classification
     -> Elastic write/upsert
```
