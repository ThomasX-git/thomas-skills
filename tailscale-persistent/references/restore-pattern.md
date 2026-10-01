# Verified restore script — customization notes

`assets/restore.sh` is the verified, idempotent restore script. Its logic comes
from a script battle-tested through two real platform resets on 2026-10-01
(19s and 15s recoveries from a warm local `.deb` cache, node identity preserved,
no re-auth). The OpenSSH parts of the original were removed per this skill's
scope; everything else is unchanged.

## Before first use

Edit the three variables at the top of `assets/restore.sh`:

| Variable | What to set |
|---|---|
| `PERSIST_DIR` | The one directory that survives resets |
| `HOSTNAME` | Stable node name, identical across restores |
| `UBUNTU_CODENAME` | `lsb_release -cs` (e.g. `noble`) |
| `BROKEN_MIRROR` | Optional: an apt mirror hostname known-unreachable in your base image; empty = skip |

Then copy it into the persist dir: `cp assets/restore.sh <persist-dir>/restore.sh`.

## Deploy checklist (first machine)

1. `cp assets/tailscaled-override.conf <persist-dir>/units/` (drop-in for the official unit)
2. `cp assets/restore.sh <persist-dir>/restore.sh` (after editing variables)
3. Fill `<persist-dir>/backups/` with `tailscaled.state` and
   `tailscale-archive-keyring.gpg` (only while `tailscale status` is logged in)
4. Optionally fill `<persist-dir>/debs/` with `apt-get download` output
5. `sudo <persist-dir>/restore.sh` once to prove the loop closes,
   then simulate or wait for a reset and run it again

## Design notes (why the script looks this way)

- **Idempotency:** every section checks current state first; re-running on a
  healthy node is a no-op apart from refreshing the `tailscaled.state` backup.
- **Backup refresh (step 0):** keeps the identity backup current on every healthy
  run, so the next restore never uses a stale identity. Never refresh while
  `tailscale status` reports `Logged out`.
- **Install order:** local `.deb`s first (fast, offline), apt as fallback.
- **Unit strategy:** the official `tailscaled.service` is used as-is. Daemon flags
  (`--tun=userspace-networking`) go through `/etc/default/tailscaled`'s `FLAGS`;
  proxy cleanup goes through a `tailscaled.service.d/override.conf` drop-in.
- **Hostname stability:** keep `--hostname` identical across restores so the
  tailnet shows one stable node instead of duplicates.
- **`| head -4 || true`:** under `set -o pipefail`, `head` exiting early raises
  SIGPIPE (exit 141) in `tailscale status`; the `|| true` keeps the script alive
  after verification output.
- **deb822 safety:** never delete a whole `URIs:` line when replacing a bad apt
  mirror; re-add the line if missing, substitute the host otherwise.
