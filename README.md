# ClaudeOverlay

<p align="center">
  <b>English</b> | <a href="README.zh-Hans.md">中文</a>
</p>

A desktop overlay for Claude Code that monitors sessions and alerts you when attention is needed — **without switching back to the terminal**. No hooks, no config files — reads Claude Code's own session data directly.

![License](https://img.shields.io/github/license/xpark-sudo/ClaudeOverlay)
![Platform](https://img.shields.io/badge/platform-macOS%2012.0%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)

## Why ClaudeOverlay?

Claude Code CLI often pauses for permission prompts or questions. If you've switched to another window, you'll miss it — and the AI sits idle. **ClaudeOverlay shows a floating window** visible across all Spaces with real-time status. Red alert? Click to jump back to your terminal.

### vs. Alternatives

| Tool | Desktop Overlay | Red Alert on Block | No Hooks Needed | Multi-Project |
|------|:---:|:---:|:---:|:---:|
| **ClaudeOverlay** | Yes | Yes | Yes | Yes |
| ccalert | No (notification) | No | Yes | No |
| vibemon | Yes | No | Yes | Yes |
| unitmux | Yes (requires tmux) | Yes | No | No |

## How It Works

ClaudeOverlay reads three zero-config data sources — no hooks, no settings.json changes:

1. **`~/.claude/sessions/<pid>.json`** — Claude Code writes these natively: PID, status (busy/idle), working directory
2. **Process tree** — detects child processes to distinguish "tool running" from "blocked waiting for permission"
3. **Transcript tail** — reads the last events from `~/.claude/projects/` to detect AskUserQuestion and pending tool calls

```
~/.claude/sessions/<pid>.json ──→ PID, status, cwd
         │
         ├── pgrep -P <pid> ──→ child processes? → tool running vs blocked
         │
         └── transcript tail ──→ AskUserQuestion? pending tool_use?
                  │
                  ▼
           Status: △ red / ● yellow / ↩ idle
```

## Features

- **Zero config**: No hooks, no settings.json modification, no shell scripts. Just install and run.
- **Red alert on block**: Turns red △ when Claude needs your input (permission prompts, AskUserQuestion)
- **Process-aware**: Detects actual blocking by checking child processes — not guessing by tool name
- **Smart jump**: Click any session to activate its terminal window (works with iTerm2, VS Code, Terminal.app, and others)
- **Multi-project**: Monitor all Claude Code sessions in one view
- **Global hotkey**: `Cmd+Shift+C` to show/hide
- **Lightweight**: SwiftUI, < 1MB, polls every 1s

## Requirements

- macOS 12.0+
- [Claude Code](https://claude.ai/code) CLI installed

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/xpark-sudo/ClaudeOverlay/main/scripts/install.sh | bash
```

This downloads the pre-built app — **no Xcode required**.

## Uninstall

```bash
pkill -f ClaudeOverlay
launchctl unload ~/Library/LaunchAgents/com.claudeoverlay.app.plist
rm -f ~/Library/LaunchAgents/com.claudeoverlay.app.plist
rm -rf ~/Applications/ClaudeOverlay.app
```

No hooks to clean up.

### Build from Source (for developers)

```bash
git clone https://github.com/xpark-sudo/ClaudeOverlay.git
cd ClaudeOverlay
swift build -c release
bash scripts/build.sh
open .build/ClaudeOverlay.app
```

## License

MIT — see [LICENSE](LICENSE) for details.
