# Master Maintenance Implementation Plan

> **For agentic workers:** Use inline execution for this repository maintenance task. Steps use checkbox syntax for tracking.

**Goal:** Establish master as the independent fork maintenance branch without changing tested runtime behavior.

**Architecture:** Reconcile the old master history into the tested spm tree once, document deferred upstream content, and fast-forward master after validation. Keep spm frozen and configure upstream separately.

**Tech Stack:** Git, SwiftPM, XCTest, GitHub repository settings.

This is the pre-execution checklist; recorded results belong to `docs/VALIDATION.md` and the delivery report.

---

### Task 1: Reconcile and document

- [ ] Inspect clean branches, origin refs, and the upstream release base.
- [ ] Create isolated `codex/master-maintenance` from spm and run `git merge --no-commit --no-ff -s ours master`.
- [ ] Verify `git diff --cached --name-only` is empty before documentation edits.
- [ ] Update README and maintenance notes; add BRANCHING.md and UPSTREAM_REVIEW.md with exact baseline and deferred commits.

### Task 2: Verify

- [ ] Run `scripts/test-ios.sh A2FF0624-DBA8-48E2-B504-8547CF5C1783` or the equivalent package test command with bounded build concurrency; expect 12 passing tests.
- [ ] Run `swift package dump-package`, `bash -n scripts/test-ios.sh`, `plutil -lint Sources/PrivacyInfo.xcprivacy`, and `git diff --check`.
- [ ] Compare runtime files, manifest, tests, resources and license with `f92aa529378f7d5ef3f39e5ac226864f9d2c6094`; expect no difference.

### Task 3: Deliver

- [ ] Commit the history merge and maintenance documents after validation; verify both old branches are ancestors.
- [ ] Fast-forward local master, add upstream remote, and push only origin master without force.
- [ ] Set the GitHub default branch to master and refresh local origin/HEAD; verify remote master and frozen spm revisions.
- [ ] Verify clean local master and remove only the task-created temporary worktree and merged temporary branch.
