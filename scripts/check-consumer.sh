#!/bin/bash
set -euo pipefail
# Two independent host targets pin their language modes in the fixture manifest.
# Do not set SWIFT_VERSION here: it would also override the Swift 6 dependency.
# Usage: scripts/check-consumer.sh [fresh-output-directory] [--] [xcodebuild arguments...]
SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIRECTORY=""
if [[ $# -gt 0 && "$1" != -* && "$1" != *=* ]]; then
  OUTPUT_DIRECTORY="$1"
  shift
fi
if [[ "${1:-}" == -- ]]; then shift; fi
if [[ -z "$OUTPUT_DIRECTORY" ]]; then
  OUTPUT_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/JXSegmentedView-Consumer.XXXXXX")"
fi
mkdir -p "$OUTPUT_DIRECTORY"
OUTPUT_DIRECTORY="$(cd "$OUTPUT_DIRECTORY" && pwd)"
cd "$SCRIPT_DIRECTORY/../Fixtures/Consumer"
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
status=0
for mode in 5 6; do
  echo "Building Swift $mode consumer of the Swift 6 JXSegmentedView package"
  if ! xcodebuild -workspace "$PACKAGE_WORKSPACE" -scheme "ConsumerSwift$mode" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$OUTPUT_DIRECTORY/Swift$mode/DerivedData" \
    -resultBundlePath "$OUTPUT_DIRECTORY/Swift$mode.xcresult" \
    -jobs "${XCODEBUILD_JOBS:-2}" \
    SWIFT_STRICT_CONCURRENCY=complete CODE_SIGNING_ALLOWED=NO \
    "$@" build 2>&1 | tee "$OUTPUT_DIRECTORY/Swift$mode.log"; then
    status=1
  fi
done
if ! "$SCRIPT_DIRECTORY/check-concurrency-diagnostics.sh" "$OUTPUT_DIRECTORY"/Swift*.log; then
  status=1
fi
exit "$status"
