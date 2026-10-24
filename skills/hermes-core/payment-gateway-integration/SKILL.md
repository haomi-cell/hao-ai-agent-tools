---
name: payment-gateway-integration
description: Use when adding QRIS payments to a bot or web project.
version: 1.0.0
---

# Payment Gateway Integration (QRIS) for bots & web

## Standing rules
- NEVER let a bot API token or API key reach the chat. If the user pastes one anyway, treat it as leaked: have them `/revoke` in @BotFather (or rotate the key) immediately, then install the replacement through a non-chat channel. Revoke-then-reissue is cheap; a hijacked bot is not.
- Always live-test the payment path with a real small invoice before wiring it into any product — a gateway that returns 200 but wrong amounts is worse than one that errors.
- Show the user the FEE breakdown (amount / fee / total) up front; surprise fees are the #1 complaint after the first real transaction.

## Two QRIS paths (decision)

| | Invoice aggregator API (e.g. sairi-style `/api/invoice`) | Self-hosted dynamic QRIS |
|---|---|---|
| Fee | ~Rp 120–450+ per trx, NOT deterministic (same amount returns different fees) | 0% — funds land 100% in the user's own wallet/bank |
| Status detection | Built-in: `GET /api/invoice/status?apikey=..&invoice_id=..` → `status: paid` | Must watch wallet mutations (poll/parse notifications) |
| Setup | One API key | One static personal QRIS (free from DANA/GoPay/ShopeePay merchant menu) + a small generator |

Default to aggregator when automatic status callback matters; default to self-hosted when fee is the pain point and the user owns a personal QRIS.

Third path: open-source self-hosted merchant engines (e.g. GoPay/GoBiz mutation-polling gateways on GitHub) that auto-detect payments by polling a GoBiz account and generate their own dynamic QRIS. Present them honestly: real auto-detection without an aggregator, but they require the user to register GoBiz/merchant first, charge QRIS MDR (not 0%), and polling credentials are non-official ToS territory (account flag risk) — credentials must go into server env, never chat. Compare against the two paths above before deploying one.

## CRITICAL: self-generated dynamic QRIS gets rejected by consumer apps
The EMVCo transform below produces a *technically valid* dynamic QR, but wallet apps (DANA verified by real scan; expect the same for GoPay/OVO/ShopeePay) only honor dynamic QRIS issued by a licensed PJSP — a hand-modified static payload fails at scan time with "QR sedang tidak tersedia", even with correct tag order and CRC. Do not ship the dynamic transform as a production path.

Working 0%-fee production pattern instead: keep the user's ORIGINAL static QR image as the payment QR, assign each active invoice a unique total (base amount + a small per-invoice offset, e.g. +1..+99, tracked in the DB so no two pending invoices share a total), and match incoming payments by exact amount. Nominal lock (buyer cannot edit the amount) legally requires a merchant path: DANA Bisnis / GoBiz registration (free, 1–3 day verification) or a paid aggregator — there is no code-level workaround.

## Self-hosted dynamic QRIS (technique reference only — see warning above)

Input: the QRIS *static* payload string. Get it by decoding the user's QR image (`zbarimg --raw crop.png` after cropping the QR region with PIL; pyzbar/cv2 may be missing — zbar-tools via apt works). Store the payload in a file OUTSIDE any repo, and never print it to chat.

Transform to dynamic (EMVCo 2.0):
1. `010211` → `010212` (static → dynamic, first occurrence only).
2. Remove any existing Tag 54; insert `54<2-digit-len><amount-in-IDR-int>` right before the trailing `63<2-digit-len>` CRC block.
3. Recompute CRC16-CCITT (poly 0x1021, init 0xFFFF) over the whole string + `6304`; append as 4 hex uppercase.
4. Render with `qrcode.make(payload)`.

Keep the generator as a standalone script taking the amount as argv — bots and web pages both call it; do not embed the payload in multiple places.

Verify before shipping: decode the generated QR back with zbarimg and confirm Tag 54 and the CRC are correct, and have the user scan it — a locked nominal that displays wrong is a lost sale.

## HAOMI store production pattern (Node/Express on Vercel + GitHub data.json)
- Poll status then credit with an idempotent flag: `applyCredit` runs only when `creditApplied !== true`, plus a per-order lock (`withPaymentLock`) — two simultaneous status checks must not double-credit.
- Plans encode duration in the user record: `role` + `roleExpiresAt` (ISO date; 'permanent' for lifetime). Expiry check runs on every request via a `getActiveRoleInfo` helper — never a cron job. Renewal stacks: new expiry = max(now, current expiry) + duration.
- Admin endpoints gate on an `isAdmin` allowlist email from env (`ADMIN_EMAIL`) — never on a client-visible flag; hiding a button in UI is not protection.
- Env-file override pitfall: if the backend loads a repo `.env` with `if (!process.env[key])` guards, platform-injected env vars silently override the file — rotate keys by editing the .env in-repo and invert the guard (`process.env[key] = val`) so the file wins.
- When the DB is a git-tracked JSON file, stale-sha writes make deletions "revive" on the next load. Never latch a permanent `writeFailed` flag on one failure (409/422 = refresh sha and retry; 401/403/404 = break but reset the flag on next success), and don't mix manual pushes to the data file with backend writes.
- Mirror hosts: static hosts (Cloudflare Pages) cannot run the Express backend. Patch the client so relative fetches are prefixed with the backend origin when `location.hostname` is the mirror, and point the login/OAuth button at the backend origin — otherwise login silently SPA-fallbacks and fails.

## Aggregator invoice API notes
- `GET {base}/api/invoice?apikey=..&amount=N` → `{ invoice_id, amount, fee, total, qris_image (data:PNG base64), expired_at }`. Decode base64 (strip `data:image/png;base64,`) to a file and send the image — never paste the base64 into chat.
- `GET {base}/api/invoice/status?apikey=..&invoice_id=..` → `status: paid|pending|expired`. On `paid`, mark the order fulfilled and delete/expire the invoice record so it cannot be double-redeemed.
- Fees from aggregators are non-deterministic per request even at the same amount — never hardcode a fee constant in UI; always display the `fee`/`total` from the live invoice response.
