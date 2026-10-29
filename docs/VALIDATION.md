# Validation recorded 2026-10-29

Environment: Xcode 27.1 (27A9275), Apple Swift 6.4, iOS 27.0 Simulator,
iPhone 17 Pro. Dedicated test device:
`94435F39-3E09-4B3B-AFB7-C322B1F12A2F` (`CC Dependency Forks 20261029`).
No existing device belonging to another task was used.

## Baseline before source fixes

The checked-in package test target was added first, while library source remained
at `fbbf965d7396bd99ac1ce88a80b6c950b85313f6`.

- The 10 initial tests executed on the Simulator: **15 assertion failures**.
- Failures reproduced selected press/cancel, unselected highlight, scroll-gradient
  replacement, active animation replacement, mask color replacement, reuse color,
  and selected/per-index font width clipping.
- Closure, fixed-width, zoom and privacy checks passed at baseline.
- Xcode test action exited 65. The initial root Xcode-project scheme was not used
  for this evidence; the SwiftPM workspace was selected explicitly.

## After patches

Command:

```sh
scripts/test-ios.sh 94435F39-3E09-4B3B-AFB7-C322B1F12A2F /tmp/cc-jxseg-derived
```

- Initial suite after fixes: **10 tests, 0 failures**.
- Expanded final suite (gradient layer and mask-to-plain reuse included):
  **12 tests, 0 failures**, `TEST SUCCEEDED`, exit 0.
- `swift package dump-package` and `git diff --check`: pass.

Local diagnostic artifacts (ephemeral; no logs are required in the repository):

- Baseline: `/tmp/cc-jxseg-red.log`.
- Initial green: `/tmp/cc-jxseg-green.log`.
- Final green: `/tmp/cc-jxseg-final.log`.
- Final result bundle:
  `/tmp/cc-jxseg-derived/Logs/Test/Test-JXSegmentedView-2026.10.29_10-58-27-+0800.xcresult`.

These are library regressions, not app end-to-end or physical-device evidence.

## Clean source export check

The regression entry was also run from `/tmp/cc-jxseg-clean-tlbxwjfa`, a separate
snapshot containing only current tracked/nonignored source files with **all
`.swiftpm` content deliberately omitted**. A fresh DerivedData directory was
used. The script generated its minimal package workspace, resolved this local
package, and completed **12 tests with 0 failures**, exit 0.

```sh
scripts/test-ios.sh 94435F39-3E09-4B3B-AFB7-C322B1F12A2F /tmp/cc-jxseg-clean-derived
```

Evidence: `/tmp/cc-jxseg-clean.log` and
`/tmp/cc-jxseg-clean-derived/Logs/Test/Test-JXSegmentedView-2026.10.29_11-05-02-+0800.xcresult`.
The ordinary upstream workspace file is tracked, but the fallback also supports
exports that omit it. The script never replaces an existing workspace.

## Master maintenance migration — 2026-10-29

The migration worktree retains the tested source tree from `f92aa529378f7d5ef3f39e5ac226864f9d2c6094`.
`Sources`, `Tests`, `Package.swift`, `LICENSE`, and `scripts/test-ios.sh` are byte-identical
to that revision. Only README and maintenance documents change.
The old master `49d8b0755f4877febd3251471e3347880f785c96` is retained as the second parent of a
one-time history reconciliation; its later upstream source changes are not adopted.
See [the review ledger](UPSTREAM_REVIEW.md).

A dedicated iPhone 17 Pro / iOS 27 Simulator `A2FF0624-DBA8-48E2-B504-8547CF5C1783` ran the
actual SwiftPM package tests with Xcode 27.1 / Swift 6.4:

```sh
xcodebuild -jobs 2 -workspace .swiftpm/xcode/package.xcworkspace -scheme JXSegmentedView -destination platform=iOS\ Simulator,id=A2FF0624-DBA8-48E2-B504-8547CF5C1783 -parallel-testing-enabled NO -collect-test-diagnostics never test
```

- **12 tests, 0 failures**, `TEST SUCCEEDED`, exit 0.
- `swift package dump-package`, shell syntax, privacy manifest lint, Markdown local
  links, unchanged runtime-tree comparison and `git diff --check`: pass.
- The existing upstream `automaticallyAdjustsScrollViewInsets` deprecation and Xcode test sysroot / AppIntents metadata diagnostics were recorded separately. No warning was suppressed or source modified to silence it.
- Test log: `/var/folders/99/z2m_xqws3mq2jll1t05vm0fc0000gn/T/jx-master-migration-20261029-1ftt_bvl/JXSegmentedView-test.log`.
- Result bundle: `/var/folders/99/z2m_xqws3mq2jll1t05vm0fc0000gn/T/jx-master-migration-20261029-1ftt_bvl/JXSegmentedView.xcresult`.

The command used a fresh external DerivedData directory and result bundle, with
`-jobs 2` to limit machine load. Only verbose failure diagnostic collection was
disabled; test assertions and package compilation were unchanged. Existing
consumer revisions remain pinned; this is not a Swift 6 language-mode migration
or a new physical-device / consumer-application validation.
