#!/bin/bash
set -euo pipefail
# Supply a dedicated, booted Simulator UUID; this script never selects others.
SIMULATOR_ID="${1:?Usage: scripts/test-ios.sh <dedicated-simulator-uuid> [derived-data-path] [--] [xcodebuild arguments...]}"
shift
DERIVED_DATA="${TMPDIR:-/tmp}/JXSegmentedView-SPM-DerivedData"
if [[ $# -gt 0 && "$1" != -* && "$1" != *=* ]]; then
  DERIVED_DATA="$1"
  shift
fi
if [[ "${1:-}" == -- ]]; then shift; fi
cd "$(dirname "$0")/.."
# Explicitly select the package workspace, even when an upstream .xcodeproj exists.
PACKAGE_WORKSPACE=".swiftpm/xcode/package.xcworkspace"
if [[ ! -f "$PACKAGE_WORKSPACE/contents.xcworkspacedata" ]]; then
  mkdir -p "$PACKAGE_WORKSPACE"
  cat > "$PACKAGE_WORKSPACE/contents.xcworkspacedata" <<'WORKSPACE'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version="1.0">
  <FileRef location="self:"></FileRef>
</Workspace>
WORKSPACE
fi
xcodebuild -workspace "$PACKAGE_WORKSPACE" -scheme JXSegmentedView \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  -jobs "${XCODEBUILD_JOBS:-2}" \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  "$@" test
