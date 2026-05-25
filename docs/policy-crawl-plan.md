# Policy Crawl Plan

PatchPilot uses Elastic as the platform-policy context layer. This is not a
general web crawler. It should crawl a curated set of official sources that can
produce actionable GitLab Merge Requests for Flutter repositories.

This is a separate ingestion flow. It should run as a scheduled worker or manual
admin job, not inline with every Telegram `/check` request.

## Goal

Convert official mobile platform policy and release information into structured
update records that OpenClaw can use to decide whether Antigravity CLI should
edit a Flutter repository.

## Source Priority

Use official sources first. Avoid random blogs, forum posts, and social media in
the MVP.

### Android / Google Play

Primary sources:

- Google Play target API requirement:
  `https://developer.android.com/google/play/requirements/target-sdk`
- Google Play policy overview:
  `https://support.google.com/googleplay/android-developer/answer/11917020`
- Android SDK platform release notes:
  `https://developer.android.com/tools/releases/platforms`
- Android Gradle Plugin release notes:
  `https://developer.android.com/studio/releases/gradle-plugin`
- Android behavior changes by version:
  `https://developer.android.com/about/versions`

What to extract:

- Required `targetSdk` / target API level.
- Required `compileSdk` or SDK platform availability.
- Android Gradle Plugin version changes.
- Gradle, Kotlin, Java, namespace, manifest, signing, and build behavior changes.
- Runtime permission, privacy, storage, foreground service, notification, and
  predictive-back changes that affect Flutter Android projects.

Likely affected files:

- `android/app/build.gradle`
- `android/app/build.gradle.kts`
- `android/build.gradle`
- `android/build.gradle.kts`
- `android/settings.gradle`
- `android/settings.gradle.kts`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/gradle.properties`
- `android/app/src/main/AndroidManifest.xml`
- `pubspec.yaml`

### Apple / App Store / iOS

Primary sources:

- App Store submission requirements:
  `https://developer.apple.com/app-store/submitting/`
- Upcoming requirements:
  `https://developer.apple.com/news/upcoming-requirements/`
- App Review Guidelines:
  `https://developer.apple.com/app-store/review/guidelines/`
- Xcode release notes:
  `https://developer.apple.com/documentation/xcode-release-notes`
- App Store support overview:
  `https://developer.apple.com/support/app-store/`

What to extract:

- Minimum Xcode / SDK requirements for App Store submission.
- iOS, iPadOS, tvOS, visionOS, and watchOS SDK submission deadlines.
- Required entitlements or capability configuration.
- Privacy, tracking, receipt, signing, notarization, and App Store Review
  changes that can affect native iOS Flutter project files.

Likely affected files:

- `ios/Podfile`
- `ios/Runner/Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`
- `ios/Runner/Runner.entitlements`
- `ios/Flutter/AppFrameworkInfo.plist`
- `pubspec.yaml`

### Flutter / Dart

Primary sources:

- Flutter breaking changes and migration guides:
  `https://docs.flutter.dev/release/breaking-changes`
- Flutter iOS deployment:
  `https://docs.flutter.dev/deployment/ios`
- Flutter Android deployment:
  `https://docs.flutter.dev/deployment/android`
- Flutter release notes:
  `https://docs.flutter.dev/release/release-notes`

What to extract:

- Flutter breaking changes that affect Android/iOS native folders.
- Flutter Gradle plugin migration requirements.
- Kotlin, Gradle, CocoaPods, Xcode, Dart SDK, and pubspec constraints.
- Removed/deprecated APIs when `dart fix` or project-level migration may apply.

Likely affected files:

- `pubspec.yaml`
- `analysis_options.yaml`
- `android/settings.gradle`
- `android/build.gradle`
- `android/app/build.gradle`
- `ios/Podfile`
- `ios/Runner/Info.plist`

## Structured Record Schema

Elastic should store normalized records with fields like:

```json
{
  "source": "google_android | google_play | apple_app_store | apple_xcode | flutter_docs",
  "platform": "android | ios | flutter",
  "title": "Google Play target API level requirement",
  "url": "https://developer.android.com/google/play/requirements/target-sdk",
  "content": "Cleaned source text",
  "summary": "Apps must target Android 15 API level 35 or later for Google Play submission.",
  "requirement_type": "target_sdk | sdk_submission | build_tool | permission | entitlement | breaking_change",
  "detected_requirement": "targetSdk >= 35",
  "effective_date": "2025-08-31",
  "affected_files": [
    "android/app/build.gradle",
    "android/app/src/main/AndroidManifest.xml"
  ],
  "recommended_action": "Inspect targetSdk, compileSdk, AGP compatibility, and Android permission behavior.",
  "severity": "info | warning | publishing_blocker",
  "last_crawled_at": "2026-05-25T00:00:00Z"
}
```

