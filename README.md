# Botao Plugins

[English](README.md) · [简体中文](README.zh-CN.md)

Botao's Claude Code plugin marketplace — macOS utilities and productivity tools, built out of
hooks and Agent Skills.

## Plugins

| Plugin | What it does |
|--------|--------------|
| [`rename-session`](plugins/rename-session) | Names every session from the conversation so far |
| [`otty`](plugins/otty) | Reports Claude Code's state to the Otty terminal, and opens files in it |
| [`botao`](plugins/botao) | Hand-written Agent Skills and slash commands — `commit`, `mr`, `/version` |
| [`caffeinate`](plugins/caffeinate) | Kept the Mac awake — **deprecated**, Claude Code ships its own |

Each plugin's own README carries its requirements, configuration and troubleshooting.

### rename-session

`/resume` lists first prompts, so a session that opened with "hi" stays "greeting" forever. This
plugin appends a `custom-title` line to the transcript from an async hook, with a name written by
one short `claude -p` call over the conversation so far — no tools, no MCP servers, no saved
session. Names stay provisional and are upgraded a few times as the work takes shape; a name you
set with `/rename` is never touched. Every name carries a prefix the plugin owns —
`T<session date>｜` by default, `V<version date>｜` when you state a version explicitly.

→ [Naming conventions, configuration and troubleshooting](plugins/rename-session/README.md)

### otty

Gives each [Otty](https://otty.app) pane a processing / idle / awaiting-input badge for the agent
running inside it, and teaches Claude to open files, folders and URLs *in* Otty rather than handing
them to `open(1)`'s default app. Otty can install the same hooks into `~/.claude/settings.json`
itself, with absolute paths baked into every entry; this plugin locates the app at runtime instead,
and does nothing at all on a machine where Otty isn't installed.

→ [State hooks, the `open` skill and troubleshooting](plugins/otty/README.md)

### botao

A container for hand-written Agent Skills, auto-discovered from `skills/{name}/SKILL.md` with
nothing to register in the manifest. It ships two: `commit` stages the working tree and writes a
Conventional Commits message in Chinese from the diff, and `mr` opens a GitLab merge request from
the current branch with a title and description written from the branch's own commits. It also
ships one slash command: `/botao:version 20260915 …` declares the version date of the session, which
`rename-session` turns into a `V20260915｜` title prefix.

→ [The skill list, the command list, and how to add one](plugins/botao/README.md)

### caffeinate

Held a `caffeinate -i -t 3600` assertion for the length of a session, reset on every prompt.

> **Deprecated.** Claude Code has shipped its own sleep inhibitor on macOS since roughly 2.1.156,
> so installing this just stacks a second `caffeinate` assertion on top of the built-in one. Kept
> for reference.

→ [How it compares to the built-in inhibitor](plugins/caffeinate/README.md)

## Installation

Register the marketplace once:

```
/plugin marketplace add Bo-Tao/claude-code-plugins
```

Then install what you want, or browse `/plugin` → Discover:

```
/plugin install rename-session@botao-plugins
```

## Repository Layout

```
.claude-plugin/marketplace.json      # marketplace manifest — lists every plugin
plugins/{name}/
  .claude-plugin/plugin.json         # plugin manifest — the only required file
  hooks/hooks.json                   # hook definitions
  hooks/*.sh                         # hook scripts (git mode 100755, or they silently fail)
  skills/{skill}/SKILL.md            # Agent Skills — auto-discovered, nothing to register
  README.md
```

A plugin ships `hooks/`, `skills/`, or both; only `plugin.json` is mandatory.

## Local Development

```bash
claude plugin validate ./plugins/{name}   # plugin manifest
claude plugin validate .                  # marketplace manifest
claude --plugin-dir ./plugins/{name}      # load locally and exercise in a real session
```

`name`, `version`, `description` and `author` are duplicated between `plugin.json` and
`marketplace.json`, and must stay in sync — `claude plugin tag` refuses to tag a release when the
two disagree. `claude plugin validate` checks manifests only, not skill discovery, so confirm a new
skill actually loads with `--plugin-dir`.

## License

MIT
