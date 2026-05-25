# Building Plan — Flutter Native Compliance MR Agent

## Recommended Project Name

**PatchPilot**

Short description:

> PatchPilot is an AI agent that watches native mobile platform updates, checks Flutter repositories, and creates GitLab Merge Requests with the required code changes.

Why this name works:

- Easy to remember.
- Sounds like an agent that helps navigate code changes.
- Not too tied to Flutter, so it can expand later to React Native, Android native, or iOS native.
- Works well for a GitHub repo name: `patchpilot`, `patchpilot-ai`, or `patchpilot-agent`.

## Alternative Names

| Name | Vibe | Notes |
|---|---|---|
| **PatchPilot** | Clean, product-ready | Best overall pick |
| **NativePatch** | Direct and technical | Very clear for mobile native updates |
| **MRPilot** | GitLab-focused | Good if output is always Merge Request |
| **ComplyBot** | Compliance-focused | Simple, but sounds more like a bot |
| **RepoMedic** | Fun/dev-friendly | Suggests fixing broken repos |
| **PolicyPatch** | Very descriptive | Strong for policy-driven code changes |
| **FlutterFixer** | Niche Flutter | Good for MVP, less scalable later |
| **UpdateForge** | Builder/product vibe | Good for hackathon/demo |

Recommended GitHub repository name:

```txt
patchpilot-agent
```

---

# Product Goal

Build an AI automation tool that receives a GitLab Flutter repository list from a Telegram Bot, checks latest native mobile platform updates through Elastic, lets an Antigravity CLI Coding Worker modify a cloned repository workspace, and creates a GitLab Merge Request for human review.

The final output is **not an auto-merge**. The final output is a **GitLab Merge Request reviewed by a human**.

---

# Final MVP Architecture

```txt
Flutter Developer
  ↓ sends repo list
Telegram Bot
  ↓ forwards runtime input
OpenClaw Runtime MR Agent
  ↓ queries already-indexed platform update context
Elastic Context Layer
  ↓ returns structured policy update

OpenClaw Runtime MR Agent
  ↓ gives repo list + Elastic context
Antigravity CLI Coding Worker
  ↓ reads repo and edits code in cloned workspace
Runtime MR Agent GitLab automation
  ↓ reviews diff, commits branch
GitLab Repository
  ↓ creates
GitLab Merge Request
  ↓ reviewed by
Human Reviewer
```

---

# Phase 0 — Repository Setup

Goal: prepare the public GitHub repository safely.

## Checklist

- [ ] Create GitHub repository: `patchpilot-agent`.
- [ ] Add `README.md` with project overview.
- [ ] Add `.gitignore`.
- [ ] Add `.env.example`.
- [ ] Make sure `.env` is ignored.
- [x] Add `PRD_AI_Native_Compliance_Automation_Refactored.md`.
- [x] Add `TRD_AI_Native_Compliance_Automation_Refactored.md`.
- [x] Add `BUILDING_PLAN.md`.
- [x] Add `diagrams/sequence-telegram-mvp.md`.
- [x] Add `diagrams/sequence-ideal-mongodb.md`.
- [ ] Add license file.

## Environment Variables

Never commit real keys.

```env
TELEGRAM_BOT_TOKEN=
GITLAB_TOKEN=
ELASTICSEARCH_URL=
ELASTIC_READ_API_KEY=
ELASTIC_WRITE_API_KEY=
OPENCLAW_API_KEY=
ANTIGRAVITY_API_KEY=
ANTIGRAVITY_MODEL=
ANTIGRAVITY_CLI_PATH=antigravity
PATCHPILOT_RUNTIME_AGENT_ID=patchpilot-runtime
POLICY_CONTEXT_AGENT_ID=policy-context
```

Optional for the ideal version:

```env
MONGODB_URI=
```

---

# Phase 1 — Telegram Bot Input

Goal: allow Flutter Developer to send GitLab repo list through Telegram.

## User Flow

```txt
Developer sends:
/check
https://gitlab.com/company/flutter-app-1
https://gitlab.com/company/flutter-app-2
```

Bot forwards repo list to the OpenClaw Runtime MR Agent.

## Checklist

- [ ] Create Telegram Bot via BotFather.
- [ ] Store `TELEGRAM_BOT_TOKEN` in env secrets.
- [ ] Implement `/start` command.
- [ ] Implement `/check` command.
- [ ] Parse GitLab repository URLs from message.
- [ ] Validate repository URL format.
- [ ] Return error if no valid repo URL is found.
- [ ] Forward valid repo list to OpenClaw workflow.
- [ ] Send initial response: “Checking latest native platform updates…”

