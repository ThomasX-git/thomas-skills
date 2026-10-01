# Golden Path

A first-time walkthrough of this repo, start to finish. Budget ~20 minutes (excluding the one interactive Tailscale login).

## 1. Orient (2 min)

- Read the [README](../../README.md) skill table — there is one skill: `tailscale-persistent`.
- Confirm your case matches: Ubuntu/Debian + systemd + one directory that survives resets.
- If it does not match, stop here; the skill's apt/systemd assumptions will not transfer.

## 2. Install the skill (2 min)

```bash
mkdir -p ~/.agents/skills
cp -R tailscale-persistent ~/.agents/skills/
```

Restart your agent or open a fresh session. See [Quickstart](quickstart.md).

## 3. Read the skill contract (5 min)

- [`tailscale-persistent/SKILL.md`](../../tailscale-persistent/SKILL.md) — the authoritative workflow, output contract, and operating rules.
- [`tailscale-persistent/references/restore-pattern.md`](../../tailscale-persistent/references/restore-pattern.md) — the three variables to edit and the deploy checklist.
- [tailscale-persistent Guide](tailscale-persistent.md) — the condensed version of the above.

## 4. Bind once (5 min, needs root + browser)

1. Install Tailscale per the guide.
2. `tailscale up --hostname=<node-name> --ssh`, complete the login URL.
3. Verify `sudo tailscale status` shows the node with no `Logged out` line.

## 5. Persist + prove (5 min)

1. Fill `<persist-dir>/` (`backups/`, `units/`, optional `debs/`) per the [guide](tailscale-persistent.md#3-persist-for-fast-restore).
2. Edit `PERSIST_DIR` / `HOSTNAME` / `UBUNTU_CODENAME` in `<persist-dir>/restore.sh`.
3. Run `sudo <persist-dir>/restore.sh` once on the healthy node — this proves idempotency and refreshes the backup.

## 6. Set up the watchdog (optional, 5 min)

Add a recurring task (e.g. every 15 min) implementing the check → single-restore → quiet-unless-broken policy from `SKILL.md`. Start with the [Examples](examples.md#example-watchdog-check-must-run-as-root) check command.

## Done — next pages

- Operational question → [FAQ](faq.md)
- Something breaks → [Troubleshooting](troubleshooting.md)
- Release history → [Release Notes](../releases/README.md)
