---
name: api-portal-builder
description: Use when building a whitelabeled API portal on Vercel.
---

# API Portal Builder (whitelabel API gateway)

## When to Use

Load when the user asks to build, extend, or debug their own API portal/gateway web product OR a game top-up storefront under their brand: register/login accounts, API keys (`Hao-xxx-xxx-xxx`), free vs premium tiers, daily limits, owner dashboard, QRIS auto-payment, or deploying that portal to Vercel. Also use when they report bugs in the existing portal (`~/project/search-project-AI/`).

Class recipe for a single-file Vercel serverless gateway + static HTML portal that resells an upstream API collection under the user's own brand (e.g. HAOMI). Working reference: `~/project/search-project-AI/` (`api/tools.js`, `public/tools.html`, `vercel.json`).

## Top-up storefront variant (game diamond/UC resell)

Same architecture, but the upstream is an H2H top-up supplier instead of an API tools collection:
- User flow: home grid of game cards (banner, INSTANT badge, search) → per-game page (UID + optional server/zone + WA number → pick nominal → QRIS) → automatic order to the H2H API on payment success → 'lacak transaksi' page by order ID.
- H2H provider candidates (researched, murah, all-game): VIPayment / FMPedia (depo min Rp 10rb, easiest for Indonesian resellers), Topupku, Bangjeff, Melostore H2H (no-KYC + sandbox), GoXtop (free tier 100 checks/day). All need the USER to register, deposit, and hold the API key — never accept the key in chat; have them fill it via env var or vault.
- Reuse the salvaged payment module `api/haomi-pay.js` (QRIS gateway + manual fallback + vouchers + WA notify + dual-mode storage, extracted from the old tools.js) instead of rewriting it.
- Prices per nominal are owner-defined (margin over H2H price): keep a products table editable from the owner panel, seed from the provider's price list, then set harga in the panel — user wants to set prices from the endpoint's own pricing.

## Architecture (one handler, one page)

- `api/<name>.js`: ONE Node serverless handler exporting `async (req, res)` that handles ALL routes: auth (`/api/auth` with `action=`), key validation, and catch-all proxy `/api/<group>/<tool>`.
- `public/tools.html`: one self-contained page (inline CSS/JS, dark theme), but sections must be SEPARATE PAGES, not stacked — the user rejected a single scrolling dump ('menu/tombol navigasi punya tempat sendiri, gak dicampur'). Structure: sticky glass navbar + `page-<name>` divs (home/akun/api/katalog/premium/owner), only one `.page.active` shown, `goPage(name)` switches with a fade+slide animation. Each tool entry gets a one-line Indonesian description — user explicitly asked for per-feature descriptions.
- Test-API section is a docs-style playground: Execute button, colored status-code badge (`200 OK`/error) + response-time ms, COPY JSON button, and language tabs (CURL / NODE.JS / PYTHON / PHP) each with their own COPY — not one concatenated text blob.
- Dedicated Docs page (endpoint explorer), modeled on the upstream's own docs UI: terminal-style search bar (`$ search endpoint path...`), category tab filter, endpoint cards with method badge (GET green / POST blue) + path + category chip + arrow, click-to-expand inline playground per endpoint (API key pre-filled from localStorage, one param input whose key is guessed from the path — `username` for stalkers, `query`/`text`/`prompt`/`url` by keyword), Execute, and a result pre with status+ms header. 400 endpoints don't ship as markup: extract them once from the upstream docs (regex `(GET|POST)\s*(/api/<group>/...)` pairs over the fetched docs text) into `public/endpoints.json` (a `{category: [[method, path], ...]}` map), then render/filter client-side from that file.
- Polish that reads as professional: glassmorphism cards (blur, inset top highlight, deep shadow), cubic-bezier transitions, focus-ring glow on inputs, icon-in-gradient-tile for catalog cards, neon key box with letter-spacing. Half-done styling ('nanggung') gets rejected — apply a consistent pass, not sprinkles.
- `vercel.json` rewrites: `{"source": "/api/auth", "destination": "/api/<name>.js"}` for fixed routes, plus a catch-all rewrite for proxy routes.

## Proxy rewrite pattern (critical)

- Vercel rewrites OVERWRITE `req.url` pathname to the destination file. Carry the original route in a query param (`_ep=<group>/<tool>`) and read `new URL(req.url).searchParams.get("_ep")`; fall back to parsing pathname for direct (non-Vercel) calls.
- Upstream base path usually needs an `/api/` prefix: build `` `/api/${route}` `` — omitting it returns upstream 404 "Endpoint tidak ditemukan".
- Strip `apikey` and `_ep` from forwarded params.
- Keep the upstream key server-side only (env var with hardcoded fallback per user instruction); the user's key is YOUR portal's key, never forwarded.

## Storage: dual-mode

