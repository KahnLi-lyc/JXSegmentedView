#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "$(xcodegen --version)" != "Version: 2.46.0" ]]; then
  echo "Use XcodeGen 2.46.0 for deterministic Demo generation" >&2; exit 1
fi
python3 scripts/check-demo-coverage.py
xcodegen generate --spec Demo/project.yml
git diff --exit-code -- Demo/JXSegmentedViewDemo.xcodeproj
if [[ -n "$(git ls-files --others --exclude-standard Demo/JXSegmentedViewDemo.xcodeproj)" ]]; then
  echo "Generated project contains untracked files" >&2; exit 1
fi
