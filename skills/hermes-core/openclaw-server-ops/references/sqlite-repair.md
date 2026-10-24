# OpenClaw SQLite Repair Recipes

## Symptom: 'malformed database schema (idx_X) - no such table: main.Y'

An index references a table that no longer exists (partial session reset). Fix order:

1. `DROP INDEX IF EXISTS idx_X` via Node 24 sqlite (`node:sqlite` DatabaseSync) on every affected store. Files found by `grep -rl 'idx_X' ~/.openclaw --include='*.sqlite'`.
2. If even DROP fails at open time (the malformed row breaks schema load), patch `sqlite_master` with `PRAGMA writable_schema=ON` + DELETE the row — note: the schema-load error often fires BEFORE any statement, so this usually also fails.
3. Partial recovery via python sqlite3 (copy schema objects then rows to a fresh DB, skipping corrupt tables): produces a DB that PASSES open/integrity checks but FAILS `foreign_key_check` (recovered rows reference tables whose data was skipped). Doctor --fix refuses it — a partially recovered store is not a valid state.
4. Final fallback (data disposable): empty DB replace. Stop unit, move `-wal`/`-shm` aside (a stale WAL re-corrupts the replacement — move them BEFORE copying the new file), copy empty DB, start unit.

## Environment notes

- Use Node 24 `node:sqlite` or python3 stdlib sqlite3 for surgery — no sqlite3 CLI installed on the VM (only libsqlite3-0).
- Backup naming: `openclaw-agent.sqlite.corrupt-bak` next to the original.
- After repair, verify: `PRAGMA integrity_check` = ok, then gateway binds port 18789 within ~30s of start.
- Corrupt stores may exist in MULTIPLE agent directories (`agents/main/agent/` AND `agents/haomi/agent/`) — locate all copies with `grep -rl '<broken-object>' ~/.openclaw | grep sqlite` and repair each; fixing one still leaves the gateway failing on the other.
- A store that fails schema load (`malformed database schema` at open time) must have its `-wal`/`-shm` moved aside BEFORE the replacement copy — a stale WAL re-corrupts the new file on first open.
- After an empty-DB replace, the first `openclaw doctor` may still report ownership/migration refusals until the gateway has started once; start the unit FIRST and only run doctor if startup itself fails.
