# Skill Matrix

One table to answer: which skill do I need, and where do I go next?

## Matrix

| I want to … | Use | Start with |
| --- | --- | --- |
| Install Tailscale on Ubuntu/Debian and survive root-filesystem resets without re-authenticating | `tailscale-persistent` | [Guide](tailscale-persistent.md) |
| Recover a node in seconds from a warm `.deb` cache after `/usr`, `/etc`, `/var` are wiped | `tailscale-persistent` | [Guide](tailscale-persistent.md) |
| Run a quiet-unless-broken health check that triggers a restore only when needed | `tailscale-persistent` (watchdog section) | [Guide](tailscale-persistent.md) → [Examples](examples.md) |
| Fix TUN/seccomp, proxy HTTP 400, broken apt sources, or `Logged out` state | `tailscale-persistent` (troubleshooting) | [Troubleshooting](troubleshooting.md) |

## Decision notes

- Ephemeral environment + one surviving directory + Tailscale → `tailscale-persistent`. There is currently no other skill to choose between.
- Ordinary persistent VM with no reset behavior → you still can use `tailscale-persistent` for the install + watchdog sections, but the backup/restore layout is optional.
- Non-Debian distro (RHEL, Arch, Alpine) → out of scope for the current skill; the apt/systemd assumptions do not transfer directly.

## Fallbacks

- Still unsure → read the [tailscale-persistent Guide](tailscale-persistent.md) first section (Purpose + When to use).
- Install problem → [Quickstart](quickstart.md), then [Troubleshooting](troubleshooting.md).
- Behavior question → [FAQ](faq.md).
