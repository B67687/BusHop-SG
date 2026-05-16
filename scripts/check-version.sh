#!/usr/bin/env bash
# ── Pre-commit version check: prevents tag/APK version mismatch ──
# Runs automatically via .git/hooks/pre-commit (symlink or copy)
set -euo pipefail

BKC="app/build.gradle.kts"
VERSION=$(grep versionName "$BKC" | sed 's/.*"\(.*\)".*/\1/')

# Check if the latest tag matches the version
LATEST_TAG=$(git tag --sort=-version:refname | grep -E '^v?[0-9]' | head -1)
TAG_VERSION="${LATEST_TAG#v}"

if [ -n "$TAG_VERSION" ] && [ "$TAG_VERSION" != "$VERSION" ]; then
	# This might be intentional if you're working between releases
	# Just warn, don't block
	echo "⚠️  Version mismatch: build.gradle.kts says $VERSION but latest tag is v$TAG_VERSION"
	echo "   If you're about to tag a new release, make sure the version is bumped first."
fi