## Acceptance Criteria

- [ ] User can send one or more GitLab repo URLs.
- [ ] Invalid input returns a helpful error.
- [ ] Valid input triggers OpenClaw workflow.

---

# Phase 2 — Elastic Policy Ingestion Flow

Goal: crawl and index official platform policy sources before runtime repo checks.

This flow is owned by the OpenClaw Policy Context Agent. It is separate from
Telegram `/check` and should run on a schedule or manual admin trigger, not
every time a developer submits a repo.

## Data Sources

Use one combined source group:

```txt
Platform Policy Docs
- Google / Android Docs
- Apple Developer / App Store Docs
- Flutter Docs
```

## Elastic Components

- Elastic Web Crawler / Policy Fetcher
- Elasticsearch Index
- Elastic Agent Builder

See [`docs/policy-crawl-plan.md`](docs/policy-crawl-plan.md) for the curated
official source list and extraction schema.

See [`diagrams/sequence-policy-ingestion.md`](diagrams/sequence-policy-ingestion.md)
for the background crawl/index flow and
[`diagrams/sequence-elastic-context-to-coding-agent.md`](diagrams/sequence-elastic-context-to-coding-agent.md)
for how Elastic records become an Antigravity coding task.

## Checklist

- [ ] Create OpenClaw `policy-context` agent.
- [ ] Create Elasticsearch deployment or Elastic Cloud project.
- [ ] Create index: `platform_policy_updates`.
- [ ] Configure Elastic Web Crawler or custom fetcher.
- [ ] Add seed URLs for Google / Apple / Flutter docs.
- [ ] Index cleaned policy documents.
- [ ] Add fields: `source`, `platform`, `title`, `url`, `content`, `summary`, `affected_files`, `severity`, `last_crawled_at`.
- [ ] Extract structured requirements: API level, SDK version, tool version, effective date, severity, and likely affected files.
- [ ] Use AI only for summarization, classification, extraction, and relevance scoring.
- [ ] Create query/tool in Elastic Agent Builder.
- [ ] Return structured update description to the Runtime MR Agent.
- [ ] Build coding-task payload with policy context, repo facts, expected changes, constraints, and validation commands.

## Example Structured Update Description

```json
{
  "has_relevant_update": true,
  "platform": "android",
  "title": "Google Play target API level requirement update",
  "summary": "Apps must target a newer Android API level for Play Store submission.",
  "affected_project_areas": [
    "android/app/build.gradle",
    "android/build.gradle",
    "AndroidManifest.xml"
  ],
  "recommended_action": "Inspect targetSdk, compileSdk, Gradle plugin compatibility, and permission behavior changes.",
  "source_urls": [
    "https://developer.android.com/..."
  ]
}
```

## Acceptance Criteria

- [ ] Elastic can retrieve relevant Android/iOS/Flutter policy docs.
- [ ] Elastic can return a structured update description.
- [ ] Runtime MR Agent can consume the Elastic response.
- [ ] Runtime repo checks can query Elastic without crawling the internet.

---

# Phase 3 — Runtime MR Agent Workflow

Goal: OpenClaw Runtime MR Agent orchestrates the flow from Telegram input to Antigravity CLI Coding Worker execution.

## Responsibilities

Runtime MR Agent should:

- Receive repo list from Telegram Bot.
- Ask Elastic for relevant update context from already-indexed records.
- Decide whether an MR is needed.
- Clone the GitLab repo into an isolated workspace.
- Send repo workspace + update description to Antigravity CLI Coding Worker.
- Inspect the generated diff before commit.
- Send result link back to Telegram.

## Checklist

- [ ] Create OpenClaw workflow/session.
- [ ] Create OpenClaw `patchpilot-runtime` agent.
- [ ] Add Telegram input handler.
- [ ] Add Elastic query step.
- [ ] Add condition: no relevant update vs relevant update found.
- [ ] Add GitLab clone/workspace preparation step.
- [ ] Install/authenticate Antigravity CLI in the isolated PatchPilot runtime.
- [ ] Generate Antigravity task prompt from Elastic update context.
- [ ] Add Antigravity CLI Coding Worker task step.
- [ ] Add diff inspection/safety boundary step.
- [ ] Add Telegram notification step.
- [ ] Add error handling.

