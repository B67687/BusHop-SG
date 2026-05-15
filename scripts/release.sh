#!/usr/bin/env bash
# ── BusHop release script ──
# Usage: ./scripts/release.sh [patch|minor]
# Steps: clean build → verify APK → commit → tag → push → create GitHub Release → upload APK
set -euo pipefail

cd "$(dirname "$0")/.."
VERSION=$(grep versionName app/build.gradle.kts | sed 's/.*"\(.*\)".*/\1/')
TAG="v$VERSION"
APK_PATH="app/build/outputs/apk/debug/app-debug-bus-hop.apk"

echo "═══ Building BusHop v$VERSION ═══"

# 1. Clean build with APK verification
./gradlew clean checkAndRenameDebugApk

# 2. Verify APK exists and has proper size
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK not found at $APK_PATH"
    exit 1
fi
APK_SIZE=$(stat -c%s "$APK_PATH" 2>/dev/null || stat -f%z "$APK_PATH" 2>/dev/null)
if [ "$APK_SIZE" -lt 1000000 ]; then
    echo "❌ APK suspiciously small (${APK_SIZE} bytes) — aborting"
    exit 1
fi
echo "✅ APK verified: $APK_PATH ($(( APK_SIZE / 1024 )) KB)"

# 3. Check for existing tag
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "⚠️  Tag $TAG already exists locally"
    read -rp "Delete existing tag and release? (y/N) " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        gh release delete "$TAG" --yes 2>/dev/null || true
        git tag -d "$TAG" 2>/dev/null || true
        git push origin --delete "$TAG" 2>/dev/null || true
    else
        echo "Aborted."
        exit 1
    fi
fi

# 4. Commit, tag, push
git add -A
git commit -m "$TAG: release"
git tag "$TAG"
git push origin master --tags

# 5. Create GitHub Release and upload APK
gh release create "$TAG" \
    --title "$TAG" \
    --notes "See commits for details." \
    --verify-tag \
    --latest

gh release upload "$TAG" "$APK_PATH" --clobber

echo ""
echo "═══ ✅ $TAG released ═══"
echo "Download: https://github.com/B67687/BusHop-SG/releases/tag/$TAG"
