---
name: open
description: Open a file, folder or URL inside Otty — in a split, a new tab, or a new window — instead of handing it to an external app. Use when the user types `/open <path-or-url>` or asks to "open X in a split / new tab / new window".
---

# Open

    otty view <path-or-url> [placement] [--mode view|edit]
    otty edit <path-or-url> [placement]     # same command, editable by default

## Placement (pick one; default is a new tab)

| Flag | Result |
| --- | --- |
| `--right` `--left` `--top` `--bottom` | split the current pane that way |
| `--new-tab` | open in a new tab (the default) |
| `--new-window` | open in a new window |

## Rules

1. Map the user's words to a placement: "split", "beside", "next to" →
   `--right` unless they name a side; "new tab" → `--new-tab`; "new window" →
   `--new-window`; nothing said → leave the default.
2. Targets: a relative path resolves against your working directory, an
   absolute path is used as-is, `http(s)://` opens in Otty's viewer, and
   `host:/path` is treated as a remote target.
3. `otty view` opens read-only and `otty edit` opens editable; `--mode`
   overrides either one for a single invocation.
4. Exit codes: 0 opened · 3 no running Otty to open it in · 4 the target could
   not be resolved.
5. Report the placement you chose in one line. If the user wanted something
   else it is one flag away.
