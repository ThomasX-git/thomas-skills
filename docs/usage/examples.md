# Examples

## Example: Prove the restore loop closes

Run once while healthy (proves idempotency + refreshes the backup), then again after a reset:

```bash
sudo <persist-dir>/restore.sh
```

Expected on a healthy node: sections report already-installed / already-configured, verification passes, `tailscaled.state` backup is refreshed. Representative tail:

```text
[restore] tailscale 已安装，跳过
[restore] 验证服务状态...
[restore] 全部就绪！
[restore] 连接：tailscale ssh <user>@<node-name>
```

## Example: First-time persist (while logged in)

```bash
mkdir -p <persist-dir>/backups <persist-dir>/units <persist-dir>/debs
cp -a /var/lib/tailscale/tailscaled.state <persist-dir>/backups/tailscaled.state
chmod 600 <persist-dir>/backups/tailscaled.state
cp -a /usr/share/keyrings/tailscale-archive-keyring.gpg <persist-dir>/backups/
cp tailscale-persistent/assets/tailscaled-override.conf <persist-dir>/units/
cp tailscale-persistent/assets/restore.sh <persist-dir>/restore.sh
# then edit PERSIST_DIR / HOSTNAME / UBUNTU_CODENAME at the top of <persist-dir>/restore.sh
```

Only do this while `sudo tailscale status` does NOT report `Logged out`.

## Example: Warm the `.deb` cache for zero-download restore

```bash
cd <persist-dir>/debs && apt-get download tailscale $(apt-cache depends --recurse --no-recommends --important --no-suggests tailscale | grep '^\w' | sort -u | awk '{print $2}' | tr '\n' ' ')
```

Keep the cache small and refresh it when the distro or Tailscale release changes.

## Example: Watchdog check (must run as root)

```bash
systemctl is-active --quiet tailscaled.service \
  && sudo -n timeout 10 tailscale status | grep -q '<node-name>'
```

All pass → stay silent. Any failure → run `sudo -n <persist-dir>/restore.sh` at most once, re-check, then send one short message (recovered vs needs manual help).

## Example: Agent prompt

```text
Use the tailscale-persistent skill to verify Tailscale on this machine and set up the persist layout under <persist-dir>.
```
