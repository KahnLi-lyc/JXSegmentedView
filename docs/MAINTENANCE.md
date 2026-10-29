# Independent SwiftPM maintenance

- Fork: https://github.com/KahnLi-lyc/JXSegmentedView
- Active maintenance and default branch: `master`.
- Frozen compatibility branch: `spm`; existing pinned commits remain valid.
- Upstream: https://github.com/pujiaxin33/JXSegmentedView
- Exact base: `fbbf965d7396bd99ac1ce88a80b6c950b85313f6` (1.4.1).
- Original MIT license, author notices, public API, source directories, examples,
  and Git history are preserved. No upstream tag is moved or replaced.

## Patches

UIKit calls the base cell's selection styling callback for both `isSelected`
and `isHighlighted`. The upstream title callback chooses a normal/selected
endpoint based on those UIKit flags. Those flags are independent of the
segmented model: cancelling a touch can turn an already-selected title normal,
and scrolling/animation can lose its intermediate color. The title callback now
uses `titleCurrentColor`. Mask rendering and active selection animations retain
ownership of their label colors and layers; the callback neither reloads nor
restarts animations. This also applies to title subclasses without a new API.

Automatic title measurement reserves the larger width of the normal and selected
fonts resolved at the requested index, rounding up once. A nil selected font
falls back to that index's normal font. The existing external width closure is
returned unchanged; fixed item widths, increments, and downstream zoom scaling
keep their original behavior. As upstream documents, title zoom assumes matching
normal and selected fonts.

## Verify

Use Xcode and a dedicated booted iOS Simulator (no CocoaPods or app checkout):

```sh
scripts/test-ios.sh <simulator-uuid>
```

The upstream-tracked SwiftPM workspace is specified explicitly because the root
Xcode project has a scheme of the same name without the package tests. The script
also generates the minimal workspace deterministically if `.swiftpm` was omitted
from a source export; it does not replace an existing workspace.
Tests use the real package target and XCTest on iOS. They cover selected touch
press/cancel, unselected highlight, scroll interpolation, active selected
animation, reuse, mask colors/layers, the gradient cell, Chinese/Arabic text,
per-index font configuration, nil selected fonts, closure/fixed width/zoom, and
the packaged privacy manifest. See `VALIDATION.md` for recorded baseline/results.

## Branch maintenance

`master` is the active default branch. Work on `feature/*` or `fix/*`, run the
package regressions, and merge into `master` before updating consumers.
The one-time history reconciliation keeps the tested `spm` source tree; it does
not adopt later upstream changes merely because their commits are ancestors.
See [branching](BRANCHING.md) and the explicit [upstream review ledger](UPSTREAM_REVIEW.md).

## Swift 6 maintenance

Current SPM requirements: Swift tools 6.0, Swift 6 language mode, iOS 16.
The adopted upstream release baseline is unchanged. Concurrency/lifecycle patches
are fork-owned; see [migration guide](SWIFT6_MIGRATION.md) and actual validation.
Original license, authorship and privacy resources are retained.