## Coding Task Context Payload

When OpenClaw queries Elastic during `/check`, it should transform matching
records into a coding-task payload for Antigravity. The payload should be
specific enough that Antigravity can edit the repo without browsing random
sources.

```json
{
  "task_type": "native_compliance_update",
  "repo_url": "https://gitlab.com/company/flutter-app",
  "workspace_path": "/workspace/jobs/job-123/repo",
  "platform": "android",
  "policy_context": {
    "title": "Google Play target API level requirement",
    "summary": "New apps and updates must target Android 15 API level 35 or later.",
    "source_urls": [
      "https://developer.android.com/google/play/requirements/target-sdk"
    ],
    "effective_date": "2025-08-31",
    "severity": "publishing_blocker",
    "detected_requirement": "targetSdk >= 35",
    "requirement_type": "target_sdk"
  },
  "repo_facts": {
    "detected_files": [
      "android/app/build.gradle",
      "android/gradle/wrapper/gradle-wrapper.properties",
      "pubspec.yaml"
    ],
    "current_values": {
      "targetSdk": "33",
      "compileSdk": "33",
      "android_gradle_plugin": "7.4.2",
      "gradle_wrapper": "7.5"
    }
  },
  "expected_changes": [
    {
      "file": "android/app/build.gradle",
      "change": "Update targetSdk and compileSdk if compatible."
    },
    {
      "file": "android/gradle/wrapper/gradle-wrapper.properties",
      "change": "Update Gradle wrapper only if required by Android Gradle Plugin compatibility."
    }
  ],
  "constraints": [
    "Edit only files inside workspace_path.",
    "Prefer minimal native configuration changes.",
    "Do not modify app business logic unless explicitly required.",
    "Do not commit, push, or create the MR; OpenClaw handles GitLab operations.",
    "Include validation status and changed file summary."
  ],
  "validation_commands": [
    "flutter analyze",
    "flutter test"
  ]
}
```

Required fields for Antigravity:

- `workspace_path`: where the cloned repo is located.
- `platform`: `android`, `ios`, or `flutter`.
- `policy_context.summary`: plain-language reason for the change.
- `policy_context.source_urls`: official references to cite in the MR.
- `policy_context.detected_requirement`: concrete requirement, such as
  `targetSdk >= 35` or `iOS SDK >= 26`.
- `repo_facts.detected_files`: files that exist in the cloned repo.
- `repo_facts.current_values`: current native config values detected by
  OpenClaw before invoking Antigravity.
- `expected_changes`: bounded file/change hints.
- `constraints`: hard guardrails.
- `validation_commands`: commands Antigravity may attempt if available.

## AI Responsibilities in the Context Layer

The crawler itself should be deterministic: fetch selected official URLs,
extract readable text, clean it, and store metadata.

AI can be used after fetch to:

- Summarize the policy update.
- Classify platform and requirement type.
- Extract dates, API levels, SDK versions, tool versions, and affected files.
- Decide whether the update is actionable for a Flutter repo.
- Produce a structured update description for OpenClaw.

AI should not:

- Invent requirements not present in the official source.
- Browse arbitrary sources during MVP.
- Modify GitLab repositories from the Elastic layer.
- Commit or open Merge Requests.

## OpenClaw Orchestrator Responsibilities

OpenClaw is the runtime orchestrator for repository checks. It should:

- Receive Telegram input.
- Query Elastic for already-indexed structured context.
- Decide no-action vs action-needed.
- Clone/fetch the GitLab repo into an isolated workspace.
- Generate the Antigravity task prompt.
- Invoke Antigravity CLI.
- Inspect the generated diff boundary.
- Commit, push, create MR, and notify Telegram.

Antigravity is the coding worker. Elastic is the context layer. OpenClaw is the
orchestrator.

## Runtime Boundary

When a developer submits a repo, PatchPilot should not crawl Google, Apple, or
Flutter docs in that request path. The runtime flow should only query Elastic
records created by this ingestion flow.
