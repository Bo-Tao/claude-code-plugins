# Botao Skills Plugin

A personal collection of custom Claude Code skills.

## Overview

This plugin is a container for hand-written [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills).
Each skill lives in its own directory under `skills/` and is auto-discovered by
Claude Code — no manifest registration needed.

Skills activate automatically: Claude reads every skill's `description` and
loads the full `SKILL.md` when the current task matches. They can also be
invoked explicitly by name. A skill that sets `disable-model-invocation: true`
opts out of automatic activation and is reachable only by explicit invocation.

The plugin also ships slash commands, auto-discovered from `commands/{name}.md`.
A command is not a skill: it is a prompt template, expanded with your arguments
and sent as your message. Nothing in it executes.

## Available Skills

| Skill | Invoke | What it does |
|-------|--------|--------------|
| `commit` | `/botao-skills:commit` | Stages the working tree, infers a Conventional Commits type and scope from the diff, and commits with a Chinese message. Explicit invocation only — staging and committing has side effects that should be triggered deliberately. |
| `mr` | `/botao-skills:mr <target-branch>` | Opens a GitLab merge request from the current branch into the target branch via `glab`, with a Chinese title and description written from the branch's own commits and diff. Also fires automatically on 提 MR / 开 MR and similar. |

Keep this table in sync as skills are added.

## Available Commands

| Command | Invoke | What it does |
|---------|--------|--------------|
| `version` | `/botao-skills:version <YYYYMMDD> [请求]` | Declares the version date of the current session, so [`rename-session`](../rename-session/README.md) titles it `V<date>｜…` rather than `T<date>｜…`. Whatever follows the date is handled as an ordinary request. |

### `/botao-skills:version` — declaring a version

```
/botao-skills:version 20260915 帮我改下 README
```

Two things at once: this session belongs to version 20260915, and here is the
request. The date may be written `20260915`, `2026-09-15` or `2026/09/15`, and
must come first; without a date the command declares nothing.

The declaration is read straight out of the conversation — nothing is written to
disk, so there is no state to go stale and none to clean up. `rename-session`
recognises any input opening with `/version` or `/v`, in any namespace or none,
followed by an 8-digit date — so an alias dropped in `~/.claude/commands/` works
just as well as the namespaced form, under either spelling.

The body uses `$ARGUMENTS` and never `$1`, deliberately: Claude Code numbers the
first argument `$1` while Codex numbers it `$0`, so one file serves both.

## Adding a Skill

1. Create the directory and entry file:

   ```
   plugins/botao-skills/skills/{skill-name}/SKILL.md
   ```

2. Write `SKILL.md` with YAML frontmatter:

   ```markdown
   ---
   name: skill-name
   description: Use when <trigger condition>. <What it does.>
   ---

   # Skill Name

   ## Instructions

   Step-by-step guidance for Claude...
   ```

3. Update the **Available Skills** table above.

4. Validate and try it locally:

   ```bash
   claude plugin validate ./plugins/botao
   claude --plugin-dir ./plugins/botao
   ```

### Conventions

- **Directory names**: kebab-case, topic-focused (`vtt-translation`, not `utils`)
- **Entry file**: must be named `SKILL.md` exactly — `README.md` is not discovered
- **`description`**: the only thing Claude sees before loading the skill, so
  lead with *when* to use it. This is what makes the skill fire (or not).
- **Supporting files**: put them in the skill's own directory and reference them
  via `${CLAUDE_PLUGIN_ROOT}/skills/{skill-name}/...` — never hardcode absolute paths.

  ```
  skills/{skill-name}/
    SKILL.md
    references/    # docs loaded on demand
    scripts/       # executable helpers
    assets/        # templates, fixtures
  ```

- **Keep `SKILL.md` lean**: push long reference material into `references/` so it
  is only read when actually needed.

## Adding a Command

Drop a markdown file in `commands/`; it becomes `/botao-skills:{filename}`.
Frontmatter takes `description` and `argument-hint`; the body is the prompt,
with `$ARGUMENTS` substituted. Plugin commands are always namespaced — a bare
`/{name}` is rejected as an unknown command — so for a command you type often,
add an alias file under `~/.claude/commands/`.

## Requirements

- `git` — both skills read the working tree
- The [`glab`](https://gitlab.com/gitlab-org/cli) CLI, already authenticated, for `mr`
- Claude Code with plugin support

## Installation

```
/plugin marketplace add Bo-Tao/claude-code-plugins
/plugin install botao-skills@botao-plugins
```

Manual:

```bash
git clone https://github.com/Bo-Tao/claude-code-plugins.git
claude --plugin-dir ./claude-code-plugins/plugins/botao
```

## License

MIT
