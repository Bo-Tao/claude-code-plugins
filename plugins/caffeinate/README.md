# Caffeinate Plugin

Prevent Mac from sleeping while Claude Code is running.

## ⚠️ Deprecated

Claude Code ships its own sleep inhibitor on macOS and has since roughly 2.1.156, so
this plugin is redundant — installing it just adds a second `caffeinate` assertion on
top of the built-in one.

The built-in inhibitor spawns `caffeinate -i -t 300` while a turn is active, renews it
every 4 minutes, and kills it about 30 seconds after the agent goes idle. Verified in
2.1.266, whose binary contains the strings `Restarting sleep inhibitor to maintain
prevention` and `Stopped sleep inhibitor, allowing sleep`.

| | Built-in | This plugin |
|---|---|---|
| Command | `caffeinate -i -t 300` | `caffeinate -i -t 3600` |
| Lifecycle | Renewed while the turn is active, killed on idle | `UserPromptSubmit` → `Stop` |
| Long runs | Renewed indefinitely | Hard 1-hour cap, protection lapses after that |
| While idle | No assertion held | `SessionStart` holds one for up to an hour |

The built-in behavior is undocumented and cannot be turned off — the internal disable
flag is compiled to `false`, and no settings key or environment variable gates it (see
[anthropics/claude-code#21432](https://github.com/anthropics/claude-code/issues/21432),
[#82283](https://github.com/anthropics/claude-code/issues/82283),
[#85261](https://github.com/anthropics/claude-code/issues/85261)). So there is nothing
this plugin can add on top, and no way for it to opt out on your behalf.

Kept here for reference. Everything below describes the original behavior.

## Overview

This plugin automatically manages your Mac's sleep state during Claude Code sessions:

- **Prevents sleep** when a session starts or when you submit a prompt
- **Allows sleep** when Claude stops responding (task complete)
- **Auto-resets** the 1-hour timer with each new prompt

## How It Works

Uses macOS's built-in `caffeinate` command with Claude Code's hooks system:

| Event | Action |
|-------|--------|
| SessionStart | Start caffeinate (prevent sleep) |
| UserPromptSubmit | Restart caffeinate (reset 1-hour timer) |
| Stop | Kill caffeinate (allow sleep) |

## Technical Details

- **PID file**: `/tmp/claude_caffeinate.pid`
- **Timeout**: 1 hour (3600 seconds), reset on each prompt
- **caffeinate flags**: `-i` (prevent idle sleep) `-t 3600` (timeout)

## Requirements

- macOS (uses native `caffeinate` command)
- Claude Code with plugin support

## Installation

```
/plugin marketplace add Bo-Tao/claude-code-plugins
/plugin install caffeinate@botao-plugins
```

Manual:

```bash
git clone https://github.com/Bo-Tao/claude-code-plugins.git
claude --plugin-dir ./claude-code-plugins/plugins/caffeinate
```

## Troubleshooting

### Check if caffeinate is running

```bash
cat /tmp/claude_caffeinate.pid && ps -p $(cat /tmp/claude_caffeinate.pid)
```

### Manually stop caffeinate

```bash
kill $(cat /tmp/claude_caffeinate.pid) 2>/dev/null
rm /tmp/claude_caffeinate.pid
```

## License

MIT
