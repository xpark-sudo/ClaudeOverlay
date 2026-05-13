# ClaudeOverlay

<p align="center">
  <a href="README.md">English</a> | <b>中文</b>
</p>

首个 Claude Code 桌面悬浮监控工具 —— **无需切回终端**，即可实时查看会话状态。当 AI 需要你确认或回答时，悬浮窗变红提醒，点击跳回终端处理。

## 为什么选择 ClaudeOverlay？

Claude Code CLI 执行过程中经常需要用户确认（"是否批准此工具调用？"）。一旦你切换到其他窗口工作，很容易错过确认节点，导致 AI 任务卡住。**ClaudeOverlay 在你的桌面上显示一个悬浮窗**，跨所有桌面空间可见，实时展示项目状态。看到红色提醒后点击即可跳回终端处理。

### 同类工具对比

| 工具 | 桌面悬浮 | 状态提醒 | 无需终端 | 多项目 |
|------|:---:|:---:|:---:|:---:|
| **ClaudeOverlay** | ✅ | ✅ | ✅ | ✅ |
| ccalert | ❌ (仅通知) | ❌ | ✅ | ❌ |
| vibemon | ✅ | ❌ | ✅ | ✅ |
| unitmux | ✅ (需 tmux) | ✅ | ❌ | ❌ |
| agtop | ❌ (TUI) | ❌ | ❌ | ✅ |

## 功能特性

- **桌面悬浮窗**：毛玻璃效果窗口，在所有桌面空间可见，不抢占焦点
- **红色阻塞提醒**：当 AI 需要你确认（权限弹窗、AskUserQuestion），悬浮窗立即变红 △ — 不操作就卡住
- **自动消红**：确认完成后自动恢复黄色 ●，不需要手动关闭
- **智能跳转**：点击项目条目自动跳转到对应的终端（iTerm2 / VS Code），无需手动切换窗口
- **多项目概览**：一目了然所有 Claude Code 会话状态
- **全局快捷键**：`Cmd+Shift+C` 呼出/隐藏悬浮窗
- **极致轻量**：SwiftUI 构建，安装包 < 2MB，极低 CPU/内存占用

## 效果演示

<!-- TODO: 添加演示 GIF -->

## 环境要求

- macOS 12.0+ (Monterey 及以上)
- Apple Silicon 或 Intel Mac
- 已安装 [Claude Code](https://claude.ai/code) CLI

## 快速安装

```bash
git clone https://github.com/xpark-sudo/ClaudeOverlay.git
cd ClaudeOverlay
bash scripts/install.sh
```

安装程序将自动：
1. 编译 SwiftUI 应用
2. 安装 `ClaudeOverlay.app` 到 `~/Applications/`
3. 安装 hook 脚本到 `~/.claude/claude-status-hook.sh`
4. 将 hook 配置合并到 `~/.claude/settings.json`

### 开机启动

```bash
bash scripts/launch-at-login.sh
```

或手动将 `~/Applications/ClaudeOverlay.app` 添加到系统设置的「登录项」中。

## 工作原理

```
Claude Code 会话
    │
    ├── SessionStart  ──→ hook ──→ ● 运行中
    ├── PreToolUse     ──→ hook ──→ △ 红色（Bash/Write/WebFetch/WebSearch/AskUserQuestion）
    │                               └── 其他工具 → ● 黄色
    ├── PostToolUse    ──→ hook ──→ ● 消红（工具执行完毕）
    └── Stop           ──→ hook ──→ ↩ 空闲
                    ▲
                    │ (每 0.2s 轮询 /tmp/claude-sessions/)
                    │
            ClaudeOverlay.app
                    │
        用户看到红色 △ → 点击跳转终端
                    │
        在终端中批准 / 回答问题
                    │
        PostToolUse 自动消红 → ●
```

## 文件结构

```
~/.claude/
├── settings.json                  # hooks 配置（安装时自动合并）
├── claude-status-hook.sh          # hook 脚本
└── claude-overlay/
    └── preferences.json           # 用户偏好设置

/tmp/claude-sessions/              # 各项目状态文件（空闲 5 分钟后自动清理）
```

## 卸载

```bash
# 停止应用
pkill -f ClaudeOverlay

# 移除开机启动
launchctl unload ~/Library/LaunchAgents/com.claudeoverlay.app.plist
rm -f ~/Library/LaunchAgents/com.claudeoverlay.app.plist

# 删除应用和脚本
rm -rf ~/Applications/ClaudeOverlay.app
rm -f ~/.claude/claude-status-hook.sh
```

hooks 配置已合并到 `~/.claude/settings.json` 中，如需完全移除请手动编辑该文件，删除 `hooks` 下的 `SessionStart`、`PreToolUse`、`PostToolUse`、`Stop` 段落。

## 从源码构建

```bash
git clone https://github.com/xpark-sudo/ClaudeOverlay.git
cd ClaudeOverlay
swift build -c release
bash scripts/build.sh
open .build/ClaudeOverlay.app
```

## 参与贡献

欢迎提交贡献！请先开 Issue 讨论你希望修改的内容。

## 开源协议

MIT — 详见 [LICENSE](LICENSE)。
