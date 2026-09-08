# Botao Plugins

Botao's Claude Code plugins collection - macOS utilities and productivity tools.

## Available Plugins

### caffeinate

Prevent Mac from sleeping while Claude Code is running.

**Features:**
- Automatically starts `caffeinate` when session begins
- Resets 1-hour timer on each prompt submission
- Automatically stops when Claude finishes responding
- Zero configuration required

### botao-skills

A personal collection of custom Claude Code skills.

**Features:**
- Container plugin for hand-written Agent Skills
- Skills auto-discovered from `skills/{name}/SKILL.md` — no manifest registration
- Currently a scaffold; skills are added over time

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
