#!/usr/bin/env bash
# ClaudeOverlay Status Hook
# Reads hook event JSON from stdin, writes status files.
# For AskUserQuestion: blocks until user responds via overlay.
set -euo pipefail

STATUS_DIR="/tmp/claude-sessions"
mkdir -p "$STATUS_DIR"

INPUT="$(cat)"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] INPUT=$INPUT" >> /tmp/hook-debug.log

# Parse fields from stdin JSON
HOOK_EVENT="$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('hook_event_name',''))" 2>/dev/null || true)"
CWD="$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || true)"
TOOL_NAME="$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || true)"

# Derive project ID from cwd: replace / with -, strip leading -
PROJECT_ID="$(echo "$CWD" | sed 's|/|-|g' | sed 's/^-//')"
PROJECT_NAME="$(basename "$CWD")"
STATUS_FILE="${STATUS_DIR}/${PROJECT_ID}.json"
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

write_status() {
    local status="$1"
    local confirm_id="${2:-}"
    local terminal="${3:-}"
    python3 -c "
import json, os

cid = None
if '${confirm_id}' != '':
    cid = '${confirm_id}'

# Detect terminal type from environment, fall back to existing file value
term = '${terminal}'
if not term:
    if os.environ.get('TERM_PROGRAM') == 'vscode' or os.environ.get('VSCODE_IPC_HANDLE'):
        term = 'VSCode'
    elif os.environ.get('ITERM_SESSION_ID') or os.environ.get('ITERM_PROFILE'):
        term = 'iTerm2'
    elif os.environ.get('TERM_PROGRAM') == 'Apple_Terminal':
        term = 'Terminal'
    elif os.path.exists('${STATUS_FILE}'):
        try:
            with open('${STATUS_FILE}') as f:
                term = json.load(f).get('terminalType', 'Unknown')
        except: pass
if not term:
    term = 'Unknown'

d = {
    'projectId': '${PROJECT_ID}',
    'projectName': '${PROJECT_NAME}',
    'projectPath': '${CWD}',
    'status': '${status}',
    'lastUpdated': '${NOW}',
    'terminalType': term,
    'hasConfirmation': $( [ "$status" = "needs_confirmation" ] && echo "True" || echo "False" ),
    'confirmationId': cid
}
with open('${STATUS_FILE}', 'w') as f:
    json.dump(d, f, indent=2)
"
}

# ============================================
# Event: SessionStart
# ============================================
if [ "$HOOK_EVENT" = "SessionStart" ]; then
    TERM_TYPE="Unknown"
    if [ "${TERM_PROGRAM:-}" = "vscode" ] || [ -n "${VSCODE_IPC_HANDLE:-}" ]; then
        TERM_TYPE="VSCode"
    elif [ -n "${ITERM_SESSION_ID:-}" ] || [ -n "${ITERM_PROFILE:-}" ]; then
        TERM_TYPE="iTerm2"
    elif [ "${TERM_PROGRAM:-}" = "Apple_Terminal" ]; then
        TERM_TYPE="Terminal"
    fi
    write_status "running" "" "$TERM_TYPE"
    exit 0
fi

# ============================================
# Event: PreToolUse (non-AskUserQuestion)
# Bash/Write/WebFetch/WebSearch may trigger permission prompts → red
# Read/Glob/Grep/Edit and others auto-execute → yellow
# ============================================
if [ "$HOOK_EVENT" = "PreToolUse" ] && [ "$TOOL_NAME" != "AskUserQuestion" ]; then
    case "$TOOL_NAME" in
        Bash|WebFetch|WebSearch)
            write_status "needs_confirmation" ;;
        *)
            write_status "running" ;;
    esac
    exit 0
fi

# ============================================
# Event: PostToolUse — tool completed, back to running
# ============================================
if [ "$HOOK_EVENT" = "PostToolUse" ]; then
    write_status "running"
    exit 0
fi

# ============================================
# Event: PreToolUse (AskUserQuestion)
# ============================================
if [ "$HOOK_EVENT" = "PreToolUse" ] && [ "$TOOL_NAME" = "AskUserQuestion" ]; then
    write_status "needs_confirmation"
    echo '{"permissionDecision":"allow"}'
    exit 0
fi

# ============================================
# Event: Stop
# ============================================
if [ "$HOOK_EVENT" = "Stop" ]; then
    write_status "waiting_input"
    exit 0
fi

# Default: no-op
exit 0
