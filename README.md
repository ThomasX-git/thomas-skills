# Thomas Skills

Reusable agent skills for real-world ops work: install once, restore fast, stay connected.

This repository ships independent skill packages. Start by choosing the one that matches your problem, then install only what you need.

## Choose a Skill

| Skill | When to use | Best for | Docs |
| --- | --- | --- | --- |
| `tailscale-persistent` | You run Tailscale on Ubuntu/Debian in an ephemeral environment where `/usr`, `/etc`, `/var` reset but one directory persists | install once, authenticate once, restore in seconds without re-auth | [Guide](docs/usage/tailscale-persistent.md) |

If you are not sure which one to use, go straight to the [Skill Matrix](docs/usage/skill-matrix.md).

## Recommended Starting Points

- I do not know which skill to use: [Skill Matrix](docs/usage/skill-matrix.md)
- I want the fastest install path: [Quickstart](docs/usage/quickstart.md)
- I prefer Chinese docs: [中文说明](docs/zh/README.zh-CN.md)
- I want a repo walkthrough first: [Golden Path](docs/usage/golden-path.md)

## Install

Skill packages in this repo follow the `SKILL.md` convention and work with
Codex-style and Claude-style skill directories:

- user scope (Codex): `$HOME/.agents/skills`
- user scope (Claude Code): `$HOME/.claude/skills`
- repo scope: `.agents/skills` or `.claude/skills`

Install one skill by copying its folder:

```bash
mkdir -p ~/.agents/skills
cp -R tailscale-persistent ~/.agents/skills/
```

Then restart your agent or reload skills so the new package is discovered.

If you want help deciding which folder to copy, start with the [Skill Matrix](docs/usage/skill-matrix.md).

## Docs

- [Quickstart](docs/usage/quickstart.md)
- [Skill Matrix](docs/usage/skill-matrix.md)
- [tailscale-persistent Guide](docs/usage/tailscale-persistent.md)
- [FAQ](docs/usage/faq.md)
- [Troubleshooting](docs/usage/troubleshooting.md)
- [Examples](docs/usage/examples.md)
- [Chinese Overview](docs/zh/README.zh-CN.md)
- [Release Notes](docs/releases/README.md)

## Repository Layout

```text
tailscale-persistent/           skill package (SKILL.md + assets/ + references/)
docs/usage/                     newcomer and usage guides
docs/zh/                        Chinese entry docs
docs/releases/                  release notes
tests/                          repository-level regression checks
```

## For Maintainers

- Run repository-level docs checks with `python3 -m unittest discover tests -v`
- Keep `tailscale-persistent/assets/restore.sh` as the verified source of truth; usage docs describe it but never duplicate its logic
- Treat `tailscaled.state` as a secret: never commit a real one, never paste its contents into docs or issues
- Keep release history in [docs/releases/README.md](docs/releases/README.md)
