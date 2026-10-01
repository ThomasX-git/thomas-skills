# Troubleshooting

## TUN device creation blocked (TUNSETIFF -> EPERM)

**Symptom:** `tailscaled` fails to start under systemd, logs mention TUN creation
failing; starting the same binary from an interactive shell works.

**Cause:** some sandboxed platforms apply a seccomp filter to systemd children
(PID 1's subtree) that denies `TUNSETIFF`, while interactive shells are unaffected.

**Fix:** pass `--tun=userspace-networking` via the official unit's supported knob —
in `/etc/default/tailscaled`, set `FLAGS="--tun=userspace-networking"`, then
`systemctl restart tailscaled`. (Do not write a custom unit for this; the
official `tailscaled.service` already reads `$FLAGS`.) Trade-off: the node cannot
serve as a subnet router or exit node, but Tailscale SSH and normal tailnet
traffic work.

**How to confirm:** compare `grep Seccomp /proc/<pid>/status` for a shell-started
vs systemd-started `tailscaled`; an extra seccomp filter on the systemd child
plus identical capabilities points at this sandbox restriction.

## Control-plane handshake fails with HTTP 400

**Symptom:** `tailscaled` starts but `tailscale up` / `tailscale status` reports
control-plane errors containing HTTP 400.

**Cause:** `HTTP(S)_PROXY` / `ALL_PROXY` env vars leak into the daemon and the
egress proxy mangles the handshake.

**Fix:** add a drop-in override for the official unit
(see `assets/tailscaled-override.conf`):
```ini
[Service]
UnsetEnvironment=HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy
```
Install to `/etc/systemd/system/tailscaled.service.d/override.conf`, then
`systemctl daemon-reload && systemctl restart tailscaled`.

## apt source broken after reset

**Symptom:** `apt-get update` fails or sources are missing after a root reset.

**Checks:**
- `/etc/apt/sources.list.d/tailscale.list` must exist with the
  `signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg` option.
- On Ubuntu 24.04+, `/etc/apt/sources.list.d/ubuntu.sources` is deb822 format:
  never delete the whole `URIs:` line when replacing a bad mirror. If `URIs:`
  is missing, re-add it (e.g. `http://archive.ubuntu.com/ubuntu`); if a mirror
  host is unreachable, substitute the host only.
- Large index downloads (e.g. `universe` ~19MB) can be truncated through some
  egress paths; retry or use a regional mirror such as `cn.archive.ubuntu.com`
  if the default truncates.

## Node shows Logged out after restore

**Cause:** `tailscaled.state` was backed up while logged out, or not restored
before `tailscale up`.

**Fix:** only refresh the backup when `tailscale status` does NOT contain
`Logged out` (the restore pattern does this). If already logged out, run
`tailscale up` interactively once, complete the login URL, then re-run the
persist step to capture a good `tailscaled.state`.

## Plain SSH over the tailnet IP hangs

Some sandboxed networks silently drop TCP SYNs toward tailnet IPs at a layer
below the VM (no SYN-ACK, no RST), even with `sshd` listening and firewall open.
This was observed, not fully root-caused. Prefer `tailscale ssh <user>@<node>`
(Tailscale SSH is handled inside `tailscaled` and does not depend on the TUN
device or the host's TCP stack path for inbound tailnet SYNs).
