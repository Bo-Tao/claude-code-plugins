---
name: mr
description: Create a GitLab merge request with the glab CLI, writing the title and description in Chinese from the branch's own commits and diff. It takes one required argument, the target branch — "/mr master" opens an MR from the current branch into master. Invoked without it, this stops and asks rather than guessing where the team merges. Use this whenever the user asks to 提 MR、开 MR、建 MR、创建 merge request、合并请求、提个到 xxx 分支的 MR, or wants the current branch merged somewhere on GitLab — even if they never mention glab by name.
argument-hint: "[target branch]"
allowed-tools: Bash(git:*), Bash(glab:*), Bash(bash:*), Read, Grep
---

# GitLab Merge Request

Open a merge request from the current branch into a target branch, with a title and description written in **Chinese** from what the branch actually changed.

The argument is the target branch: `/mr master` means current branch → `master`. It is required. Invoked bare, Step 1 stops and asks — see `target_required`.

## Hard rules

1. Title and description in Chinese. The Conventional Commits prefix (`feat`, `fix(scope)`) stays English; everything after the colon is Chinese.
2. No emoji, no AI-authorship traces (`Generated with`, `Co-Authored-By`, 🤖).
3. This skill only pushes the current branch and creates the MR. Never commit, switch branches, force-push, rebase, merge, or touch the target branch.
4. Run start to finish without asking for confirmation. There is exactly one exception — `BLOCKER=target_required` in Step 1, where guessing costs more than asking. Otherwise stop only on a real blocker, and when you stop, say what is wrong and what would fix it.
5. Never claim to have verified something you did not verify. See the 自测 rules in Step 3.

## Step 1 — Preflight

