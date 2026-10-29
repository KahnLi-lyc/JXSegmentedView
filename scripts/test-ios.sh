#!/bin/bash
set -euo pipefail
# Supply a dedicated, booted Simulator UUID; this script never selects others.
SIMULATOR_ID="${1:?Usage: scripts/test-ios.sh <dedicated-simulator-uuid> [derived-data-path]}"
DERIVED_DATA="${2:-/tmp/JXSegmentedView-SPM-DerivedData}"
cd "$(dirname "$0")/.."
# The upstream root .xcodeproj has a non-test scheme with the same name.
# Ensure the minimal package workspace exists even in exports omitting .swiftpm.
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
xcodebuild -workspace "$PACKAGE_WORKSPACE" \
  -scheme JXSegmentedView \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$DERIVED_DATA" test
