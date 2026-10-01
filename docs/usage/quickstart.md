# Quickstart

Use this page when you want the shortest path from repository checkout to a working local skill install.

If you are still deciding which package to install, start with the [Skill Matrix](skill-matrix.md).

## 1. Choose one skill

This repo currently ships one package:

- `tailscale-persistent` — persistent Tailscale install and fast restore for ephemeral Ubuntu/Debian environments.

Use the [Skill Matrix](skill-matrix.md) when the choice is unclear.

## 2. Install one skill

Skill packages follow the `SKILL.md` convention. Install to whichever skill directory your agent scans:

```bash
# Codex user scope
mkdir -p ~/.agents/skills
cp -R tailscale-persistent ~/.agents/skills/

# Claude Code user scope (alternative)
mkdir -p ~/.claude/skills
cp -R tailscale-persistent ~/.claude/skills/
```

Replace the target directory with a repo scope (`.agents/skills` or `.claude/skills`) when the skill should travel with a project checkout.

## 3. Reload your agent

After copying the folder:

- restart the agent, or
- reload skills in a fresh session

The goal is simply to make the agent rescan the installed skill directories.

## 4. Verify discovery

Open a new session and ask the agent to use the installed package directly, for example:

```text
Use the tailscale-persistent skill to check whether Tailscale is healthy on this machine.
```

If the agent picks up `SKILL.md` and follows its workflow, the install worked.

## 5. Go deeper

- Need help choosing: [Skill Matrix](skill-matrix.md)
- Want the full workflow: [tailscale-persistent Guide](tailscale-persistent.md)
- Want examples: [Examples](examples.md)
- Hit a problem: [Troubleshooting](troubleshooting.md)
- Prefer a guided repo walkthrough: [Golden Path](golden-path.md)
