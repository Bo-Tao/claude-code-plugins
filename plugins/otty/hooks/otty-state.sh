#!/bin/sh

# Report Claude Code's state to Otty by delegating to the hook script that ships
# inside Otty.app — that copy is code-signed with the app and carries all the
# protocol details (session id parsing, bypass-mode detection, Task subagent
# Stop suppression, PermissionRequest payload forwarding), so it stays the
# single source of truth and follows Otty's own updates.
#
# Args:
#   $1  state      — processing | idle | awaiting
#   $2  claude_pid — "$PPID" as passed from hooks.json, i.e. the Claude process
#   $3  "ctx"      — PermissionRequest only: forward the full hook payload
# Env:
#   OTTY_APP — absolute path to Otty.app, when installed outside the defaults
#   OTTY_CLI — absolute path to otty-cli; derived from OTTY_APP when unset

state="$1"
claude_pid="$2"

# hooks.json passes "$PPID", which the shell running the hook resolves to the
# Claude process (its own parent). Fall back to this script's parent if it ever
# arrives unexpanded or empty.
case "$claude_pid" in
    ''|*[!0-9]*) claude_pid="$PPID" ;;
esac

for app in "$OTTY_APP" "/Applications/Otty.app" "$HOME/Applications/Otty.app"; do
    [ -n "$app" ] || continue
    hook="$app/Contents/Resources/agent-integration/claude/otty-hook.sh"
    [ -x "$hook" ] || continue

    OTTY_CLI="${OTTY_CLI:-$app/Contents/MacOS/otty-cli}"
    export OTTY_CLI

    # exec keeps stdin intact — the bundled script reads the hook payload from it.
    exec "$hook" "$state" "$claude_pid" "$3"
done

# Otty isn't installed: stay silent so a missing app never breaks the session.
exit 0
