---
name: commit
description: Stage changes and create a git commit with a Conventional Commits message written in Chinese. Use when the user asks to commit, 提交, 保存改动, or wants a commit message generated from the current diff.
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git reset), Grep, Read
---

# Git Commit

Stage the current working-tree changes, write a Conventional Commits message in **Chinese**, and commit. No push, no PR.

## Hard rules

1. Write the message in Chinese. Do not imitate the style of previous commits.
2. No emoji, no traces of AI authorship (`Co-Authored-By`, `Generated with`, etc.).
3. Commit only: never push, switch branches, use `--no-verify`, or run destructive commands such as `git reset --hard`.

## Message format

```
<type>(<scope>): <subject>

<body>

<footer>
```

- **type** (required, lowercase): `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert`. When both `fix` and `feat` fit, choose `fix`; reserve `feat` for new capabilities.
- **scope** (optional): the affected module or directory; omit the parentheses entirely when there is no clear scope.
- **subject** (required): imperative mood, lowercase first letter, no trailing period, at most 72 characters, describing one thing only.
- **body** (optional): motivation and approach, separated from the subject by a blank line.
- **footer** (optional): link issues with `Closes #123`; breaking changes start with `BREAKING CHANGE:`.

Example: `fix(auth): redirect to login when the token expires`. Counter-examples: `update checkout.rb` (names a file, not an outcome), `fix bug and add tests` (two things at once).

## Workflow

1. **Read the state**: `git status --short --branch`, `git diff HEAD --stat`, `git diff HEAD`, each as its own shell call. Stop and explain if this is not a git repository or an unresolved merge / rebase is in progress. Untracked files do not appear in the diff — read them with Read.
2. **Short-circuit on no changes**: if `git status` shows nothing to commit, report that and stop. (`git diff HEAD` misses untracked files, so it cannot decide whether the tree is clean.)
3. **Safety check**: stop and confirm with the user if the pending changes include suspected secrets or local config (`.env*`, `*.pem`, `*.key`, `id_rsa`, credentials, certificates) or build output that should not be committed (`dist/`, `build/`, `node_modules/`, unusually large binaries).
4. **Compose the message**: infer type and scope from the diff; if the user stated their intent, follow it. When the diff is truncated or too thin to judge intent, read the key files with Read / Grep instead of guessing from filenames.
5. **Stage and commit**: stage named files only, never `git add -A` or `git add .`. Pass the message via heredoc so quotes and backticks are not interpreted by the shell, and repeat the file list after `--` so nothing staged outside this run rides along.

   ```bash
   git add file1 file2
   ```

   ```bash
   git commit -F - -- file1 file2 <<'EOF'
   <message>
   EOF
   ```

6. **Handle the result**:
   - Failed because a pre-commit hook rewrote files (lint-staged, formatter, etc.): re-`git add` the same files and retry once with the same message.
   - Failed on a real error such as lint or tests: stop, paste the output verbatim, do not bypass the hook.
   - Succeeded: confirm with `git status`, then report the commit hash and the final message.
7. **Splitting**: when the changes clearly cover several unrelated concerns, split them into separate commits by file (2–3 at most, no `git add -p`); when the boundary is unclear, make a single commit.
