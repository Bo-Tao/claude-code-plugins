# Botao Plugins

[English](README.md) · [简体中文](README.zh-CN.md)

Botao 的 Claude Code 插件市场 —— 由 hooks 和 Agent Skills 搭起来的 macOS 工具与效率插件。

## 插件

| 插件 | 做什么 |
|------|--------|
| [`rename-session`](plugins/rename-session) | 根据整段对话给每个会话起名字 |
| [`otty`](plugins/otty) | 把 Claude Code 的状态报给 Otty 终端，并在 Otty 里打开文件 |
| [`botao-skills`](plugins/botao-skills) | 手写的 Agent Skills —— `commit` 与 `mr` |
| [`caffeinate`](plugins/caffeinate) | 让 Mac 不休眠 —— **已废弃**，Claude Code 自带了 |

各插件的依赖、配置和排查都写在它自己的 README 里（英文）。

### rename-session

`/resume` 列出的是每个会话的第一句话，于是一个以「hi」开头的会话就永远叫「greeting」。这个插件
从一个 async hook 往 transcript 里追加 `custom-title` 行，名字由一次简短的 `claude -p` 调用写出
——依据是整段对话，不是开头那一句；不带工具、不带 MCP server、不落盘成新会话。插件写的名字是临时
的，会随着工作成形被升级几次；你用 `/rename` 起的名字则永不改动。每个名字都带一个由脚本掌管的前
缀：默认 `T<会话日期>｜`，你明确声明版本时则是 `V<版本日期>｜`。

→ [命名约定、配置项与排查](plugins/rename-session/README.md)

### otty

给每个 [Otty](https://otty.app) 分屏挂上 processing / idle / awaiting-input 徽章，对应其中运行
的 agent；同时教会 Claude 把文件、目录和 URL 开在 Otty *里*，而不是丢给 `open(1)` 的默认应用。
Otty 自己也能把同样的 hooks 装进 `~/.claude/settings.json`，但每条都写死了绝对路径；这个插件改为
运行时定位 app，在没装 Otty 的机器上则完全不做事。

→ [状态 hooks、`open` skill 与排查](plugins/otty/README.md)

### botao-skills

手写 Agent Skills 的容器插件，从 `skills/{name}/SKILL.md` 自动发现，不需要在 manifest 里注册。
目前有两个：`commit` 暂存工作区并根据 diff 写一条中文的 Conventional Commits 提交信息；`mr` 从当
前分支开一个 GitLab merge request，标题和描述都由这个分支自己的提交写出。

→ [skill 清单，以及如何新增一个](plugins/botao-skills/README.md)

### caffeinate

在整个会话期间持有一个 `caffeinate -i -t 3600` 断言，每次提交 prompt 时重置。

> **已废弃。** Claude Code 大约从 2.1.156 起在 macOS 上自带了休眠抑制器，装这个插件只是在内置的
> 那份之上再叠一个 `caffeinate` 断言。保留仅作参考。

→ [与内置抑制器的对比](plugins/caffeinate/README.md)

## 安装

先注册一次 marketplace：

```
/plugin marketplace add Bo-Tao/claude-code-plugins
```

然后装你要的那个，或者在 `/plugin` → Discover 里翻：

```
/plugin install rename-session@botao-plugins
```

## 仓库结构

```
.claude-plugin/marketplace.json      # marketplace 清单 —— 列出全部插件
plugins/{name}/
  .claude-plugin/plugin.json         # 插件清单 —— 唯一必需的文件
  hooks/hooks.json                   # hook 定义
  hooks/*.sh                         # hook 脚本（git 里必须是 100755，否则会静默失效）
  skills/{skill}/SKILL.md            # Agent Skills —— 自动发现，无需注册
  README.md
```

一个插件可以只有 `hooks/`、只有 `skills/`，或者两者都有；只有 `plugin.json` 是必需的。

## 本地开发

```bash
claude plugin validate ./plugins/{name}   # 校验插件清单
claude plugin validate .                  # 校验 marketplace 清单
claude --plugin-dir ./plugins/{name}      # 本地加载，在真实会话里试一遍
```

`name`、`version`、`description`、`author` 这四项在 `plugin.json` 和 `marketplace.json` 里各存了
一份，必须保持一致 —— 两边不一致时 `claude plugin tag` 会拒绝打 tag。`claude plugin validate` 只
校验清单、不校验 skill 是否被发现，所以新增 skill 后要用 `--plugin-dir` 确认它真的加载了。

## License

MIT
