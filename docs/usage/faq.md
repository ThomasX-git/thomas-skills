# FAQ

## Which agent does this repo target?

Any agent that discovers `SKILL.md` packages (Codex-style `~/.agents/skills`, Claude-style `~/.claude/skills`). The skill content itself is plain markdown + shell and has no agent-specific dependency.

## Why back up only `tailscaled.state`?

It holds the node identity. Restoring it before `tailscale up` is what avoids re-authentication. Back it up only while `tailscale status` does NOT report `Logged out`, otherwise you snapshot a logged-out identity.

## Why the official `tailscaled.service` instead of a custom unit?

The official unit already exists from the deb package and reads daemon flags from `/etc/default/tailscaled` (`FLAGS`). Environment-specific tweaks belong in supported knobs: `FLAGS` for `--tun=userspace-networking`, a `tailscaled.service.d/override.conf` drop-in for `UnsetEnvironment`. A custom unit would fight package upgrades.

## When do I need `--tun=userspace-networking`?

When `tailscaled` under systemd cannot create a TUN device (`TUNSETIFF` → EPERM) while the same binary works from an interactive shell. That points at a seccomp filter on systemd children. Userspace networking keeps Tailscale SSH and normal tailnet traffic working; only subnet-router / exit-node duties are lost. Details: [Troubleshooting](troubleshooting.md).

## Why must the watchdog check run as root?

As a non-root user, `tailscale status` falsely reports `Not connected` even when the daemon is connected. A non-root watchdog would trigger a bogus restore every cycle. Run the check with `sudo -n` and treat a sudo failure as "cannot self-heal, report instead".

## Can I commit `tailscaled.state` to this repo?

No. Treat it as a secret: never print it, never commit it, never paste it into issues. The `.gitignore` already excludes `*.state` and `backups/`.

## Plain SSH over the tailnet IP hangs — is the skill broken?

Probably not. Some sandboxed networks silently drop TCP SYNs toward tailnet IPs below the VM layer even with `sshd` listening. Prefer `tailscale ssh <user>@<node>`, which is handled inside `tailscaled`. See [Troubleshooting](troubleshooting.md).

## Where is the authoritative workflow?

[`tailscale-persistent/SKILL.md`](../../tailscale-persistent/SKILL.md), then `assets/restore.sh` for restore logic. Usage docs here summarize; they do not override the skill package.
