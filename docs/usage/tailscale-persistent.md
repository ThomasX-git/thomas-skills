# tailscale-persistent

Install Tailscale on Ubuntu/Debian, bind it to a tailnet once, and restore it in seconds after a root-filesystem reset — without re-authenticating.

Source of truth: [`tailscale-persistent/SKILL.md`](../../tailscale-persistent/SKILL.md).
This guide summarizes the workflow; the skill file plus `assets/` and `references/` are authoritative when they disagree.

## When to use

- The machine runs Ubuntu/Debian with systemd.
- `/usr`, `/etc`, `/var` can be wiped on reset, but one directory survives (the persist dir).
- You want one stable node name on the tailnet across resets.

Out of scope: non-Debian distros, custom `tailscaled` units, OpenSSH server setup (the skill prefers Tailscale SSH).

## Install the skill

```bash
mkdir -p ~/.agents/skills
cp -R tailscale-persistent ~/.agents/skills/
```

## Workflow (summary)

### 1. Install Tailscale

On Ubuntu/Debian as root (adjust `noble` to `lsb_release -cs`):

```bash
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg \
  -o /usr/share/keyrings/tailscale-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu noble main' \
  > /etc/apt/sources.list.d/tailscale.list
apt-get update -qq
apt-get install -y -qq tailscale
```

Or install from a warm local cache: `dpkg -i <persist-dir>/debs/*.deb`.

### 2. First-time bind

```bash
tailscale up --hostname=<node-name> --ssh
```

Complete the login URL in a browser on first run, then verify `tailscale status` shows the node without a `Logged out` line.

### 3. Persist for fast restore

Layout inside the surviving directory:

```text
<persist-dir>/
├── restore.sh                    # idempotent, must run as root (from assets/restore.sh)
├── units/
│   └── tailscaled-override.conf  # drop-in for the OFFICIAL unit (proxy cleanup)
├── debs/                         # optional cached .deb files for zero-download reinstall
└── backups/
    ├── tailscaled.state          # node identity — secret, never commit
    └── tailscale-archive-keyring.gpg
```

Persist steps (as root, while logged in):

```bash
mkdir -p <persist-dir>/backups <persist-dir>/units <persist-dir>/debs
cp -a /var/lib/tailscale/tailscaled.state <persist-dir>/backups/tailscaled.state
chmod 600 <persist-dir>/backups/tailscaled.state
cp -a /usr/share/keyrings/tailscale-archive-keyring.gpg <persist-dir>/backups/
cp tailscale-persistent/assets/tailscaled-override.conf <persist-dir>/units/
```

Before first use, edit the variables at the top of `restore.sh`: `PERSIST_DIR`, `HOSTNAME`, `UBUNTU_CODENAME`, plus optional `BROKEN_MIRROR`, `USE_USERSPACE_TUN`, `CLEAR_PROXY`. See [`references/restore-pattern.md`](../../tailscale-persistent/references/restore-pattern.md).

### 4. Restore after a reset

```bash
sudo <persist-dir>/restore.sh
```

The script reinstalls (local `.deb`s first, apt fallback), restores identity + keyring, configures the official unit, runs `tailscale up`, verifies, and refreshes the backup. Expected time is seconds with a warm cache (19s / 15s observed in the verified runs).

### 5. Watchdog

Set a recurring check (e.g. every 15 minutes) that, as root:

1. checks `systemctl is-active --quiet tailscaled.service`,
2. checks `sudo -n timeout 10 tailscale status` shows the expected hostname (must run as root — non-root `tailscale status` falsely reports disconnected),
3. runs `restore.sh` at most once per cycle only when a check fails, then notifies quietly.

Full contract: [`SKILL.md`](../../tailscale-persistent/SKILL.md) sections 5 and Output Contract.

## References

- Skill: [`tailscale-persistent/SKILL.md`](../../tailscale-persistent/SKILL.md)
- Restore design notes: [`tailscale-persistent/references/restore-pattern.md`](../../tailscale-persistent/references/restore-pattern.md)
- Failure runbook: [`tailscale-persistent/references/troubleshooting.md`](../../tailscale-persistent/references/troubleshooting.md)
- Verified script: [`tailscale-persistent/assets/restore.sh`](../../tailscale-persistent/assets/restore.sh)