One script collects every fact needed. Run it with an absolute path (`scripts/preflight.sh` inside this skill's directory), passing the target branch the user named — and nothing when they named none, so it can gather the candidates for you:

```bash
bash "<skill-dir>/scripts/preflight.sh" <target-branch>
```

It prints `KEY=VALUE` lines, and which ones you get depends on whether a target branch was named. Almost everything worth knowing is measured *against* the target, so without one there is nothing to measure:

- **With a target branch**: `HOST` `PROJECT` `REMOTE` `SOURCE_BRANCH` `TARGET_BRANCH` `AHEAD` `BEHIND` `MERGE_BASE` `REMOTE_BRANCH` `UNPUSHED` `UNCOMMITTED`, plus `MR_TEMPLATES` and `EXISTING_MR` when they apply.
- **Without one**: `HOST` `PROJECT` `REMOTE` `SOURCE_BRANCH`, then `DEFAULT_BRANCH` / `RECENT_MR_TARGETS` / `CANDIDATE` and `BLOCKER=target_required`. Everything else is absent by design — don't go compute it by hand, just ask.

Read them before doing anything else. They decide the whole run.

`FATAL=` and `BLOCKER=` lines mean stop and report:

| Line | What to tell the user |
|---|---|
| `FATAL=not_a_git_repo` | Not a git repository |
| `FATAL=glab_not_installed` | glab is missing — `brew install glab` |
| `FATAL=detached_head` | HEAD is detached; check out a branch first |
| `FATAL=no_git_remote` | The repository has no remote configured |
| `BLOCKER=glab_not_authenticated` | Log in to that instance — `glab auth login --hostname <HOST>` |
| `BLOCKER=same_source_and_target` | Source and target are the same branch; an MR would be meaningless |
| `BLOCKER=no_commits_ahead` | Nothing to merge into the target (likely merged already); `BEHIND` says how far back it is |
| `BLOCKER=target_branch_missing_on_remote` | No such branch on the remote; run `git branch -r \| grep <target>` and offer the closest names |
| `BLOCKER=mr_already_open` | One is already open at `EXISTING_MR`. If `UNPUSHED` is not 0, push once so it updates itself — never open a second |
| `BLOCKER=target_required` | See below |

**`target_required` — the one case worth stopping to ask about.** The user did not name a target branch. Do not pick one for them: a repository's default branch and the branch a team actually merges into are frequently not the same (staging / gray / dev workflows especially), and an MR aimed at the wrong branch misleads reviewers and can trigger the wrong pipeline. Asking costs one round trip.

A bare "which target branch?" just hands the question back — anyone who knew the answer would have typed it. So the script does nothing else on this path except work out the candidates and the evidence for each:

- `DEFAULT_BRANCH` — what the remote's `HEAD` points at, i.e. the default branch in the GitLab project settings.
- `RECENT_MR_TARGETS` — where this source branch's own past MRs went, shaped like `staging:3`. This is the most direct evidence of the team's convention.
- `CANDIDATE` — one line per candidate, carrying the current branch's `ahead` / `behind` against it. **`ahead=0` means that candidate is a dead end**: the commits are already in it, so an MR would be empty. Put this in the question, or the user may pick a branch that cannot be opened at all.

Those evidenced candidates are enough. Don't pad the list out of `git branch -r` — the user answers with a branch name, so this is a fill-in-the-blank, not a multiple choice, and one stale branch that is hundreds of commits ahead only clouds the decision. If they want somewhere else, they will say so.

Lay the candidates out with their evidence and let the user name one:

> `knowledge-mark` 之前的 3 个 MR 都开到 `staging`，但仓库默认分支是 `master`。
> - `master`：领先 25 个提交 —— 这些提交确实还没合进去
> - `staging`：领先 0 / 落后 6 —— 已经全合进去了，再开是空 MR
>
> 开到哪个？

What they actually want may be a release MR of `staging` into `master`, which needs `staging` checked out first — and switching branches is not this skill's job. Offer it as an option; don't switch for them.

`UNCOMMITTED` is **not** a blocker — uncommitted files simply won't be in the MR. Note them in the final report so the user notices if they forgot to commit something.

If you query GitLab yourself for anything, always pass `-F json`. `glab mr list` with its default table output crashes on some instances (nil pointer in `mrutils.DisplayAllMRs`, glab 1.97.0). If a `glab` subcommand still fails, `glab api` is the reliable fallback.

## Step 2 — Read what the branch changed

Use `MERGE_BASE` from the preflight so you see only this branch's work, not commits the target picked up meanwhile:

```bash
git log --reverse --format='%h %s%n%b' <MERGE_BASE>..HEAD
git diff --stat <MERGE_BASE>..HEAD
git diff <MERGE_BASE>..HEAD
```

Commit subjects tell you the intent; the diff tells you whether the intent was actually carried out and what else came along for the ride. You need both — a description written from subjects alone repeats what the reviewer can already see in the commit list.

If the diff is very large (roughly >1500 lines), read `--stat` first and then only the files that carry the logic. Lockfiles, generated type declarations, vendored scripts and snapshots rarely change what the reviewer needs to know.

## Step 3 — Write the title and description

### Title

`<type>(<scope>): <中文主题>`, at most 72 characters. Type vocabulary as in commits (`feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `revert`); scope is the affected module or directory, omitted when there isn't a clear one. The type must match what the change actually does — `chore(release): 修复…` contradicts itself.

How to pick the subject depends on what kind of branch this is:

- **Feature branch** (opened for one thing): name that one thing. A single commit? Reuse its subject. If two unrelated things genuinely landed on the branch, put the higher-impact one in the main clause and leave the rest to the description — stacking "A 并 B" into a title is a refusal to summarize.
  Good: `feat(报表导出): 支持按周维度导出数据` · `fix(auth): token 过期后跳回登录页`
  Bad: `更新若干文件` (says nothing) · `feat: 修改 UserService.ts` (names a file, not an outcome) · `feat(构建): 接入域名容错并切换环境配置包` (two things crammed into one clause)

- **Environment / release branch** (`staging`, `gray`, `dev`, `release/*` merging into the trunk): these accumulate unrelated work by design, so forcing one theme onto them always reads wrong. Label it honestly as a release merge — main clause says which branch goes into which, and the itemization goes in parentheses:
  `chore: staging 合并入 master（权限选择器与角色搜索修复、README 重写）`

### Description

Length follows **the number of distinct concerns and the risk surface**, not the diff's line count — the two often disagree. A 500-line bulk rename is worth three sentences; a 93-line change that touches the build script, the dependencies and runtime code at once earns a full sectioned description, because the reviewer has three independent things to judge. (Step 2's 1500-line threshold only decides whether you read the whole diff; it says nothing about description length.)

When the change really is one thing with a narrow risk surface, three to five sentences covering why, what and what to verify is enough — no need to fill in four headings, and a hollow "影响范围：无" is worse than omitting the section. Expand into sections when the change spans several concerns:

```markdown
## 背景
为什么要做这个改动：需求、bug 现象、或者上游依赖变化。

## 改动
- 按模块列，每条说清楚"改了什么、怎么改的"
- 有取舍或者不显然的实现选择，在这里解释一句

## 影响范围
碰到了哪些模块 / 接口 / 配置；有没有破坏性变更、数据迁移、需要同步改的调用方。没有就写"无"。

## 自测
见下。
```

**影响范围 is about risk, not a list of changes.** Pasting `git diff --stat` or the commit list there is worthless — the reviewer already sees both on the MR page. This section answers "what breaks if this lands, and where": whether a failing build step takes the whole pipeline down, whether deleting a placeholder tag silently disables something, whether a swapped dependency is semantically equivalent, whether tightened validation will reject existing data. Only someone who read the diff can write these.

**Do not actually run the project's checks for 自测.** Installing dependencies, starting servers and running builds all carry side effects and stretch the run out. Make the verification list concrete instead: point at test files the branch already added; write commands in copy-paste form (`pnpm type-check && pnpm test:unit`); turn manual checks into single executable actions ("切换系统后确认搜索框清空且不再多发一次请求") rather than "建议测试一下". If you did not verify something, say so plainly — a fabricated verification result lowers the reviewer's guard, which is worse than leaving it blank.

If the preflight reported `MR_TEMPLATES`, read the template under `.gitlab/merge_request_templates/` and follow **its** headings instead. The team put those sections there because reviewers and pipelines look for them. Fill them with the same analysis and keep any checklist they define.

If a commit body or the branch name carries an issue id (`#1234`, `feat/PROJ-88`), add a `相关 issue: #1234` line at the end. Use `Closes #1234` only when the user explicitly says this MR closes it — that keyword auto-closes the issue on merge, which is not yours to decide.

The audience is a reviewer who has not seen this branch. Every line should either save them a question or save them a click; drop whatever does neither.

## Step 4 — Push and create

`UNPUSHED=0` means the branch is already on the remote — skip this step entirely. Push only when it says otherwise (`missing` and `all` both mean the remote has nothing yet). Never `--force`:

```bash
git push -u <REMOTE> HEAD
```

Write the description to a file in the scratchpad first, so quotes, backticks and newlines survive the shell intact:

```bash
cat > <scratchpad>/mr-desc.md <<'EOF'
<description>
EOF
```

```bash
glab mr create \
  --source-branch "<SOURCE_BRANCH>" \
  --target-branch "<TARGET_BRANCH>" \
  --title "<title>" \
  --description "$(cat <scratchpad>/mr-desc.md)" \
  --yes
```

Do not pass `--remove-source-branch`, `--squash-before-merge` or `--draft` unless the user asked — omitting them lets the project's own defaults apply. Do not pass `--web`; the user wants the link in the terminal, not a browser.

Extra wishes in the same request map onto flags: 草稿/draft → `--draft`, 指派给 X → `-a X`, 找 X review → `--reviewer X`, 打标签 → `-l <label>`.

When `glab` fails, read the message instead of retrying blindly:
- `401`/`unauthorized` → `glab auth login --hostname <HOST>`
- source branch not found → the push didn't land; check the `git push` output
- required field / template validation → paste the error verbatim and stop; guessing at a company's required fields wastes a round trip

## Step 5 — Report

Report in Chinese, compactly:

- MR 链接
- `源分支 → 目标分支`
- 标题
- 包含 N 个 commit、M 个文件变更
- Warnings, if any: 未提交的文件没进 MR / 落后目标分支 N 个提交，可能需要 rebase
