# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Code plugins marketplace (`botao-plugins`): macOS utility plugins that extend Claude Code through hooks. Currently ships one plugin, `caffeinate`.

## Repository Structure

```
.claude-plugin/marketplace.json   # Marketplace manifest (lists all plugins)
plugins/{plugin-name}/
  .claude-plugin/plugin.json      # Plugin manifest
  hooks/hooks.json                # Hook definitions
  hooks/*.sh                      # Hook scripts (must be chmod +x)
  README.md                       # Plugin documentation
```

## Creating a New Plugin

1. `plugins/{name}/.claude-plugin/plugin.json` — plugin manifest
2. `plugins/{name}/hooks/hooks.json` — hook definitions
3. `plugins/{name}/hooks/*.sh` — bash scripts, `chmod +x`
4. `plugins/{name}/README.md` — usage docs
5. Register the plugin in `.claude-plugin/marketplace.json`
6. Validate both manifests (see Verification)

### plugin.json

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "...",
  "author": { "name": "Botao" },
  "keywords": ["..."]
}
```

### marketplace.json entry

Same `name` / `version` / `description` / `author`, plus `source` (`./plugins/{name}`), `category`, `tags`.

Gotcha: those fields are duplicated across the two files and must stay in sync — `claude plugin tag` refuses to tag a release when they disagree. Bump both on every version change.

### hooks.json

```json
{
  "description": "...",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/foo.sh", "timeout": 5 }
        ]
      }
    ]
  }
}
```

Events used here: `SessionStart` (session begins), `UserPromptSubmit` (prompt submitted), `Stop` (Claude finishes responding). Claude Code supports more (`PreToolUse`, `PostToolUse`, `SessionEnd`, `SubagentStop`, `PreCompact`, `Notification`).

### Hook Script Guidelines

- Reference plugin files via `${CLAUDE_PLUGIN_ROOT}`; never hardcode absolute paths
- Keep `timeout` at 5s — these hooks fire on every event, so they must be fast
- Keep scripts silent (`> /dev/null 2>&1`): `SessionStart` / `UserPromptSubmit` stdout is injected into Claude's context
- Put state files in `/tmp/` (e.g. `/tmp/claude_caffeinate.pid`)
- Scripts must be idempotent: re-running replaces prior state, and a recorded PID is re-checked (`ps -p ... -o args=`) before being killed, so a recycled PID is never signalled
- `chmod +x` before committing — git must record mode `100755` or the hook silently fails

## Verification

```bash
claude plugin validate ./plugins/{name}   # plugin manifest
claude plugin validate .                  # marketplace manifest
claude --plugin-dir ./plugins/{name}      # load locally and exercise in a real session
```

## Conventions

- Conventional Commits (`chore:`, `feat:`, `fix:`)
- `.gitignore` excludes `docs/` and `.claude/`, so design docs under `docs/plans/` stay local and are never committed
