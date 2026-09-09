# Botao Plugins

Botao's Claude Code plugins collection - macOS utilities and productivity tools.

## Available Plugins

| Plugin | What it does |
|--------|--------------|
| [`rename-session`](plugins/rename-session) | Names every session from the conversation so far |
| [`otty`](plugins/otty) | Reports Claude Code's state to the Otty terminal, and opens files in it |
| [`botao-skills`](plugins/botao-skills) | A container for hand-written Agent Skills |
| [`caffeinate`](plugins/caffeinate) | Keeps the Mac awake — **deprecated**, Claude Code ships its own |

### rename-session

Give every session a real name, so `/resume` shows what each one was about instead of a list
of first prompts.

**Features:**
- Names from the conversation so far, not just the first prompt — a session opening with "hi"
  never stays "greeting"
- Provisional names are upgraded a few times as the work takes shape; a name you set with
  `/rename` is never touched
- Every name carries a prefix the plugin owns: `T<session date>｜` by default, `V<version
  date>｜` when you state a version explicitly
- One short `claude -p` call per naming, with no tools, no MCP servers and no saved session

### otty

Report Claude Code's state to the [Otty](https://otty.app) terminal app, and open files,
folders and URLs inside Otty instead of handing them to an external app.

**Features:**
- Per-pane processing / idle / awaiting-input badges, via `SessionStart`, `UserPromptSubmit`,
  `PreToolUse`, `PostToolUse`, `PermissionRequest` and `Stop`
- No absolute paths in your settings — the app is located at runtime, and the plugin does
  nothing when Otty isn't installed
- An `open` skill that maps "open this file" / "show it beside the terminal" / `/open <path>`
  onto `otty view` and `otty edit`

### botao-skills

A personal collection of custom Claude Code skills.

**Features:**
- Container plugin for hand-written Agent Skills
- Skills auto-discovered from `skills/{name}/SKILL.md` — no manifest registration
- Ships `commit` and `mr`; more are added over time

### caffeinate

Prevent Mac from sleeping while Claude Code is running.

> **Deprecated.** Claude Code has shipped its own sleep inhibitor on macOS since roughly
> 2.1.156, so this plugin is redundant — installing it just adds a second `caffeinate`
> assertion on top of the built-in one. See the
> [plugin README](plugins/caffeinate/README.md) for the comparison.

**Features:**
- Automatically starts `caffeinate` when session begins
- Resets 1-hour timer on each prompt submission
- Automatically stops when Claude finishes responding
- Zero configuration required

## Installation

### Add marketplace

Register the marketplace first:

```
/plugin marketplace add Bo-Tao/claude-code-plugins
```

### Install Plugins

Plugins can be installed directly from this marketplace via Claude Code's plugin system.

To install, run `/plugin install {plugin-name}@botao-plugins`

or browse for the plugin in /plugin > Discover

## License

MIT
