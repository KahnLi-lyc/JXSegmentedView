#!/bin/bash
set -euo pipefail
SIMULATOR_ID="${1:?Usage: scripts/test-demo.sh <dedicated-booted-simulator-uuid> <output-directory> [xcodebuild arguments...]}"
OUTPUT="${2:?Supply a fresh output directory}"
shift 2
cd "$(dirname "$0")/.."
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
if [[ -e "$OUTPUT/Demo.xcresult" ]]; then
  echo "Refusing to overwrite existing Demo.xcresult" >&2
  exit 1
fi
set -o pipefail
xcodebuild -project Demo/JXSegmentedViewDemo.xcodeproj -scheme JXSegmentedViewDemo \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$OUTPUT/DerivedData" -resultBundlePath "$OUTPUT/Demo.xcresult" \
  -jobs "${XCODEBUILD_JOBS:-2}" -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- "$@" test 2>&1 | tee "$OUTPUT/demo.log"
python3 scripts/check-demo-resources.py "$OUTPUT/DerivedData/Build/Products/Debug-iphonesimulator/JXSegmentedViewDemo.app"
scripts/check-concurrency-diagnostics.sh "$OUTPUT/demo.log"