## Acceptance Criteria

- [ ] Runtime MR Agent can receive runtime repo input.
- [ ] Runtime MR Agent can query Elastic read-only.
- [ ] Runtime MR Agent can trigger Antigravity CLI Coding Worker.
- [ ] Runtime MR Agent can stop safely if Antigravity CLI is unavailable.
- [ ] Runtime MR Agent can send status back to Telegram.

---

# Phase 4 — GitLab Integration

Goal: allow Runtime MR Agent/GitLab automation to read repositories, prepare workspaces, create branches, commit Antigravity-generated changes, and open Merge Requests.

## GitLab Tools Needed

| Tool / API | Function in Project |
|---|---|
| Repository Files API | Read and update files in Flutter repo |
| Branches API | Create fix branch from default branch |
| Commits API | Commit generated changes |
| Merge Requests API | Create MR for human review |
| Project API | Resolve GitLab project ID from URL |

## Checklist

- [ ] Create GitLab personal/project access token.
- [ ] Store `GITLAB_TOKEN` in env secrets.
- [ ] Resolve project ID from GitLab repo URL.
- [ ] Clone or fetch repository into isolated workspace.
- [ ] Read repository tree.
- [ ] Read target files:
  - [ ] `pubspec.yaml`
  - [ ] `android/app/build.gradle`
  - [ ] `android/build.gradle`
  - [ ] `AndroidManifest.xml`
  - [ ] `ios/Podfile`
  - [ ] `ios/Runner/Info.plist`
- [ ] Create fix branch.
- [ ] Commit code changes.
- [ ] Create GitLab Merge Request.
- [ ] Include policy explanation in MR description.

## Acceptance Criteria

- [ ] Runtime MR Agent can prepare a cloned target repo workspace.
- [ ] Antigravity can edit only the cloned target repo.
- [ ] Runtime MR Agent can create branch.
- [ ] Runtime MR Agent can commit changes.
- [ ] Runtime MR Agent can open GitLab MR.

---

# Phase 5 — Antigravity CLI Coding Worker

Goal: generate safe repository changes based on Elastic context.

## Input

```txt
- GitLab repo URL(s)
- Structured update description from Elastic
- Platform target: Android / iOS / Flutter
```

## Agent Tasks

```txt
1. Read repository files.
2. Identify affected native config.
3. Decide required code changes.
4. Generate code changes.
5. Leave a reviewable working-tree diff.
6. Report validation status and changed files.
```

## Checklist

- [ ] Antigravity reads only the cloned target repo.
- [ ] Antigravity uses Elastic update description as policy context.
- [ ] Antigravity does not browse random external sources.
- [ ] Antigravity creates minimal code changes.
- [ ] Antigravity avoids changing unrelated files.
- [ ] Antigravity writes a concise change summary for the MR.
- [ ] Runtime MR Agent writes clear commit message.
- [ ] Runtime MR Agent writes MR description with:
  - [ ] What changed
  - [ ] Why it changed
  - [ ] Source policy reference
  - [ ] Affected files
  - [ ] Human review reminder

## Acceptance Criteria

- [ ] PatchPilot-generated MR is understandable by a human reviewer.
- [ ] MR contains Antigravity-generated code diff and explanation.
- [ ] MR does not auto-merge.

---

# Phase 6 — Validation and Safety

Goal: reduce risk before MR is created.

For hackathon MVP, validation can be lightweight.

## Optional Validation Commands

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Checklist

- [ ] Check whether Flutter is available in runtime.
- [ ] If available, run `flutter analyze`.
- [ ] If available, run basic build/test command.
- [ ] If not available, mention validation not executed in MR description.
- [ ] Never auto-merge MR.
- [ ] Always require human review.

## Acceptance Criteria

- [ ] MR clearly states whether validation was run.
- [ ] Human reviewer knows what to check.

---

# Phase 7 — Telegram Result Notification

Goal: send final MR result back to developer.

## Checklist

- [ ] Send “No MR needed” if no relevant update exists.
- [ ] Send MR link if MR was created.
- [ ] Send failure message if agent fails.
- [ ] Include short summary in Telegram message.

## Example Success Message

```txt
PatchPilot created a GitLab Merge Request.

Repo: company/flutter-app
Update: Android target SDK requirement
MR: https://gitlab.com/company/flutter-app/-/merge_requests/12

Please review before merging.
```

## Acceptance Criteria

