---
name: openclaw-server-ops
description: "Use when OpenClaw gateway crashes or its DB needs repair."
author: haomi-curator
license: internal
metadata:
  hermes:
    tags: [openclaw, gateway, sqlite, server-ops]
    related_skills: [wa-hao-chat-style]
version: 1.0.1
---

# OpenClaw Server Ops (Hao's VM)

## When to Use

Any OpenClaw problem on the server: gateway crash-loop, `openclaw doctor` failures, session resets, dual-brain reactivation (Hermes + OpenClaw together).

## Always-on rules

- Run every OpenClaw CLI with Node 24 from `~/.n-node/bin` (export PATH first) — the system Node 22 embeds an SQLite build with the upstream WAL-reset corruption bug and OpenClaw refuses it; a crash-loop under system Node is a version mismatch, not a code bug.
- Restart the gateway via its systemd user unit `openclaw-gateway` (port 18789). Direct restarts of Hermes-related services from a session are guard-blocked — use cronjob_manage or the unit itself for OpenClaw.
- Never run `openclaw agent --local` while the gateway is running — the turn can execute twice.
- After any session reset or database surgery, back up the old file (`*.corrupt-bak`) before replacing — Hao may want history back.

## Startup crash-loop procedure

1. Read the real error: `systemctl --user is-active openclaw-gateway` + `journalctl --user -u openclaw-gateway -n 30`. A bare 'Failed to start' with 'Start request repeated too quickly' means `systemctl --user reset-failed` before the next start.
2. Run `openclaw doctor` (with Node 24 PATH). Decode the failing check:
   - 'malformed database schema (idx_...) - no such table' → orphan index from a partial reset. See references/sqlite-repair.md.
   - 'SQLite support is unavailable or unsafe in this Node runtime' → you are on the system Node; re-run with Node 24.
   - foreign_key_check violations after a recovered DB → the recovery dropped rows a live table still references; a partial recovery is NOT a valid state — go to step 4.
3. `openclaw doctor --fix` handles clean repair paths. Read its full output — it preserves evidence under `~/.openclaw.update-captures/`.
4. If the DB is corrupt beyond recovery AND the data is disposable (fresh-chat reset already done): stop the unit, move the WAL/SHM files aside, replace the agent store with an empty SQLite file, start the unit — OpenClaw migrates an empty store automatically. Confirm by watching the port bind (`ss -tln | grep 18789`) within ~30s.

## Dual-brain reactivation

- `openclaw-gateway` unit failing on restart after downtime: check for a stale process still holding the unit (journal shows 'Unit process ... remains running after unit stopped') — `systemctl --user stop` + `pkill -9 -f openclaw` + `reset-failed` before starting fresh.
- Startup is slow (config-ready phase alone takes ~5s, admission more); `TimeoutStartSec` default 30s can kill a healthy boot — an override drop-in (`~/.config/systemd/user/<unit>.service.d/override.conf` with `TimeoutStartSec=180`) + `daemon-reload` fixes it.
- Verify dual-brain live by asking BOTH brains the same question: OpenClaw via `openclaw agent --message "..."` (gateway mode), Hermes answers in-session. Report both answers side by side.
- `openclaw doctor` on the system shell runs Node 22 by default even with PATH exported in your kernel — call the Node 24 binary directly (`/home/agentuser/.n-node/bin/node ~/.openclaw-prefix/bin/openclaw doctor`) when diagnosing.

## Session reset (fresh chat)

- Preferred: stop the unit first — the gateway holds the SQLite connection with WAL and blocks destructive writes.
- Removing schema objects selectively leaves orphan indexes that hard-fail the next startup with 'malformed database schema'. If you drop tables, drop their dependent indexes/triggers in the same pass.

## Reference

- references/sqlite-repair.md — full repair recipes: orphan-index drop, writable_schema attempts, python sqlite3 partial recovery and its failure signature.
