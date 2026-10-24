---
name: whatsapp-profile-management
description: "Use when changing the WhatsApp profile or Baileys bridge."
version: 1.0.0
platforms: [linux]
---

# WhatsApp Profile Management (Baileys Bridge)

Change the WA account's display name, about/status, and business profile programmatically through the Hermes WhatsApp bridge (Baileys), without touching the user's phone.

## Setup already done (do not redo)

`~/.hermes/hermes-agent/scripts/whatsapp-bridge/bridge.js` has two custom endpoints:

- `POST /profile` — body `{name, status, business:{description, email?, websites?, hours?}}`
- `POST /business-name` — body `{name}`; sends a manual `w:biz` IQ to the self JID (works inconsistently; see pitfalls)

## Procedure

1. Apply the change:
   `curl -s -X POST http://127.0.0.1:3000/profile -H 'Content-Type: application/json' -d '<json>'`
2. Verify response `{"ok":true,...}` — each changed field reports true.
3. Tell the user to fully close and reopen WhatsApp to see the change.

## Restarting the bridge (after editing bridge.js)

- NEVER kill the bridge from inside the gateway (`execute_code`) — SIGTERM kills the caller. Use: `systemd-run --user --on-active=2 /bin/kill "$(ss -tlnp | grep ':3000 ' | grep -oP 'pid=\K[0-9]+' | head -1)"`
- The gateway auto-respawns the bridge within ~10-20s; wait, then confirm `curl -s http://127.0.0.1:3000/health` shows a NEW `scriptHash` and fresh `uptime`.

## Pitfalls

- Baileys exports the business-profile updater with a typo: `sock.updateBussinesProfile` (not updateBusinessProfile). Support both names.
- The `business.name` field is NOT supported by Baileys' updater; the business name shown to contacts is server-locked and can only be changed from the WA Business app on the phone. Do not burn time on protocol attempts — the `w:biz` IQ either hangs (no reply) or returns not-acceptable.
- IQ must target the self JID (`sock.user.id`), not `s.whatsapp.net` — the latter hangs forever. Add curl `--max-time 30` when testing unknown IQ paths.
- An invalid `email` value in the business payload makes the whole mutation fail with `not-acceptable` — omit email unless valid.
- Profile photo cannot be changed server-side (policy); tell the user to change it in the app.
- Update the name via BOTH `updateProfileName` (display name) and the business profile; they are stored separately and the business one wins on business accounts.
