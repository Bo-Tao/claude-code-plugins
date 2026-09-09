# Otty Plugin

Report Claude Code's state to the [Otty](https://otty.app) terminal app, so each pane shows a
processing / idle / awaiting-input badge for the agent running inside it.

## Overview

Otty normally installs these hooks into `~/.claude/settings.json` itself (Settings → Agents →
Install Hooks), with absolute paths baked into every entry. This plugin does the same job as a
versioned, portable plugin instead:

- No absolute paths in your settings — the app is located at runtime
- Works when Otty lives in `~/Applications`, or anywhere via `OTTY_APP`
- Silently does nothing when Otty isn't installed, so the same config is safe on other machines

## How It Works

| Event | Reported state |
|-------|----------------|
| SessionStart | `idle` |
| UserPromptSubmit | `processing` |
| PreToolUse | `processing` |
| PostToolUse | `processing` |
| PermissionRequest | `awaiting` (forwards the hook payload so Otty can offer auto-approve context) |
| Stop | `idle` |

`hooks/otty-state.sh` is a thin wrapper: it locates `Otty.app`, then `exec`s the hook script that
ships **inside the app bundle**
(`Contents/Resources/agent-integration/claude/otty-hook.sh`) and lets it talk to `otty-cli`.

That bundled script is code-signed with Otty and holds all the protocol details — session id
parsing, `--dangerously-skip-permissions` detection, suppressing the spurious "task complete" that
fires per Task subagent, base64 payload forwarding. Delegating to it keeps a single source of
truth: when Otty updates, this plugin needs no changes.

Lookup order for the app:

1. `$OTTY_APP`
2. `/Applications/Otty.app`
3. `~/Applications/Otty.app`

If none of them holds an executable hook script, the wrapper exits 0 without output.

`"$PPID"` is passed from `hooks.json` rather than read inside the script: the shell Claude Code
spawns for a hook has the Claude process as its parent, and Otty needs that pid to match the event
to a pane (and to ignore a nested `claude -p` fired by a subagent).

## Requirements

- macOS with [Otty](https://otty.app) installed
- Claude Code with plugin support

## Installation

```
/plugin marketplace add Bo-Tao/claude-code-plugins
/plugin install otty@botao-plugins
```

Manual:

```bash
git clone https://github.com/Bo-Tao/claude-code-plugins.git
claude --plugin-dir ./claude-code-plugins/plugins/otty
```

### Remove Otty's own hooks first

The plugin and Otty's built-in installer do the same thing. If both are active, every event runs
the hook twice. After installing this plugin, either use Otty → Settings → Agents → **Uninstall
Hooks**, or delete the entries in `~/.claude/settings.json` whose command contains `otty-hook.sh`.

## Configuration

| Variable | Purpose |
|----------|---------|
| `OTTY_APP` | Absolute path to `Otty.app` when it lives outside the two default locations |
| `OTTY_CLI` | Absolute path to `otty-cli`; derived from the resolved app when unset |

## Troubleshooting

**Badges never update** — check that the app is where the wrapper looks:

```bash
ls /Applications/Otty.app/Contents/Resources/agent-integration/claude/otty-hook.sh
```

**Verify the hook end to end** with a stand-in `otty-cli` that just logs its arguments:

```bash
cat > /tmp/fake-otty-cli <<'EOF'
#!/bin/sh
echo "$@" >> /tmp/otty-args.log
EOF
chmod +x /tmp/fake-otty-cli

echo '{"session_id":"test"}' | OTTY_CLI=/tmp/fake-otty-cli \
  ~/.claude/plugins/.../plugins/otty/hooks/otty-state.sh processing $$
cat /tmp/otty-args.log
# state:claude session-id=test state=processing bypass=0 agent-pid=<pid>
```

**States reported twice** — Otty's own hooks are still in `~/.claude/settings.json`; see above.

## License

MIT
