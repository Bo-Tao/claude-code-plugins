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

## Available Skills

| Skill | Invoke | What it does |
|-------|--------|--------------|
| `commit` | `/botao-skills:commit` | Stages the working tree, infers a Conventional Commits type and scope from the diff, and commits with a Chinese message. Explicit invocation only — staging and committing has side effects that should be triggered deliberately. |
| `mr` | `/botao-skills:mr <target-branch>` | Opens a GitLab merge request from the current branch into the target branch via `glab`, with a Chinese title and description written from the branch's own commits and diff. Also fires automatically on 提 MR / 开 MR and similar. |

Keep this table in sync as skills are added.

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
claude --plugin-dir ./claude-code-plugins/plugins/botao-skills
```

## License

MIT
