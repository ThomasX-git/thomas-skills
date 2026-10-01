# Troubleshooting

Repo-level triage for the `tailscale-persistent` skill. The per-failure runbook lives in [`tailscale-persistent/references/troubleshooting.md`](../../tailscale-persistent/references/troubleshooting.md); this page tells you where to look first.

## Skill not discovered after install

- Confirm the folder landed where your agent scans: `~/.agents/skills/tailscale-persistent/SKILL.md` (Codex) or `~/.claude/skills/tailscale-persistent/SKILL.md` (Claude Code).
- Restart the agent or open a fresh session so it rescans skill directories.
- Ask explicitly: `Use the tailscale-persistent skill to …`.

## `restore.sh` refuses to run

- It must run as root: `sudo <persist-dir>/restore.sh`. A non-root run dies early by design.
- `PERSIST_DIR`, `HOSTNAME`, `UBUNTU_CODENAME` at the top of the script must be edited before first use (defaults are placeholders).

## `tailscaled` won't start under systemd (TUN / EPERM)

Set `USE_USERSPACE_TUN=1` in `restore.sh` so `/etc/default/tailscaled` gets `FLAGS="--tun=userspace-networking"`. Full diagnosis in the [skill runbook](../../tailscale-persistent/references/troubleshooting.md#tun-device-creation-blocked-tunsetiff---eperm).

## Control-plane handshake fails with HTTP 400

Proxy env vars leaked into the daemon. Set `CLEAR_PROXY=1` so the official unit gets the `UnsetEnvironment` drop-in from `assets/tailscaled-override.conf`.

## `apt-get update` fails after a reset

- `/etc/apt/sources.list.d/tailscale.list` must exist with the `signed-by` keyring option; `restore.sh` recreates it from the `backups/` keyring.
- On Ubuntu 24.04+ deb822 sources, never delete a whole `URIs:` line — re-add it if missing, substitute the host otherwise. Set `BROKEN_MIRROR` in `restore.sh` when the base image ships an unreachable mirror.

## Node shows `Logged out` after restore

The backup was taken while logged out, or the state file was not restored before `tailscale up`. Run `tailscale up` interactively once, complete auth, re-capture `tailscaled.state`, then re-run restore.

## Watchdog restores every cycle

The status check ran as non-root. Re-run the check with `sudo -n timeout 10 tailscale status`; if `sudo -n` fails, the watchdog cannot self-heal and should report instead of retrying.

## Still stuck

1. Capture: `systemctl status tailscaled`, `sudo tailscale status`, and the tail of `restore.sh` output.
2. Match the symptom against the [skill runbook](../../tailscale-persistent/references/troubleshooting.md).
3. File an issue with the matched section, what you already tried, and the captured output (redact tailnet IPs / node names if sensitive).
