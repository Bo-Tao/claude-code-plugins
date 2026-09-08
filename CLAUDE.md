# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Code plugins marketplace (`botao-plugins`): personal plugins that extend Claude Code through hooks and skills. Ships `caffeinate` (hooks) and `botao-skills` (skills).

## Repository Structure

```
.claude-plugin/marketplace.json   # Marketplace manifest (lists all plugins)
plugins/{plugin-name}/
  .claude-plugin/plugin.json      # Plugin manifest
  hooks/hooks.json                # Hook definitions
  hooks/*.sh                      # Hook scripts (must be chmod +x)
  skills/{skill-name}/SKILL.md    # Agent skills (auto-discovered)
  README.md                       # Plugin documentation
```

## Creating a New Plugin

1. `plugins/{name}/.claude-plugin/plugin.json` — plugin manifest
2. Components the plugin actually needs — `hooks/`, `skills/`, `commands/`, `agents/` (omit the rest)
3. `plugins/{name}/README.md` — usage docs
4. Register the plugin in `.claude-plugin/marketplace.json`
5. Validate both manifests (see Verification)

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

### Skills

Skills live at `plugins/{name}/skills/{skill-name}/SKILL.md` and are auto-discovered — there is nothing to register in `plugin.json` or `hooks.json`.

```markdown
---
name: skill-name
description: Use when <trigger condition>. <What it does.>
---

Instructions for Claude...
```

- The entry file must be named `SKILL.md` exactly; `README.md` is not discovered
- `description` is the only text Claude sees before loading the skill — lead with *when* to use it, since that is what makes it fire
- Supporting files go in the skill's own directory (`references/`, `scripts/`, `assets/`) and are referenced via `${CLAUDE_PLUGIN_ROOT}/skills/{skill-name}/...`
- Keep `SKILL.md` lean; push long reference material into `references/` so it loads only on demand
- `claude plugin validate` only checks manifests, not skill discovery — confirm a new skill actually loads with `claude --plugin-dir ./plugins/{name}`

## Verification

```bash
claude plugin validate ./plugins/{name}   # plugin manifest
claude plugin validate .                  # marketplace manifest
claude --plugin-dir ./plugins/{name}      # load locally and exercise in a real session
```

## Conventions

- Conventional Commits (`chore:`, `feat:`, `fix:`)
- `.gitignore` excludes `docs/` and `.claude/`, so design docs under `docs/plans/` stay local and are never committed
