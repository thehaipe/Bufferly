#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Bufferfly — Automated Archive → Notarize → GitHub Release
# ─────────────────────────────────────────────────────────────
# Usage:
#   ./scripts/release.sh              # build + notarize only
#   ./scripts/release.sh --publish   # + create GitHub Release (tag from Xcode version)
#
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT="$PROJECT_DIR/Bufferfly.xcodeproj"
SCHEME="Bufferfly"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/Bufferfly.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"
KEYCHAIN_PROFILE="Bufferfly-Notarize"

# Read version from Xcode project
VERSION=$(grep 'MARKETING_VERSION' "$PROJECT/project.pbxproj" | grep -o '[0-9]\+\.[0-9]\+[\.0-9]*' | head -1)
if [[ -z "$VERSION" ]]; then
    fail "Could not read MARKETING_VERSION from project.pbxproj"
fi
TAG="v.${VERSION}"

# Parse arguments
PUBLISH=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --publish)
            PUBLISH=true
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: $0 [--publish]"
            exit 1
            ;;
    esac
done

# ── Helpers ──────────────────────────────────────────────────

step() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

fail() {
    echo "ERROR: $1" >&2
    exit 1
}

# ── Preflight checks ────────────────────────────────────────

step "Preflight checks"

command -v xcodebuild >/dev/null 2>&1 || fail "xcodebuild not found. Make sure Xcode is installed and selected: sudo xcode-select -s /Applications/Xcode.app"
command -v xcrun >/dev/null 2>&1 || fail "xcrun not found"
command -v ditto >/dev/null 2>&1 || fail "ditto not found"

if $PUBLISH; then
    command -v gh >/dev/null 2>&1 || fail "GitHub CLI not found. Install with: brew install gh"
fi

# Verify Xcode (not just Command Line Tools)
XCODE_PATH=$(xcode-select -p 2>/dev/null)
if [[ "$XCODE_PATH" == */CommandLineTools ]]; then
    fail "Active developer directory is Command Line Tools. Switch to Xcode:\n  sudo xcode-select -s /Applications/Xcode.app"
fi

echo "Xcode: $XCODE_PATH"
echo "Project: $PROJECT"
echo "Scheme: $SCHEME"
echo "Version: $VERSION (tag: $TAG)"

# ── Clean build directory ────────────────────────────────────

step "1/6  Cleaning build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
echo "Done."

# ── Archive ──────────────────────────────────────────────────

step "2/6  Archiving"
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -quiet \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    DEVELOPMENT_TEAM=4RM8QA94J7

echo "Archive created at: $ARCHIVE_PATH"

# ── Export ───────────────────────────────────────────────────

step "3/6  Exporting with Developer ID"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_DIR" \
    -quiet

# Find the .app (handles any product name)
APP_PATH=$(find "$EXPORT_DIR" -name "*.app" -maxdepth 1 | head -1)
if [[ -z "$APP_PATH" ]]; then
    fail "No .app found in $EXPORT_DIR"
fi

APP_NAME=$(basename "$APP_PATH" .app)
echo "Exported: $APP_PATH"

# ── Notarize ─────────────────────────────────────────────────

step "4/6  Creating zip for notarization"
ZIP_PATH="$BUILD_DIR/${APP_NAME}.zip"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "Created: $ZIP_PATH"

step "5/6  Submitting for notarization (this may take a few minutes)"
xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait

echo "Notarization successful."

# ── Staple ───────────────────────────────────────────────────

step "6/6  Stapling notarization ticket"
xcrun stapler staple "$APP_PATH"

# Re-create zip after stapling
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "Final zip: $ZIP_PATH"

# ── Verify ───────────────────────────────────────────────────

step "Verification"
echo "Checking Gatekeeper assessment..."
spctl --assess --type execute --verbose=2 "$APP_PATH" 2>&1 || true
echo ""
echo "Checking staple status..."
xcrun stapler validate "$APP_PATH" 2>&1 || true

# ── Publish to GitHub ────────────────────────────────────────

if $PUBLISH; then
    step "Publishing to GitHub Releases ($TAG)"

    RELEASE_NOTES="## Bufferfly ${TAG}

- Version: ${VERSION}
- Signed with Developer ID
- Notarized by Apple

### Installation
1. Download \`${APP_NAME}.zip\`
2. Unzip and drag \`${APP_NAME}.app\` to Applications
3. Open from Applications — no extra steps needed"

    gh release create "$TAG" \
        "$ZIP_PATH" \
        --title "Bufferfly $TAG" \
        --notes "$RELEASE_NOTES"

    echo ""
    echo "Release published: $TAG"
    gh release view "$TAG" --json url -q '.url'
fi

# ── Done ─────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Done! Ready for distribution."
echo "  Zip: $ZIP_PATH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
