#!/usr/bin/env bash
# ── BusHop release script ──
# Usage: ./scripts/release.sh [VERSION]
# Steps: bump version → clean build → tests → APK verify → commit → tag → push → release
set -euo pipefail

cd "$(dirname "$0")/.."
BKC="app/build.gradle.kts"

# Read current version
CURRENT=$(grep versionName "$BKC" | sed 's/.*"\(.*\)".*/\1/')
echo "Current version: v$CURRENT"

# Use provided version or bump patch
NEW="${1:-}"
if [ -z "$NEW" ]; then
	IFS='.' read -r -a PARTS <<<"$CURRENT"
	NEW="${PARTS[0]}.${PARTS[1]}.$((${PARTS[2]:-0} + 1))"
	echo "No version given — bumping to v$NEW"
fi

CODE=$(grep versionCode "$BKC" | sed 's/.*versionCode\s*=\s*\([0-9]*\).*/\1/')
NEXT_CODE=$((CODE + 1))

# 1. Bump version in build.gradle.kts
sed -i "s/versionCode = $CODE/versionCode = $NEXT_CODE/" "$BKC"
sed -i "s/versionName = \"$CURRENT\"/versionName = \"$NEW\"/" "$BKC"

VERSION="$NEW"
TAG="v$VERSION"
echo "═══ Building BusHop v$VERSION (code $NEXT_CODE) ═══"

# 2. Verify versionName matches tag (regression check)
CHECK=$(grep versionName "$BKC" | sed 's/.*"\(.*\)".*/\1/')
if [ "$CHECK" != "$VERSION" ]; then
	echo "❌ Version mismatch: build.gradle.kts says $CHECK, expected $VERSION"
	exit 1
fi

# 3. Clean build with tests + APK verification
./gradlew clean test checkAndRenameDebugApk

APK_PATH="app/build/outputs/apk/debug/bus-hop.apk"
APK_SIZE=$(stat -c%s "$APK_PATH" 2>/dev/null || stat -f%z "$APK_PATH" 2>/dev/null)
if [ "$APK_SIZE" -lt 1000000 ]; then
	echo "❌ APK suspiciously small (${APK_SIZE} bytes) — aborting"
	exit 1
fi
echo "✅ Tests passed, APK verified: $((APK_SIZE / 1024)) KB"

# 4. Commit the version bump (only build.gradle.kts change)
git add "$BKC"
git commit -m "Bump to v$VERSION"
git push

# 5. Tag and push
git tag "$TAG"
git push origin main --tags

# 6. Create GitHub Release and upload APK
gh release create "$TAG" \
	--title "$TAG" \
	--notes "See commits for details." \
	--verify-tag \
	--latest

gh release upload "$TAG" "$APK_PATH" --clobber

echo ""
echo "═══ ✅ $TAG released ═══"
echo "Download: https://github.com/B67687/BusHop-SG/releases/tag/$TAG"
