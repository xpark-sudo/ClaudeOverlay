#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/Applications/ClaudeOverlay.app"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP="$(cd "$SCRIPT_DIR/.." && pwd)/.build/ClaudeOverlay.app"

echo "Installing ClaudeOverlay..."

# 1. Build if needed
if [ ! -d "$SOURCE_APP" ]; then
    echo "  Building..."
    bash "$SCRIPT_DIR/build.sh"
fi

# 2. Install app
echo "  Installing app to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
cp -R "$SOURCE_APP" "$INSTALL_DIR"

# 3. Create prefs directory
mkdir -p "${HOME}/.claude/claude-overlay"

echo ""
echo "Installation complete!"
echo ""

# Auto-configure login item via LaunchAgent
echo "  Configuring auto-launch..."
bash "$SCRIPT_DIR/launch-at-login.sh"

echo ""
echo "  Run ClaudeOverlay:  open $INSTALL_DIR"
echo "  Remove from startup: launchctl unload ~/Library/LaunchAgents/com.claudeoverlay.app.plist"
