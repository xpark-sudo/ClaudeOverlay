#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/Applications/ClaudeOverlay.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="xpark-sudo/ClaudeOverlay"
TMP_DIR="$(mktemp -d)"
trap "rm -rf '$TMP_DIR'" EXIT

echo "Installing ClaudeOverlay..."

# 1. Try downloading pre-built binary first
echo "  Fetching latest release..."
DOWNLOAD_URL=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
    | grep -o '"browser_download_url": *"[^"]*ClaudeOverlay.app.zip"' \
    | head -1 \
    | grep -o 'https://[^"]*' || true)

if [ -n "${DOWNLOAD_URL}" ]; then
    echo "  Downloading pre-built app..."
    curl -fsSL "${DOWNLOAD_URL}" -o "$TMP_DIR/ClaudeOverlay.app.zip"
    echo "  Extracting..."
    unzip -qo "$TMP_DIR/ClaudeOverlay.app.zip" -d "$TMP_DIR"
    SOURCE_APP="$TMP_DIR/ClaudeOverlay.app"
else
    # 2. Fall back to building from source
    echo "  No pre-built binary found, building from source..."
    SOURCE_APP="$(cd "$SCRIPT_DIR/.." && pwd)/.build/ClaudeOverlay.app"
    if [ ! -d "$SOURCE_APP" ]; then
        bash "$SCRIPT_DIR/build.sh"
    fi
fi

# 3. Install app
echo "  Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
cp -R "$SOURCE_APP" "$INSTALL_DIR"

# 4. Create prefs directory
mkdir -p "${HOME}/.claude/claude-overlay"

echo ""
echo "Installation complete!"
echo ""

# Auto-configure login item
echo "  Configuring auto-launch..."
bash "$SCRIPT_DIR/launch-at-login.sh"

echo ""
echo "  Run:  open $INSTALL_DIR"
echo "  Stop: launchctl unload ~/Library/LaunchAgents/com.claudeoverlay.app.plist"
