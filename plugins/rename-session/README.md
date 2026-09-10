# Rename Session Plugin

Give every Claude Code session a real name, automatically — so `/resume` shows what each
session was about instead of a list of first prompts.

## Overview

A session title lives in the session transcript as a JSONL line:

```json
{"type":"custom-title","customTitle":"...","sessionId":"..."}
```

Claude Code re-reads the last such line, so appending one renames the session. This plugin
appends that line from an async hook, with a name written by a short model call over the
conversation so far.

Naming from the *conversation* rather than the first prompt is the point: a session that
opens with "hi" should not be called "greeting" forever.

- A prompt carrying no task is skipped — naming waits for real work
- The model sees the first and last few user turns, not just the prompt that fired the hook
- The plugin's own names stay provisional and may be upgraded a few times as the work takes
  shape, reconsidered every few turns rather than on every prompt
- A name you set with `/rename` is never touched

## The Name

```
T20260909｜fix caffeinate pid reuse
V20260915｜读取 README 中的内容
└──┬───┘└┬┘└──────────┬─────────┘
prefix  ｜         body — the model writes only this
```

The prefix belongs to the script; the model only ever writes the body after it.

| Prefix | When |
|--------|------|
| `T<session's local start date>｜` | by default |
| `V<the version date you gave>｜` | when you state a version explicitly — this wins over `T` |

The date is the session's **first** day, not the day of the rename, so an upgraded name keeps
its prefix.

### Stating a version outright

`/version` says it directly, and beats the heuristic below:

```
/botao:version 20260915 帮我改下 README
```

The command ships with [`botao`](../botao/README.md). Any namespace is accepted,
and so is the short spelling `/v` — useful if you drop an alias in
`~/.claude/commands/`.

Claude Code records a slash command as its invocation rather than its expansion,
so the declaration is read from two places: `.prompt` for the turn now firing —
which is why the prefix changes on the very turn you type it — and the
transcript's `<command-args>` for every turn before it. The last one wins.

### What counts as a version date

Without an explicit `/v`, a version date is inferred from what you wrote.

A date (`2026-09-15`, `2026/09/15`, `20260915`) qualifies when, within 14 characters of it:

- a version word appears — `版本`, `版次`, `迭代`, `version`, `ver.`
- **and** no ordinary-business word does — `创建`, `截止`, `结束`, `发布`, `上线`, `交付`,
  `deadline`, `due`, `release`, `deploy`, `publish`

Dates introduced as examples (`示例`, `例如`, `比如`, `格式为`, `形如`, `举例`, `e.g.`) or sitting
inside quotes or backticks are not declarations. The last qualifying date in the conversation wins.

Because the prefix is ours and the body is not, a version stated mid-session is applied to the
standing name directly — no model call, no budget spent, the body untouched.

## How It Decides

| Situation | What happens |
|-----------|--------------|
| No task yet — greeting, thanks, a test message | model answers `SKIP`, session stays unnamed |
| Named already, work has not moved on | model answers `SKIP`, name kept |
| Named already, work has clearly moved on | name upgraded (counts against the rename budget) |
| Title is not one this plugin wrote | you named it by hand — the plugin stops for good |
| `SessionStart` from `/clear` or compaction | skipped; a compacted session gets its next look at the next prompt |
| Still unnamed after `SESSION_NAMER_MAX_TURNS` turns | gives up, stops spending model calls |

Ownership is decided by value, not by the last line: Claude Code re-appends its own
`custom-title` line as session metadata and that copy carries no marker. The plugin collects
every title it has written (marked `"sessionNamer":true`) and compares the effective title
against them.

## The Model Call

A bare `-p` run of the CLI itself:

```bash
claude -p --model sonnet --system-prompt "..." \
  --tools "" --strict-mcp-config --no-session-persistence --output-format json
```

Its own system prompt, no tools, no MCP servers, no saved session. It costs a few hundred
tokens and leaves nothing behind in the session list it is meant to clean up.

