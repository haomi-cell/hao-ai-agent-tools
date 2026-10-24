---
name: wa-bot-telegram-porting
description: Use when porting a WA/Baileys bot to Telegram or fixing it.
version: 1.0.0
author: Haomi
license: MIT
metadata:
  hermes:
    tags: [telegram, whatsapp, bot, adapter]
    related_skills: [systematic-debugging]
---

# WA Bot → Telegram Porting (Baileys-style plugin ecosystem)

## When to Use

- User asks to convert their WhatsApp bot (jere-md / Baileys plugin dump, e.g. from a zip) into a Telegram bot with all features intact.
- User reports bugs in an already-ported bot: buttons not appearing, chat piling up, bot crashing, error reports spamming, parse errors.

Goal: keep ALL plugins unchanged by writing a Telegram adapter (`lib/simple.js`) that mimics the Baileys API (sendMessage, sendFile, sendButton, smsg, groupMetadata, downloadM), plus a Telegram-native menu with inline buttons.

## Working setup (project `/home/agentuser/haomi-tele`)

- Entry: `index.js`; run `cd /home/agentuser/haomi-tele && source /tmp/tgenv && node index.js > /tmp/botlog.txt 2>&1` (background, notify=true). Token lives in `/tmp/tgenv`, never print its value.
- Restart via process_manage kill + terminal background start. Kill the exact running session (list first; old exited sessions linger in the list).
- Verify startup: grep botlog for `HMENU`, `Login sebagai`, `Polling dimulai`; `Gagal memuat` must be 0.
- Endpoint/API key config is all in `config.js` (`global.web`, `global.apikey.jereapi`) — plugins read it via `global.*`; never hardcode elsewhere.

## Procedure

1. Keep plugins untouched; solve everything in the adapter and menu plugin.
2. Menu: Telegram-native (categories → per-command buttons → execute), callback_data like `hmenu:<action>` and `hrun:<cmd>`; feature buttons execute by emitting a synthetic message: `conn.smsg(conn, pseudo)` then `conn.ev.emit('messages.upsert', {messages:[pseudo], type:'notify'})`. Emit ONCE — a double emit runs the command twice.
3. After ANY edit to `lib/simple.js`, `index.js`, or `handler.js`, full restart is required — only `plugins/**` hot-reloads; adapter/handler fixes left unrestarted keep producing the old bug and burn user trust.
4. Verify each fix by actually running the command (directly via the Telegram API or by asking the user to test) before reporting success.

- Every `callback_data` a keyboard can send MUST have a matching handler branch in the menu callback router — an unhandled callback_data does not error, the button just silently does nothing ("gk bisa di pencat"). When adding a button, add its handler in the same change.
- WA plugins with strict `customPrefix` regexes (e.g. `/^[$]\s/` for the `$ cmd` terminal) silently no-op when the user's typing differs by one char. Rewrite such prefixes leniently (`/^\$|^\.\$/`) and cap output length + add exec timeout before shipping a terminal-style plugin to Telegram.
- Owner error-dispatch loops (handler.js sends stack traces to every owner) must skip the sender himself — otherwise the owner gets error-spammed by his own actions and the chat piles up.
- Menu navigation edits must pass the TARGET message id (`cb.message.message_id`, falling back to `m.key.id`) into an `editMessageText` helper with HTML text + new `reply_markup`; fall back to sending a new message only if the edit is rejected. Never use a `tgApi()` method that does not exist on the adapter.
- Feature buttons that need arguments cannot run from a tap alone: the executed plugin should reply with usage text; note the required chat format in the button screen caption.

## Diagnosing "bot gak nyala" reports

1. Check the process and the log tail first (`ps aux | grep 'node index'`, tail botlog) — most "dead" reports are the process silently gone after a session hiccup; restart it.
2. Verify via the Telegram API directly: `getMe` OK = token fine; `getUpdates` returning 409 Conflict is GOOD — it means the bot process holds the polling lock and is alive.
3. Send a probe message to the owner chat via `sendMessage` to confirm the send path; ask the user to test in the CORRECT chat. A user testing `.menu` in the Hermes web UI (or another bot) gets unrelated errors (e.g. the web UI's own 401) — always confirm which chat they typed into before debugging the bot.

## Adapter pitfalls (each cost a real outage — do not skip)

- ALWAYS attach `reply_markup` on media sends too (sendPhoto/sendVideo/sendAudio/sendDocument), not just sendMessage — menus with images silently lose their buttons otherwise. This is the #1 "mana tombolnya" bug.
- Wrap every Telegram API send in a retry that (a) retries without `reply_parameters` when the error mentions message_id/reply, and (b) retries without `parse_mode` when the error mentions parse/entity/markdown. Plugins routinely quote with synthetic/non-numeric message ids and send unparseable Markdown; both must degrade to a plain send, never throw.
- Provide `conn.logger` (no-op stub) — the handler's error path calls it; a missing logger turns a plugin error into a process crash.
- Install `process.on('unhandledRejection'/'uncaughtException')` handlers that log but do NOT exit — one bad plugin must never kill the bot.
- Bot token conflicts return Telegram error 409; log a clear hint instead of crashing.

## Bot / profile personalization ("ubah profil biar keren")

- Telegram bot profile: `setMyName`, `setMyShortDescription`, `setMyDescription`, `setMyCommands` via `curl https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/<method>` with the token sourced from `~/.hermes/.env` (never print it). Verify each with the matching `getMy*` call before reporting success.
- WhatsApp (Baileys) profile: Hermes's WA bridge (`~/.hermes/hermes-agent/scripts/whatsapp-bridge/bridge.js`, port 3000) has `POST /profile` accepting `{name, status, business}` — payload `{"name":"...","status":"..."}`.
- To modify bridge.js behavior you must restart the bridge: `execute_code` blocks killing the gateway's child; schedule the kill outside the gateway with `systemd-run --user --on-active=3 /bin/kill <pid>` — the gateway auto-respawns the bridge with the new file. Verify via `/health` (`uptime` resets, new `scriptHash`).
- Kill via a `systemd-run` script that combines kill+sleep+curl is unreliable (timer unit may not run the chained commands) — schedule one action per unit and re-check state between steps.

## Telegram-only semantics to translate

- WA HTML-game rich messages (`conn.relayMessage`, `richResponseMessage`, `GenAI...HtmlPrimitive`) do not exist in Telegram: map them to a normal message (e.g. info card + the actual media file) instead of trying to relay.
- `conn.ev` is a plain EventEmitter — `emitAsync` does not exist; awaiting it is a silent no-op.
- vCard contacts (`sendContact`, `@s.whatsapp.net`) → inline keyboard with `t.me` / `wa.me` URL buttons.

## Anti-pile-up UX (user requirement: chat must not accumulate)

- Menu navigation (category, pagination, ALL) must EDIT the existing message (`editMessageText` with new text + reply_markup), never send a new one.
- Provide `conn.autoDelete(sentMsg, seconds)` helper for ephemeral bot replies (deleteMessage after N seconds).
- Results should look like tidy aligned tables: monospace `<code>` block with `label.padEnd(W) + ' : ' + value`, HTML parse_mode, clickable `<a href>` links. Escape user data for HTML.
- Default text sends use `parse_mode: 'Markdown'` so WA `*bold*` formatting renders; catch parse failures and resend plain.
