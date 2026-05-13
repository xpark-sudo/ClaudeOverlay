# ClaudeOverlay

<p align="center">
  <b>English</b> | <a href="README.zh-Hans.md">中文</a>
</p>

The first desktop overlay for Claude Code that lets you monitor sessions and see when attention is needed — **without switching back to the terminal**. When Claude needs your approval or answer, the overlay turns red. Click to jump back and keep things moving.

![License](https://img.shields.io/github/license/xpark-sudo/ClaudeOverlay)
![Platform](https://img.shields.io/badge/platform-macOS%2012.0%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)

## Why ClaudeOverlay?

Claude Code CLI often pauses to ask for confirmation ("Approve this tool call?"). If you've switched to another window, you'll miss it — and the AI sits idle. **ClaudeOverlay shows a floating window on your desktop** that stays visible across all spaces, displaying real-time project status with color-coded indicators. See a red alert? Click to jump back to your terminal and handle it.

### vs. Alternatives

| Tool | Desktop Overlay | Status Alerts | No Terminal Required | Multi-Project |
|------|:---:|:---:|:---:|:---:|
| **ClaudeOverlay** | Yes | Yes | Yes | Yes |
| ccalert | No (notification) | No | Yes | No |
| vibemon | Yes | No | Yes | Yes |
| unitmux | Yes (requires tmux) | Yes | No | No |
| agtop | No (TUI) | No | No | Yes |

## Features

- **Floating Overlay**: Frosted glass window visible on all Spaces, doesn't steal focus
- **Red Alert on Block**: Turns red △ when Claude needs your approval (permission prompts, AskUserQuestion) — flow is blocked until you act
- **Auto-clear**: Red automatically clears to yellow ● once confirmed, no manual dismiss needed
- **Smart Jump**: Click any project to jump directly to its terminal (iTerm2 / VS Code)
- **Multi-Project**: Monitor all your Claude Code sessions in one view
- **Global Hotkey**: `Cmd+Shift+C` to show/hide the overlay
- **Lightweight**: Built with SwiftUI, app bundle < 2MB, minimal CPU/memory

## Screenshots

<!-- TODO: Add GIF/screenshots -->

## Requirements

- macOS 12.0+ (Monterey or later)
- Apple Silicon or Intel Mac
- [Claude Code](https://claude.ai/code) CLI installed

## Quick Install

```bash
git clone https://github.com/xpark-sudo/ClaudeOverlay.git
cd ClaudeOverlay
bash scripts/install.sh
```

This will:
1. Build the SwiftUI app
2. Install `ClaudeOverlay.app` to `~/Applications/`
3. Install the hook script to `~/.claude/claude-status-hook.sh`
4. Merge hook configuration into `~/.claude/settings.json`

### Launch on startup

```bash
bash scripts/launch-at-login.sh
```

Or manually add `~/Applications/ClaudeOverlay.app` to Login Items in System Settings.

## How It Works

```
Claude Code Session
    │
    ├── SessionStart  ──→ hook ──→ ● running
    ├── PreToolUse     ──→ hook ──→ △ red (Bash/Write/WebFetch/WebSearch/AskUserQuestion)
    │                               └── other tools → ● yellow
    ├── PostToolUse    ──→ hook ──→ ● clear red (tool completed)
    └── Stop           ──→ hook ──→ ↩ idle
                    ▲
                    │ (polls /tmp/claude-sessions/ every 0.2s)
                    │
            ClaudeOverlay.app
                    │
        User sees red △ → clicks to jump to terminal
                    │
        Approves/answers in terminal
                    │
        PostToolUse clears red → ●
```

## File Structure

```
~/.claude/
├── settings.json                  # hooks config (auto-merged by install)
├── claude-status-hook.sh          # hook script
└── claude-overlay/
    └── preferences.json           # user settings

/tmp/claude-sessions/              # per-project status files (auto-cleaned after 5 min idle)
```

## Uninstall

```bash
# Stop the app
pkill -f ClaudeOverlay

# Remove from startup
launchctl unload ~/Library/LaunchAgents/com.claudeoverlay.app.plist
rm -f ~/Library/LaunchAgents/com.claudeoverlay.app.plist

# Remove app and hook script
rm -rf ~/Applications/ClaudeOverlay.app
rm -f ~/.claude/claude-status-hook.sh
```

Hooks are merged into `~/.claude/settings.json`. To fully remove, manually edit that file and delete the `SessionStart`, `PreToolUse`, `PostToolUse`, and `Stop` sections under `hooks`.

## Build from Source

```bash
git clone https://github.com/xpark-sudo/ClaudeOverlay.git
cd ClaudeOverlay
swift build -c release
bash scripts/build.sh
open .build/ClaudeOverlay.app
```

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

## License

MIT — see [LICENSE](LICENSE) for details.