- [ ] Developer receives MR link in Telegram.
- [ ] Developer can open GitLab and review MR.

---

# Phase 8 — Demo Preparation

Goal: prepare hackathon demo with a reliable story.

## Demo Story

```txt
A Flutter developer sends a GitLab repo URL to PatchPilot via Telegram.
PatchPilot checks Elastic for latest Google / Apple / Flutter platform updates.
Elastic returns a relevant Android/iOS update.
PatchPilot runs Antigravity CLI Coding Worker.
Antigravity updates the Flutter native config in the cloned workspace.
Runtime MR Agent reviews the diff boundary and commits the branch.
PatchPilot creates a GitLab Merge Request.
Human reviewer reviews the MR.
```

## Checklist

- [ ] Prepare demo GitLab Flutter repo.
- [ ] Add intentionally outdated native config.
- [ ] Prepare Elastic index with at least one relevant policy document.
- [ ] Prepare Telegram Bot.
- [ ] Prepare OpenClaw workflow.
- [ ] Prepare Antigravity CLI auth/config in isolated PatchPilot runtime.
- [ ] Prepare successful MR example.
- [ ] Prepare fallback recording/screenshots.
- [ ] Prepare 2-minute pitch.

---

# Phase 9 — Ideal Version After Hackathon

Goal: extend MVP into a persistent product.

## Add MongoDB

MongoDB is useful when repo list needs to persist per user account.

## Checklist

- [ ] Add user account model.
- [ ] Save registered repositories by user.
- [ ] Add dashboard for repo list.
- [ ] Add scheduled scans.
- [ ] Add scan history.
- [ ] Add MR history.
- [ ] Add organization/team support.

---

# Milestone Plan

## Day 1

- [ ] Finalize repo structure.
- [ ] Create Telegram Bot.
- [ ] Create Elastic index.
- [ ] Prepare seed policy docs.

## Day 2

- [ ] Build OpenClaw flow.
- [ ] Connect Telegram → OpenClaw.
- [ ] Connect OpenClaw → Elastic.

## Day 3

- [ ] Build GitLab integration.
- [ ] Integrate Antigravity CLI coding worker.
- [ ] Implement branch + commit + MR creation.
- [ ] Test on demo Flutter repo.

## Day 4

- [ ] Improve Antigravity CLI Coding Worker prompt/task and diff guardrails.
- [ ] Add MR description quality.
- [ ] Add Telegram result notification.

## Day 5

- [ ] Polish demo.
- [ ] Prepare slides/readme.
- [ ] Record backup demo.

---

# Definition of Done for Hackathon MVP

- [ ] Developer can send repo list through Telegram.
- [ ] Runtime MR Agent receives repo list.
- [ ] Elastic returns structured platform update context.
- [ ] Runtime MR Agent clones or fetches the GitLab repo into an isolated workspace.
- [ ] Antigravity CLI Coding Worker reads the cloned GitLab repo workspace.
- [ ] Antigravity CLI Coding Worker creates code changes in the cloned workspace.
- [ ] Runtime MR Agent inspects generated diff before commit.
- [ ] GitLab branch is created.
- [ ] GitLab Merge Request is created.
- [ ] Developer receives MR link in Telegram.
- [ ] Human reviewer can approve or request changes.
- [ ] No secret key is committed to the public repository.

---

# Non-Goals for MVP

- [ ] Auto-merge to main branch.
- [ ] Full multi-user dashboard.
- [ ] Full scheduled scanning.
- [ ] Support for every Google/Apple policy.
- [ ] Support for non-Flutter repositories.
- [ ] Perfect validation for every repo environment.

---

# Security Checklist

- [ ] Never commit `.env`.
- [ ] Use `.env.example` only.
- [ ] Store Telegram token in runtime secrets.
- [ ] Store GitLab token in runtime secrets.
- [ ] Store Elastic read/write API keys in runtime secrets.
- [ ] Give Runtime MR Agent Elastic read access only.
- [ ] Give Policy Context Agent Elastic write/upsert access only.
- [ ] Store Antigravity auth/config in runtime secrets or user-scoped CLI config.
- [ ] Use least-privilege GitLab token.
- [ ] Do not expose secrets in MR description.
- [ ] Do not send secrets to Telegram.
- [ ] Do not log secrets in OpenClaw.

---

# Suggested README Tagline

```txt
PatchPilot — AI agent that turns mobile platform policy updates into GitLab Merge Requests for Flutter teams.
```
