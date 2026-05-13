#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${HOME}/Applications/ClaudeOverlay.app/Contents/MacOS/ClaudeOverlay"
PLIST_PATH="${HOME}/Library/LaunchAgents/com.claudeoverlay.app.plist"
LABEL="com.claudeoverlay.app"

if [ ! -f "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found. Run install.sh first."
    exit 1
fi

mkdir -p "${HOME}/Library/LaunchAgents"

cat > "$PLIST_PATH" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${APP_PATH}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
PLIST

# Unload first in case it's already loaded
launchctl unload "$PLIST_PATH" 2>/dev/null || true
# Load the agent (starts immediately + registers for next login)
launchctl load "$PLIST_PATH"

echo "ClaudeOverlay will now start automatically at login."
echo "  Plist: $PLIST_PATH"
echo "  Status: $(launchctl list "$LABEL" 2>&1 | head -1)"

# Note: launchctl load above already starts the app via RunAtLoad
echo "  App launched."
