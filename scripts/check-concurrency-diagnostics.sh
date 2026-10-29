#!/bin/bash
set -euo pipefail
if [[ $# -eq 0 ]]; then
  echo "Usage: scripts/check-concurrency-diagnostics.sh <build-log> [...]" >&2
  exit 2
fi
# Keep all warnings visible. Gate concurrency warnings specifically so unrelated
# deprecation and SDK/sysroot diagnostics are neither hidden nor promoted.
pattern='warning:.*(actor-isolat|actor isolated|actor isolation|[Mm]ain[Aa]ctor|[Gg]lobal[Aa]ctor|[Ss]endable|concurren|isolation|nonisolated|data race|sending |task-isolated|region-isolated)'
failed=0
for log in "$@"; do
  if [[ ! -f "$log" ]]; then
    echo "Missing build log: $log" >&2
    exit 2
  fi
  if LC_ALL=C grep -En "$pattern" "$log"; then
    failed=1
  fi
done
if [[ "$failed" -ne 0 ]]; then
  echo "New concurrency warning diagnostics are not allowed." >&2
  exit 1
fi
