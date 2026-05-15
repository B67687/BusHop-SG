#!/usr/bin/env bash
# ── One-command local quality check ──
# Runs lint + tests + APK verification. Exit code 0 = everything clean.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "═══ Lint ═══"
./gradlew lint
echo ""
echo "═══ Tests ═══"
./gradlew test
echo ""
echo "═══ APK verification ═══"
./gradlew checkAndRenameDebugApk
echo ""
echo "✅ All checks passed."
