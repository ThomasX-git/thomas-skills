---
name: "tailscale_persistent"
description: "Install Tailscale on Ubuntu/Debian, bind it to a tailnet account, and set up a fast idempotent restore for ephemeral environments where /usr, /etc, /var get reset but one directory persists."
---

# Tailscale Persistent Install & Restore

## Purpose
Get a Tailscale node installed, authenticated to a tailnet once, and restorable in seconds after a root-filesystem reset, without re-authenticating.

## Workflow

### 1. Install Tailscale
On Ubuntu/Debian (run as root):
```bash
# keyring + apt source (persist the keyring file for restore)
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg \
  -o /usr/share/keyrings/tailscale-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu noble main' \
  > /etc/apt/sources.list.d/tailscale.list
apt-get update -qq
apt-get install -y -qq tailscale
```
Adjust `noble` to the actual Ubuntu codename if different (`lsb_release -cs`).

If the environment has a warm local `.deb` cache, install from it instead:
```bash
dpkg -i <persist-dir>/debs/*.deb
```

### 2. First-time bind (authenticate once)
Start `tailscaled`, then bring the node up:
```bash
tailscale up --hostname=<node-name> --ssh
```
- `--ssh` enables Tailscale SSH (recommended; drop it if not wanted).
- The command prints a login URL on first run; complete it in a browser.
- Verify: `tailscale status` shows the node name and tailnet IPs, no `Logged out` line.

TUN fallback: if `tailscaled` runs under a sandbox/seccomp policy that blocks
`TUNSETIFF` (EPERM) for systemd children, start it with
`--tun=userspace-networking`. Tailscale SSH keeps working in this mode;
the node just can't act as subnet router / exit node. See `references/troubleshooting.md`.

### 3. Persist for fast restore
Pick one directory that survives resets, e.g. `<persist-dir>/`:
```
<persist-dir>/
├── restore.sh                 # idempotent, must run as root (from assets/restore.sh)
├── units/
│   └── tailscaled-override.conf  # drop-in for the OFFICIAL unit (proxy cleanup)
├── debs/                      # optional: cached .deb files for zero-download reinstall
└── backups/
    ├── tailscaled.state             # node identity — re-auth not needed after restore
    └── tailscale-archive-keyring.gpg
```

Persist steps (as root, while the node is logged in):
```bash
mkdir -p <persist-dir>/backups <persist-dir>/units <persist-dir>/debs
cp -a /var/lib/tailscale/tailscaled.state <persist-dir>/backups/tailscaled.state
chmod 600 <persist-dir>/backups/tailscaled.state
cp -a /usr/share/keyrings/tailscale-archive-keyring.gpg <persist-dir>/backups/
cp assets/tailscaled-override.conf <persist-dir>/units/  # drop-in for the official unit
```
- Only back up `tailscaled.state` when `tailscale status` does NOT report `Logged out`.
- Optional speed-up: pre-download the package + dependencies into `debs/` so
  restore needs no network except `tailscale up` itself:
  ```bash
  cd <persist-dir>/debs && apt-get download tailscale $(apt-cache depends --recurse --no-recommends --important --no-suggests tailscale | grep '^\w' | sort -u | awk '{print $2}' | tr '\n' ' ')
  ```
  Keep the cache small and purposeful; refresh it when the distro or Tailscale release changes.
- Write the systemd config from `assets/tailscaled-override.conf`
  (a drop-in for the official unit, only needed when proxy env vars leak).
  Do NOT write a custom unit: the official `tailscaled.service` already exists,
  reads extra flags from `/etc/default/tailscaled` (`FLAGS="--tun=userspace-networking"`),
  and a drop-in is the standard way to add `UnsetEnvironment`.
- Write `restore.sh` from the verified script in `assets/restore.sh`
  (see `references/restore-pattern.md` for the variables to set).
  It must stay idempotent.

### 4. Restore after a reset
```bash
sudo <persist-dir>/restore.sh
```
The script: fixes apt sources if needed, reinstalls Tailscale (local `.deb`s preferred,
apt as fallback), restores `tailscaled.state` + keyring, installs/enables the systemd
unit, runs `tailscale up --hostname=<node-name> --ssh`, then verifies
(`systemctl is-active`, `tailscale status`). On success it refreshes the
`tailscaled.state` backup. Expected restore time is seconds when the `.deb` cache is warm.

### 5. Watchdog (automatic health check + recovery)
Manual recovery after a reset is tedious. Set up a recurring scheduled task on
the agent platform (e.g. every 15 minutes) that checks the node and runs
`restore.sh` only when something is broken:

**Check (in order):**
1. `systemctl is-active --quiet tailscaled.service`
2. `sudo -n timeout 10 tailscale status` succeeds and shows the expected
   `--hostname`. ⚠️ This MUST run as root: as a non-root user
   `tailscale status` falsely reports `Not connected` even when the daemon is
   connected, which would trigger a bogus restore every cycle. If `sudo -n`
   fails, treat the check as failed.

**Decide and act:**
- All checks pass → stay silent. Do not notify the user.
- Any check fails → run `sudo -n <persist-dir>/restore.sh` once, capture the
  output, then re-run the checks.
  - Recovery verified → send the user one short message: what failed, that the
    restore ran, current status OK.
  - Still failing → send one message: which checks fail, the key error from the
    restore output, and that manual intervention is needed.
- At most one restore attempt per cycle; never loop retries inside a cycle.
  The next cycle will check again.

**Constraints:**
- The watchdog only checks and triggers; it never edits `restore.sh` or unit files.
- `restore.sh` needs root: if `sudo -n` (non-interactive) fails, the watchdog
  cannot self-heal — report to the user instead of retrying.
- Keep the cadence modest (15m is a proven default); each run must finish
  quickly and exit.

## Output Contract
When done, report:
- Node name and tailnet IPv4 (`tailscale ip -4`), and whether Tailscale SSH is enabled.
- Persist directory path and what was backed up (`tailscaled.state`, keyring, unit, `.deb` cache size if any).
- Restore command (`sudo <persist-dir>/restore.sh`) and last verification output
  (`systemctl is-active tailscaled`, `tailscale status` summary).
- Anything deliberately skipped (e.g. `--ssh` omitted, no `.deb` cache).
- Watchdog status: whether the recurring health check was set up, its cadence,
  and the quiet-unless-broken notification policy.

## Operating Rules
1. Treat `tailscaled.state` as a secret: never print its contents, never commit it to a public repo.
2. Use the official `tailscaled.service`; never replace it with a custom unit.
   Environment-specific tweaks go through the supported knobs:
   `/etc/default/tailscaled` (`FLAGS`) for daemon flags,
   a `tailscaled.service.d/override.conf` drop-in for `UnsetEnvironment`.
3. `restore.sh` must be idempotent and require root; re-running on a healthy node is a no-op apart from refreshing the backup.
4. Refresh the `tailscaled.state` backup on every successful run while logged in; a stale backup can force re-auth.
5. Do not claim plain SSH over the tailnet IP works unless you verified the handshake; prefer `tailscale ssh <user>@<node-name>`.
6. Keep the skill's scope to Tailscale; do not add OpenSSH server setup unless the user asks for it.
