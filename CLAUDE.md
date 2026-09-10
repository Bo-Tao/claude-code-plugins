# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Code plugins marketplace (`botao-plugins`): personal plugins that extend Claude Code through hooks and skills.

| Plugin | Components | Reference example for |
|---|---|---|
| `rename-session` | hooks | async hooks; calling `claude -p` from inside a hook |
| `otty` | hooks + skills | delegating to an external app; `PreToolUse` / `PostToolUse` / `PermissionRequest` |
| `botao-skills` | skills + commands | skills and slash commands, no hooks at all |
| `caffeinate` | hooks | the simplest hook plugin — **deprecated**, superseded by Claude Code's own sleep inhibitor |

## Repository Structure

```
.claude-plugin/marketplace.json      # Marketplace manifest (lists all plugins)
plugins/{plugin-name}/
  .claude-plugin/plugin.json         # Plugin manifest (the only required file)
  hooks/hooks.json                   # Hook definitions
  hooks/*.sh                         # Hook scripts (must be chmod +x)
  skills/{skill-name}/SKILL.md       # Agent skills (auto-discovered)
  skills/{skill-name}/scripts/*.sh   # Skill helpers (chmod +x too)
  README.md                          # Plugin documentation
```

Only `plugin.json` is mandatory; a plugin ships `hooks/`, `skills/`, or both.

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

Events used here: `SessionStart`, `UserPromptSubmit` and `Stop` (caffeinate, otty, rename-session), plus `PreToolUse`, `PostToolUse` and `PermissionRequest` (otty). Claude Code supports more (`SessionEnd`, `SubagentStop`, `PreCompact`, `Notification`).

`matcher` filters *within* an event: the tool name on `PreToolUse` / `PostToolUse`, the trigger source on `SessionStart` (`startup` / `resume` / `clear` / `compact`) and `PreCompact`. `UserPromptSubmit`, `Stop` and `PermissionRequest` have nothing to filter, so omit it there — caffeinate's `"matcher": "*"` on those events is inert; otty leaves it out.

A hook that does real work runs `async` instead of blocking the turn:

```json
{ "type": "command", "command": "bash \"${CLAUDE_PLUGIN_ROOT}/hooks/foo.sh\"",
  "async": true, "timeout": 120, "statusMessage": "Naming session..." }
```

### Hook Script Guidelines

- Reference plugin files via `${CLAUDE_PLUGIN_ROOT}`; never hardcode absolute paths
- Keep `timeout` at 5s for a blocking hook — it fires on every event and the turn waits on it. Anything slower (a network call, a model call) belongs in an `async` hook with a timeout that fits the work: rename-session uses 120s
- Keep scripts silent: `SessionStart` / `UserPromptSubmit` stdout is injected into Claude's context, and an async hook's stdout is handed to the model too. `exec >/dev/null` on its own line at the top of the script is the sturdiest form — command substitutions inside still work
- Put state files under `${TMPDIR:-/tmp}` (e.g. `$TMPDIR/session-namer-<session-id>.lock`)
- Scripts must be idempotent: re-running replaces prior state, and a recorded PID must be re-checked (`ps -p ... -o args=`) before being killed, so a recycled PID is never signalled
- Hooks that can overlap (`SessionStart` and the first `UserPromptSubmit` do, on resume) need a lock — a `mkdir` at a fixed path, ignored once it is older than the hook timeout
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
- Optional frontmatter used here: `disable-model-invocation: true` keeps a skill reachable only by explicit `/{plugin}:{skill}` invocation (see `commit`, whose side effects should be deliberate); `allowed-tools` narrows what the skill may run; `argument-hint` documents a required argument (see `mr`)
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

- Conventional Commits, with the subject in Chinese after the English type — `feat(otty): 新增 open skill 在 otty 内打开文件与链接`
- `.gitignore` excludes `docs/` and `.claude/`, so design docs under `docs/plans/` stay local and are never committed
