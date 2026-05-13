#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/Applications/ClaudeOverlay.app"
HOOK_SCRIPT="${HOME}/.claude/claude-status-hook.sh"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_APP="$(cd "$SCRIPT_DIR/.." && pwd)/.build/ClaudeOverlay.app"
SETTINGS_FILE="${HOME}/.claude/settings.json"

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

# 3. Install hook script
echo "  Installing hook script..."
cp "$SCRIPT_DIR/claude-status-hook.sh" "$HOOK_SCRIPT"
chmod +x "$HOOK_SCRIPT"

# 4. Create required directories
mkdir -p /tmp/claude-sessions
mkdir -p "${HOME}/.claude/claude_pending_responses"
mkdir -p "${HOME}/.claude/claude-overlay"

# 5. Merge hook configuration into settings.json
echo "  Configuring hooks..."
python3 -c "
import json, os, shutil

settings_path = os.path.expanduser('$SETTINGS_FILE')
hooks_config = {
    'hooks': {
        'SessionStart': [{
            'matcher': 'startup|resume|clear|compact',
            'hooks': [{
                'type': 'command',
                'command': 'bash ~/.claude/claude-status-hook.sh',
                'timeout': 5
            }]
        }],
        'PreToolUse': [{
            'matcher': '.*',
            'hooks': [{
                'type': 'command',
                'command': 'bash ~/.claude/claude-status-hook.sh',
                'timeout': 5
            }]
        }],
        'PostToolUse': [{
            'matcher': '.*',
            'hooks': [{
                'type': 'command',
                'command': 'bash ~/.claude/claude-status-hook.sh',
                'timeout': 5
            }]
        }],
        'Stop': [{
            'hooks': [{
                'type': 'command',
                'command': 'bash ~/.claude/claude-status-hook.sh',
                'timeout': 5
            }]
        }]
    }
}

settings = {}
if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)
    # Backup
    shutil.copy2(settings_path, settings_path + '.bak')

settings.update(hooks_config)

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)

print(f'  Hooks installed to {settings_path}')
"

echo ""
echo "Installation complete!"
echo ""

# Auto-configure login item via LaunchAgent
echo "  Configuring auto-launch..."
bash "$SCRIPT_DIR/launch-at-login.sh"

echo ""
echo "  Run ClaudeOverlay:  open $INSTALL_DIR"
echo "  Remove from startup: launchctl unload ~/Library/LaunchAgents/com.claudeoverlay.app.plist"
