# Thomas Skills 中文说明

这是 `thomas-skills` 的中文入口页，目标是帮你先回答三件事：

- 这个仓库里有什么
- 我该先用哪个 skill
- 接下来该去看哪篇文档

英文 GitHub 首页仍然是默认入口：[`README.md`](../../README.md)。

## 仓库定位

这个仓库是一组可复用的 agent skill 包，面向真实运维场景：装一次、认证一次，环境重置后秒级恢复。

当前包含 1 个 skill：

- `tailscale-persistent`

## 选择 Skill

| Skill | 何时使用 | 最适合处理 | 文档 |
| --- | --- | --- | --- |
| `tailscale-persistent` | 在根文件系统会被重置（`/usr`、`/etc`、`/var` 丢失，但有一个目录持久化）的 Ubuntu/Debian 环境里跑 Tailscale | 装一次、认证一次，重置后免重新授权、秒级恢复 | [使用指南](../usage/tailscale-persistent.md) |

如果你还不确定该选哪个，优先看 [Skill Matrix](../usage/skill-matrix.md)（英文）。

## 推荐起点

- 想快速装一个 skill： [快速开始](../usage/quickstart.md)（英文）
- 想先看仓库常用路径： [黄金路径](../usage/golden-path.md)（英文）
- 想看英文原版首页： [`README.md`](../../README.md)

## 安装

skill 包遵循 `SKILL.md` 约定，Codex / Claude Code 的 skill 目录都可用：

- 用户级（Codex）：`$HOME/.agents/skills`
- 用户级（Claude Code）：`$HOME/.claude/skills`
- 仓库级：`.agents/skills` 或 `.claude/skills`

安装一个 skill 的最短方式：

```bash
mkdir -p ~/.agents/skills
cp -R tailscale-persistent ~/.agents/skills/
```

## 文档导航

- [快速开始](../usage/quickstart.md)
- [Skill Matrix](../usage/skill-matrix.md)
- [tailscale-persistent 使用指南](../usage/tailscale-persistent.md)
- [常见问题](../usage/faq.md)（英文）
- [故障排查](../usage/troubleshooting.md)（英文）
- [示例](../usage/examples.md)（英文）
- [发布说明](../releases/README.md)（英文）

说明：

- skill 名称、命令、路径保持不翻译，进入英文页时直接对照使用。

## 仓库结构

```text
tailscale-persistent/           skill 包（SKILL.md + assets/ + references/）
docs/usage/                     英文 usage 与导航页
docs/zh/                        中文入口
docs/releases/                  发布说明
tests/                          仓库级回归测试
```

## 维护者入口

- 仓库级文档检查：`python3 -m unittest discover tests -v`
- `tailscale-persistent/assets/restore.sh` 是恢复逻辑的唯一可信源，文档只描述、不重复实现
- `tailscaled.state` 是密钥：永远不要提交、不要打印、不要贴到 issue 里
- 发布历史入口：[`docs/releases/README.md`](../releases/README.md)
