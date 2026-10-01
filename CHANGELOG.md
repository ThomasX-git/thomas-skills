# Changelog

All notable changes to this repository are documented in this file.

The format is intentionally lightweight and optimized for small skill releases.

## Unreleased

### Added

- repository landing docs: README skill table, quickstart, skill matrix, FAQ, troubleshooting, examples, golden path, Chinese overview, and release-notes index
- per-skill usage guide for `tailscale-persistent` under `docs/usage/`
- repository-level docs regression tests under `tests/`

## v0.1.0 - 2026-10-01

### Added

- `tailscale-persistent` skill package: install Tailscale on Ubuntu/Debian, bind it to a tailnet once, and restore it in seconds after a root-filesystem reset without re-authenticating
- idempotent `assets/restore.sh` (verified through two real platform resets: 19s and 15s recoveries from a warm local `.deb` cache, node identity preserved)
- `assets/tailscaled-override.conf` drop-in for the official `tailscaled.service` (proxy env cleanup)
- `references/restore-pattern.md` customization and deploy checklist
- `references/troubleshooting.md` runbook: TUN/seccomp fallback, proxy HTTP 400, apt deb822 repair, `Logged out` recovery, tailnet-IP SSH hang
- watchdog health-check contract (check as root, quiet-unless-broken, at most one restore per cycle)