Upstash Redis REST (`UPSTASH_REDIS_REST_URL`/`_TOKEN` env → `USE_REDIS`) when present, in-memory Maps otherwise (demo mode, resets each deploy). Wrap all access in `sGet/sSet/sDel`.

- **Every key prefix needs a branch in ALL THREE functions** (`k:` user-by-key, `u:` user-by-name, `s:` session, `inv:` invoice, `pr:` proof-TF, `v:` voucher, `bc:` broadcast, `fp:` forgot-password request). A missing branch silently returns null → symptoms are misleading "apikey tidak valid" / "sesi habis" / "invoice tidak ditemukan", not a storage error. When adding a new stored record type, add its prefix to sGet/sSet/sDel in the same edit.
- Keys: user key format `<Brand>-xxx-xxx-xxx` (3-char lowercase alnum segments, enforce by regex); owner/admin key same format.
- Password: hash with Node's built-in `crypto.scryptSync` (salted, `sc$<salt>$<hash>` format) — plain sha256+salt is too weak for a sold product; keep a `verifyPw()` that falls back to legacy sha256 records so existing accounts still log in.
- Sessions expire: store `exp: Date.now()+7*864e5` on the session record and check it wherever the token is read; delete the expired record. Tokens must not live forever.
- Rate-limit auth: per-IP counter on failed login/register (e.g. 8 fails / 15 min → 429) — otherwise passwords are bruteforceable.
- Store user record twice (`u:<name>` and `k:<apikey>`); when changing a key, delete the old `k:` entry and write the new one.

## Tiers & payment

