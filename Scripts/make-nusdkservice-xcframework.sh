#!/bin/bash
#
# Builds Frameworks/nuSDKService.xcframework from the CocoaPods release zip.
#
# nuSDKService ships as a plain .framework, which SwiftPM cannot consume —
# binary targets require an .xcframework. Run this whenever the version pinned
# in NexilisLite.podspec changes, then commit the regenerated xcframework.
#
# Usage: Scripts/make-nusdkservice-xcframework.sh [version]
#        (version defaults to the one below)
#
set -euo pipefail

VERSION="${1:-5.0.2}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
URL="https://nexilis.io/UCPaaSiOS/nusDKService/v${VERSION}/nuSDKService.zip"
OUT="${ROOT}/Frameworks/nuSDKService.xcframework"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# nexilis.io answers 403 to curl's default user agent, so pose as CocoaPods.
USER_AGENT="CocoaPods/1.16.2 cocoapods-downloader"

echo "==> Downloading nuSDKService ${VERSION}"
echo "    ${URL}"
if curl -fL --progress-bar -A "$USER_AGENT" -o "${WORK}/nuSDKService.zip" "$URL"; then
    echo "==> Unpacking"
    unzip -q "${WORK}/nuSDKService.zip" -d "${WORK}/unpacked"
    SEARCH_ROOT="${WORK}/unpacked"
else
    # Fall back to whatever `pod install` already downloaded, so the script
    # still works offline / if the download endpoint changes.
    CACHE="$(find "${HOME}/Library/Caches/CocoaPods/Pods/Release/nuSDKService" \
        -maxdepth 1 -type d -name "${VERSION}-*" 2>/dev/null | head -1)"
    if [ -z "$CACHE" ]; then
        echo "error: download failed and no CocoaPods cache for ${VERSION} found" >&2
        exit 1
    fi
    echo "==> Download failed; using CocoaPods cache at ${CACHE}"
    SEARCH_ROOT="$CACHE"
fi

# CocoaPods zips are often built on macOS and carry resource forks that make
# codesigning/xcframework packaging complain.
find "$SEARCH_ROOT" -name '__MACOSX' -type d -prune -exec rm -rf {} + 2>/dev/null || true
find "$SEARCH_ROOT" -name '.DS_Store' -delete 2>/dev/null || true

FRAMEWORK="$(find "$SEARCH_ROOT" -name 'nuSDKService.framework' -maxdepth 3 -type d | head -1)"
if [ -z "$FRAMEWORK" ]; then
    echo "error: nuSDKService.framework not found in ${SEARCH_ROOT}" >&2
    exit 1
fi

echo "==> Slices in the shipped binary:"
lipo -info "${FRAMEWORK}/nuSDKService"

echo "==> Packaging xcframework"
mkdir -p "${ROOT}/Frameworks"
rm -rf "$OUT"
xcodebuild -create-xcframework -framework "$FRAMEWORK" -output "$OUT"

echo
echo "==> Done: ${OUT}"
echo "    Remember to commit it, and to bump s.version in NexilisLite.podspec."
