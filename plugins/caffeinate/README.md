# Caffeinate Plugin

Prevent Mac from sleeping while Claude Code is running.

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

## Requirements

- macOS (uses native `caffeinate` command)
- Claude Code with plugin support

## Installation

### Claude Code (add marketplace)

Register the marketplace first:

```
/plugin marketplace add Bo-Tao/claude-code-plugins
```

Then install the plugin:

```
/plugin install caffeinate@botao-plugins
```

### Manual Installation

```bash
git clone https://github.com/Bo-Tao/claude-code-plugins.git
claude --plugin-dir ./claude-code-plugins/plugins/caffeinate
```

## Technical Details

- **PID file**: `/tmp/claude_caffeinate.pid`
- **Timeout**: 1 hour (3600 seconds), reset on each prompt
- **caffeinate flags**: `-i` (prevent idle sleep) `-t 3600` (timeout)

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