- FREE: daily limit counter (reset when `usedDate !== today()`), cannot change own key. PREMIUM: unlimited, custom key allowed (validate against the key regex, 409 if taken).
- QRIS gateway (api.sairibot.my.id): GET `/api/invoice?apikey=&amount=` → `{invoice_id, fee, total, qris_image (data:URI), expired_at}`; GET `/api/invoice/status?apikey=&invoice_id=` → `{status: "paid"|...}`. Test real invoice creation before wiring the UI.
- Flow: `plans` (public list) → `buy` (create invoice, store `inv:<id> = {username, plan}` — bind invoice to buyer so another account can't redeem it) → `checkpay` (on `paid`: set plan + `paidUntil = now + days`, delete invoice). Plans table is one object — adding a role/price is one line.
- Gateway-down fallback: wrap `payInvoice` in try/catch; on failure return a MANUAL invoice (id `MANUAL-*`, static QRIS image served from `/public`) with a copy-exact-amount instruction. User then submits proof: `submitproof` (screenshot as base64 data:URI + claimed nominal) stores `pr:<id>`, then best-effort WA notify to owner via gateway; the gateway may not have a WA-send endpoint — always handle `wa_sent:false` gracefully since the proof still sits in the owner dashboard queue.
- Owner verification loop: `owner_proofs` (list pending) → `owner_verify` (approve → set premium + paidUntil from invoice's days; reject → mark). Show the proof screenshot inline in the owner panel.
- Vouchers: owner creates code with potongan (Rp) + max uses; `buy` accepts optional `voucher`, clamps total to a floor (Rp 1000), increments `terpakai`, rejects invalid/exhausted codes. Show a voucher input under the QRIS; applying it creates a NEW invoice and re-renders the QRIS.
- Broadcast/notif: owner sets one global `bc:latest` record (text + optional base64 image); every visitor's page polls `notif` on load and every 60s, shows a bell 🔔 with a red dot until viewed (per-visitor seen-marker in localStorage). Render the image inline if present.
- Ban system: `banned` flag stored on BOTH `u:` and `k:` records; check it in login AND key validation (403). Owner panel has ban/unban buttons per user.
- Seed a demo owner account on first request (create the `u:owner` record with the OWNER_KEY as its apikey if missing) so the user can log in with a known username/password and the owner panel auto-opens when the profile's apikey equals the owner key.
- Extras the user expects: owner revenue total (sum transaction history), CSV export of all users, editable plan prices (`owner_setprice`, persist overrides), public voucher list (active vouchers visible to all users), user transaction history (keep last N on the user record, return in `profile`), forgot-password flow (user request → WA owner → owner ACC applies the new hash), optional WA number on register so the user gets a WA notification when premium activates, and a public `/api/status` health endpoint (web/auth/upstream/storage).
- Owner panel actions (all gated on admin key): stats, per-user upgrade/downgrade, reset usage, ban/unban, delete user, verify payments, manage vouchers, broadcast.

## Testing (the part that wastes time if done wrong)

- Mock `res` to MATCH the handler's actual response calls — read `sendJson` first: if it calls `res.status(code).json(obj)`, the mock needs both `status(c){...}` and `json(o){...}`; a mock with only `setHeader/end` dies with `res.status is not a function` before any test runs. And `req` as `{method, url, headers:{...,'x-forwarded-for':'t1','content-type':'application/json'}, on(ev,cb) feeding the JSON body then 'end', end(){}}` — the handler reads the body via req.on('data'/'end'), so a plain `body` field is not enough.
- Syntax-check the handler with `node -c file.js` and inline page scripts with `new Function(scriptBody)` before any live test.
- `zip` may be missing on the host — build deliverable archives with `python3 -c` using `zipfile.ZipFile(...,'w',ZIP_DEFLATED)` walking the project (exclude node_modules/.git).
- **Each `node -e` is a fresh process — in-memory storage does NOT survive between test invocations.** Register→login→checkpay chains that share state must run inside ONE `node -e` script, or 401 "sesi habis" results are false negatives, not bugs.
- Test matrix: register → proxy (200, plan header, counter) → wrong key 401 → limit expiry → login → profile → customkey (free=403, premium=200, bad format=400) → owner actions incl. wrong adminkey → payment plans/buy/checkpay.
- Serve preview with `npx serve public -l <port>` as background terminal; sanity-check JS with `new Function(scriptBody)`.
- `browser_exec` code has NO top-level await (SyntaxError 'await outside function' kills the step before anything runs) — wrap the sequence in `function main(){ ... wait_for_load() ... } main()`.

## UI conventions (user's standing requirements)

- Visual identity: emerald/neon-green theme, left-aligned header with logo chip, mono font for keys/code — deliberately DIFFERENT from the jerexd reference; user allows functional similarity but not a lookalike skin.
- Loading screen: full hacker style — black background, matrix-rain canvas, self-typing terminal log lines, neon progress bar with % — and NO logo letter/"H" badge; user rejected the branded-letter loader explicitly.
- Creator credit `𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞` (keep the fancy unicode) in loading screen, welcome popup, and footer.
- Profile page: avatar initial + plan badge, key card with show/hide/copy/custom, daily quota progress bar, total-requests counter, device info (OS/browser/screen/battery) — but NO leaderboard/rankings; user rejected those.
- "Toxic" responses: failed validation returns a random pick from a category ROAST map (fakekey / limit / premiumonly / unpaid / spam / banned). Keep words like gembel/miskin/busuk but avoid truly reportable slurs; banned users get the harshest variants and skip the fail-streak counter.
- Failed-request spam detection: per-IP fail-streak counter; after N consecutive failures swap the normal reason for the spam roast. Reset the streak on success.
- Free/open register+login so the user can demo freely; welcome popup (once per visitor via localStorage) doubles as a VIP ad; hero banner image in the header is clickable → scrolls to plans.

## Whitelabel rule (user's standing requirement)

Context: the user is an AUTHORIZED reseller — the upstream owner knows the portal resells their API and the user pays for access. Still treat the master key as a secret and never expose upstream branding; 'authorized' covers the business relationship, not credential hygiene.

NEVER expose third-party names (upstream providers, gateways, CDNs) in any user-visible surface: page text, endpoint names, docs, or error messages. Backend code must not leak them either:

- Wrap the upstream `fetch` in try/catch and return a branded message (`Server HAOMI sedang sibuk / maintenance…`) on network failure; do the same for upstream 5xx/522 instead of passing the raw Cloudflare/upstream error body through.
- Name internal identifiers neutrally (`upstream`, `BASE_URL`) — not the provider's name.

## Logging into the user's upstream account (when asked to 'login with my account')

- Headless browser sessions cannot prompt the user to save a login (vault prompt unavailable) — direct them to run `hermes vault add` themselves instead of asking for credentials in chat.
- NEVER type a password the user pasted into chat into any page; treat it as compromised and tell them to change it. Only vault-held credentials may be filled.
- Upstream login pages guarded by Cloudflare Turnstile ('Verify you are human') cannot be completed from the headless browser — the send-OTP button stays locked. Don't burn turns on it: the working fallback is the user logging in on their own phone and sending screenshots or ONE screen recording (video works — extract plan prices, limits, key format from it), then you sync those findings into the portal.

## Workflow & user preferences

- Verify each layer with real calls before reporting done (user trusts tested features); report concisely in Indonesian, no heavy emoji/RPG styling, no ━━━ dividers.
- User wants to SEE deliverables: copy the HTML to a sendable path (`MEDIA:`) as preview before deploying; register/login intentionally free and open so they can test freely.
- README format: when the user asks for a 'struktur dashboard' README, mirror the upstream's README SHAPE (numbered sections: platform metadata, per-page structure, plan-price tables, endpoint integration flow, navigation tree in a code block) but with 100% own-brand content — and NO third-party links anywhere (no upstream URLs, WA channels, Telegram contacts); only endpoint paths may remain. Keep the visual-design/CSS section OUT (user removed it); document structure and features, not styling.
- Ship the whole project as a zip when asked for 'the complete files' — include README, api/, public/ assets (banner, static QRIS), vercel.json.
- `write_file` refuses overwriting a file not fully read this session; when replacing a file wholesale, `rm` it via terminal then `write_file` fresh.