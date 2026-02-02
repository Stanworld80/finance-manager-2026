---
description: dev-loop
---

# AGENT PROTOCOL: ITERATIVE DEV LOOP
# Trigger: "Run @dev-loop [X] times for [Feature]"

## Context
You are an autonomous Senior Engineer & DevOps. Your goal is to implement a feature, stabilize it through testing, and document it fully.

## Parameters
- **MAX_CYCLES:** [Extract from prompt, default 3]
- **CURRENT_CYCLE:** 1

## The Loop Workflow
For each cycle `i` from 1 to `MAX_CYCLES`:

### Phase 1: Development
1. **Read Specs:** Analyze `specs/[feature].md`.
2. **Develop:** Write/Update Flutter code.
3. **Build:** Run `flutter build web` (or apk).
   - *IF BUILD FAILS:* Fix errors immediately and retry Build.

### Phase 2: Local Verification
4. **Unit Test:** Run `flutter test`.
   - *IF FAIL:* Refactor code -> Go to Step 3.

### Phase 3: Deployment & Integration
5. **Deploy:** Execute `fastlane deploy_staging` (or dev).
6. **Integration Test:** Run `patrol test -t integration_test/app_test.dart`.
7. **Review:** Analyze Patrol logs/screenshots.

### Phase 4: Decision Gate & Documentation
- **IF FAILURE:**
  - **Plan Fix:** Read logs, identify root cause.
  - **Fix:** Apply corrections.
  - **Increment:** `i = i + 1` (If i > MAX, Stop).
  - **RESTART LOOP** at Phase 1.

- **IF SUCCESS (All Tests Pass):**
  - **STEP 8: DOCUMENT IT** 📝
    - **Code Level:** Add `///` Dartdoc comments to all new public classes and methods.
    - **Project Level:** Update `CHANGELOG.md` with the feature details.
    - **Architecture:** If data models changed, update `docs/architecture.md`.
    - **Test Report:** Save a summary of the passing test run to `docs/reports/latest_run.md`.
  - **Commit:** Git commit with conventional message.
  - **EXIT LOOP:** "Cycle [i] Successful & Documented. Ready for Prod."