`SESSION_NAMER_RUNNING` guards against recursion — that `-p` call still loads user settings
(so `apiKeyHelper` and proxy setups keep working), and with them these hooks.

## Hooks

| Event | Mode | Timeout |
|-------|------|---------|
| `SessionStart` | async | 120s |
| `UserPromptSubmit` | async | 120s |

Both run `hooks/rename-session.sh`. The long timeout is deliberate — the hook makes a model
call — and `async` keeps it off the critical path, so nothing waits on it.

The script redirects its own stdout to `/dev/null`: Claude Code hands an async hook's stdout to
the model as extra context, and a naming hook has nothing to say to the model.

Only one run names a session at a time. On resume, `SessionStart` and the first
`UserPromptSubmit` overlap; a `mkdir` lock at `$TMPDIR/session-namer-<id>.lock` keeps them from
both calling the model and both writing a name. A lock left behind by a killed run is ignored
once it is older than the hook timeout.

## Requirements

- `jq` on `PATH`
- The `claude` CLI on `PATH` (or `SESSION_NAMER_CLAUDE_BIN` pointing at it)
- Claude Code with plugin support

Missing either binary, the hook exits 0 without output.

## Installation

```
/plugin marketplace add Bo-Tao/claude-code-plugins
/plugin install rename-session@botao-plugins
```

Manual:

```bash
git clone https://github.com/Bo-Tao/claude-code-plugins.git
claude --plugin-dir ./claude-code-plugins/plugins/rename-session
```

## Configuration

All optional.

| Variable | Default | Purpose |
|----------|---------|---------|
| `SESSION_NAMER_DISABLE` | unset | Set to anything to turn the plugin off |
| `SESSION_NAMER_MODEL` | `sonnet` | Model used to write the name |
| `SESSION_NAMER_CLAUDE_BIN` | `claude` | CLI used to write the name; a bare name on `PATH` or an absolute path |
| `SESSION_NAMER_FORMAT` | built-in | Your convention for the body, in prose |
| `SESSION_NAMER_MAX_RENAMES` | `3` | How many times the plugin may name one session |
| `SESSION_NAMER_MAX_TURNS` | `20` | Stop trying to name a session after this many turns |
| `SESSION_NAMER_RECHECK_EVERY` | `5` | Once named, reconsider the name every N turns |
| `SESSION_NAMER_DEBUG` | unset | Log every run to `$TMPDIR/session-namer.log` |

### Naming convention

The body follows, in order of precedence:

1. `SESSION_NAMER_FORMAT`
2. `.claude/session-name.md` in the project (first 2000 characters)
3. the built-in default — a plain summary of the work, no type label, no punctuation around it,
   written in the language you write in: at most 6 words in English, or 10 characters in
   Chinese or Japanese, lowercase where that applies, no trailing period

A convention describes the **body only**. The `T`/`V` prefix is added afterwards and is not the
model's to write.

Per project:

```bash
mkdir -p .claude && cat > .claude/session-name.md <<'EOF'
Start with the area of the codebase, then a dash, then what is being done.
Chinese, at most 12 characters.
EOF
```

## Troubleshooting

**Nothing ever gets named** — turn on the log and check what each run decided:

```bash
SESSION_NAMER_DEBUG=1 claude
tail -f "${TMPDIR:-/tmp}/session-namer.log"
```

Each line is one run: `skip: named by hand`, `skip: rename budget spent`, `skip: model declined`,
`named: T20260909｜…`, and so on. The CLI's stderr goes to the same file.

**Named once, then never again** — that is the budget (`SESSION_NAMER_MAX_RENAMES`, default 3)
and the cadence (`SESSION_NAMER_RECHECK_EVERY`, default 5 turns) working as intended. Raise
either if you want more.

**Stopped naming after I renamed it myself** — also intended. Once the effective title is not one
the plugin wrote, it never writes again for that session.

**Wrong prefix** — a `V` prefix means you declared a version with `/v`, or a version date was
inferred from the conversation. For the inferred kind, quote the date or introduce it with `例如` /
`e.g.` to keep it from being read as a declaration.

## License

MIT
