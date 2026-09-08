# Botao Skills Plugin

A personal collection of custom Claude Code skills.

## Overview

This plugin is a container for hand-written [Agent Skills](https://docs.claude.com/en/docs/claude-code/skills).
Each skill lives in its own directory under `skills/` and is auto-discovered by
Claude Code — no manifest registration needed.

Skills activate automatically: Claude reads every skill's `description` and
loads the full `SKILL.md` when the current task matches. They can also be
invoked explicitly by name.

## Available Skills

_None yet — this plugin is a scaffold. Add skills under `skills/`._

<!-- Keep this table in sync as skills are added:
| Skill | Purpose |
|-------|---------|
| `example-skill` | What it does and when it fires |
-->

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
   claude plugin validate ./plugins/botao-skills
   claude --plugin-dir ./plugins/botao-skills
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

## Installation

### Claude Code (add marketplace)

```
/plugin marketplace add Bo-Tao/botao-plugins
/plugin install botao-skills@botao-plugins
```

### Manual

```bash
claude --plugin-dir ./plugins/botao-skills
```

## License

MIT
