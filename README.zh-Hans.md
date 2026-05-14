# ClaudeOverlay

<p align="center">
  <a href="README.md">English</a> | <b>中文</b>
</p>

Claude Code 桌面悬浮监控工具。**不需要切换回终端**，悬浮窗实时显示会话状态，被阻塞时变红提醒。零 hook、零配置——直接读取 Claude Code 自身的会话数据。

## 为什么选择 ClaudeOverlay？

Claude Code 执行中经常弹出权限确认或提问。一旦切到其他窗口，很容易错过，AI 就卡住了。**ClaudeOverlay 在所有桌面空间显示一个悬浮窗**，实时彩色状态一目了然。看到红色？点一下跳回终端处理。

### 同类对比

| 工具 | 桌面悬浮 | 阻塞红警 | 零配置 | 多项目 |
|------|:---:|:---:|:---:|:---:|
| **ClaudeOverlay** | ✅ | ✅ | ✅ | ✅ |
| ccalert | ❌ (仅通知) | ❌ | ✅ | ❌ |
| vibemon | ✅ | ❌ | ✅ | ✅ |
| unitmux | ✅ (需 tmux) | ✅ | ❌ | ❌ |

## 工作原理

三个零配置数据源，不需要任何 hook：

1. **`~/.claude/sessions/<pid>.json`** — Claude Code 原生维护：PID、状态(busy/idle)、工作目录
2. **进程树检测** — 检查是否有子进程在跑，区分「工具执行中」和「权限弹窗阻塞」
3. **Transcript 尾行解析** — 读 `~/.claude/projects/` 的最后事件，检测 AskUserQuestion 和 pending tool_use

```
~/.claude/sessions/<pid>.json ──→ PID、状态、目录
         │
         ├── pgrep -P <pid> ──→ 有子进程？→ 工具执行 / 被阻塞
         │
         └── transcript 尾行 ──→ AskUserQuestion？tool_use 未结束？
                  │
                  ▼
           状态：△ 红 / ● 黄 / ↩ 橙
```

## 功能特性

- **零配置**：不写 hook，不改 settings.json，不安 shell 脚本。装了就能用
- **阻塞红警**：权限弹窗、AskUserQuestion 等阻塞场景立即变红 △
- **进程感知**：通过子进程检测判断真实阻塞状态，不靠猜工具名
- **智能跳转**：点击会话直接激活对应终端窗口（iTerm2、VS Code、Terminal.app 等都支持）
- **多项目**：一个悬浮窗看所有 Claude Code 会话
- **全局快捷键**：`Cmd+Shift+C` 呼出/隐藏
- **轻量**：SwiftUI，< 1MB，每 1 秒轮询

## 环境要求

- macOS 12.0+
- 已安装 [Claude Code](https://claude.ai/code) CLI

## 快速安装

```bash
git clone https://github.com/xpark-sudo/ClaudeOverlay.git
cd ClaudeOverlay
bash scripts/install.sh
```

编译并安装 `ClaudeOverlay.app` 到 `~/Applications/`，配置开机自启。

## 卸载

```bash
pkill -f ClaudeOverlay
launchctl unload ~/Library/LaunchAgents/com.claudeoverlay.app.plist
rm -f ~/Library/LaunchAgents/com.claudeoverlay.app.plist
rm -rf ~/Applications/ClaudeOverlay.app
```

不需要清理 hook 配置。

## 从源码构建

```bash
git clone https://github.com/xpark-sudo/ClaudeOverlay.git
cd ClaudeOverlay
swift build -c release
bash scripts/build.sh
open .build/ClaudeOverlay.app
```

## 开源协议

MIT — 详见 [LICENSE](LICENSE)。
