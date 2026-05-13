#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="ClaudeOverlay"

echo "Building $APP_NAME..."

# Build release binary (native arch)
swift build -c release --product "$APP_NAME"

# Assemble .app bundle
APP_DIR=".build/$APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy executable
cp ".build/release/$APP_NAME" "$APP_DIR/Contents/MacOS/"

# Copy Info.plist (from project root, not Sources/Resources)
cp Info.plist "$APP_DIR/Contents/"

# Copy entitlements
cp ClaudeOverlay.entitlements "$APP_DIR/Contents/Resources/"

# Generate and copy app icon
echo "  Generating icon..."
python3 scripts/generate-icon.py Sources/Resources
cp Sources/Resources/AppIcon.icns "$APP_DIR/Contents/Resources/"
# Copy iconset for SwiftPM resource bundling
cp -R Sources/Resources/AppIcon.iconset "$APP_DIR/Contents/Resources/" 2>/dev/null || true

# Copy localization resources from the compiled bundle
# Find the resource bundle (path varies by architecture)
RESOURCE_BUNDLE=$(find .build -name "ClaudeOverlay_ClaudeOverlay.bundle" -type d 2>/dev/null | head -1)
if [ -n "${RESOURCE_BUNDLE:-}" ] && [ -d "$RESOURCE_BUNDLE" ]; then
    for lproj in "$RESOURCE_BUNDLE"/*.lproj; do
        if [ -d "$lproj" ]; then
            lang="$(basename "$lproj")"
            mkdir -p "$APP_DIR/Contents/Resources/$lang"
            cp "$lproj"/*.strings "$APP_DIR/Contents/Resources/$lang/" 2>/dev/null || true
        fi
    done
fi

# Ad-hoc sign
codesign --force --sign - "$APP_DIR" 2>/dev/null || true

echo ""
echo "Built: $APP_DIR"
echo "Size: $(du -sh "$APP_DIR" | cut -f1)"
