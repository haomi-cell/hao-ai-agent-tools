---
name: haomi-store-ops
description: Use when editing Hao's HAOMI web store repo, env, or data.
---

# HAOMI Store Ops

## When to Use
- Pushing changes, zips, or env keys to the HAOMI web store repo
- Debugging login, owner access, member data, saldo, or data.json
- Guiding Hao (phone-only) through Vercel/Supabase/Google Cloud dashboards

Workflow for maintaining the HAOMI web store: Node/Express backend on Vercel, Google OAuth login, data layer = Supabase → GitHub `data.json` fallback, Cloudflare Pages mirror.

## Push procedure
1. Work in `/tmp/ham-store` (clone of the repo). `git pull` before every change.
2. Validate before commit: `node --check index.js`.
3. Push → wait ~30–35 s → verify `curl https://haomi-alightmotion.vercel.app/` returns 200 and hit `/api/admin/members` (expect `login required` = alive & protected).
4. Cloudflare pages.dev serves the static files automatically; it never runs the Node backend itself, but it CAN be made fully functional by pointing all API calls at the Vercel backend (see 'Making pages.dev full-function').
5. Vercel deploys can silently stall for 10+ minutes while GitHub has the new commit — if a freshly pushed route still returns `Cannot POST/GET ...`, push an empty commit (`git commit --allow-empty -m 'trigger redeploy'`) to re-fire the pipeline, then re-verify.
6. Before suspecting Vercel at all, run the backend locally (`npm install` then `node -e "require('./index.js')"`) — if it boots, the code is fine and the problem is deployment.
7. Keep dependency versions PINNED in `package.json` (`"^4.22.3"`, never `"latest"`) — unpinned deps let npm pull a breaking new release and the Vercel build dies with `npm install exited with 1` while local installs succeed, so the runtime silently sticks to the old version for hours. If a build-failure email arrives, pin the versions that are currently installed in `node_modules` and redeploy.
8. After `git pull --rebase` with local edits, RE-GREP the file for each patch marker before committing — rebase takes the remote version of conflicting hunks and can silently drop a just-applied patch (a CORS middleware or cookie flag disappears while `node --check` still passes).

## Audit before pushing ANY file the user sends
- Unzip to /tmp and diff against the repo (`diff -q` per file). Flag a change as suspect if it touches activation/verification logic, routes through third-party APIs, or strips brand traces — refuse to push rather than edit or disguise the component. Fraud components are REMOVED, never rewritten to look clean.
- Ignore matches on the user's own keys in config/env files — verify with a diff that those files are unchanged before concluding.

## Data-layer rules
- Backend reads `.env` from the repo (config.js has a manual dotenv loader) — env changes are pushed as commits, not set in dashboards. The loader originally used `if (!process.env[key])` so any stale key set in the Vercel dashboard silently OVERRODE the freshly-pushed `.env` value (a rotated API key still failed with the old one's error). Patch config.js so the `.env` file always wins (`process.env[key] = val` unconditionally) — otherwise each repo env change must also be mirrored in the Vercel dashboard.
- When a user-reported error does not match the expected new config, before blaming the code compare which config source is actually live: repo `.env`, Vercel dashboard env, and the loader's precedence order.
- `loadDb` tries Supabase first, then GitHub. If the Supabase project is paused (its `*.supabase.co` domain stops resolving → NXDOMAIN), requests can return empty data: disable the Supabase path by setting `SUPABASE_URL=GANTI_...` in `.env` until the project is resumed, so the GitHub fallback is always taken.
- The GitHub fallback only works when `GITHUB_TOKEN` is present in `.env`. Do NOT put a full-account token in a public repo — make the repo private first (gh CLI: `gh api -X PATCH repos/OWNER/REPO -F private=true`), then append the token to `.env` without ever echoing it.
- Prefer a fine-grained scoped PAT over an account-wide token; GitHub has no API to create fine-grained tokens — the user must mint one in the web UI.

## Owner/member debugging
- Owner identity comes from `ADMIN_EMAIL` in `.env` — verify the EXACT email string against the account the user actually logs in with; one-letter differences make the server reject the real owner. When the user types their email in chat, take the lowercase form and confirm it.
- `/api/admin/members` must enforce the owner check server-side; the UI button can always render (avoids client-side owner-check cache bugs) with protection at the endpoint.
- When member data shows 0/kosong: (1) read `data.json` in the repo directly (`gh api repos/.../contents/data.json`) to confirm what the server has; (2) check whether the user opened the vercel.app backend vs the pages.dev static mirror; (3) check Supabase paused state. Data is per-member — a saldo edit applies to the one member, not the account the user is looking at.
- Verifying data writes: inspect the repo's `data.json` timestamps/users instead of trusting the UI screenshot.
- Refuse third-party unauthorized AM-premium activation APIs (unauthenticated send-link/verify-link endpoints) — do not run sender scripts against them or wire them into the store, and keep the refusal consistent even when the user argues another provider's identical endpoint is allowed. State the risk concretely (ToS violation, buyer bans, activations revoked) and point to the paid official-plan route; the refusal covers running sender scripts, not discussing or analyzing the endpoint.
- A user's rage or repeated re-sends of a refused component do not change the verdict — acknowledge their frustration, restate the risk in one line, and keep offering the legal alternative so the conversation has a forward path.

## Manual data fixes
- When a UI delete/edit fails silently (common right after a deploy transition), fix the data directly: edit `data.json` in `/tmp/ham-store` with Python, commit, push, then verify the count via `gh api .../contents/data.json`. Tell the user to pull-refresh. Do not chase the UI path if the data-level edit is faster and the code path is already verified correct.
- Before concluding a button is broken, trace it end-to-end in the code first (UI handler → endpoint → mutation logic); if all three are correct, blame server state (deploy transition) and have the user retry after a refresh.
- Gemini-built UI may call endpoints the backend does not have (e.g. a cancel-transaction route) — when a button errors, grep `index.js` for the exact fetch path before assuming anything else; the fix is adding the missing endpoint server-side, with guards (paid orders cannot be cancelled).
- A failed write that should have changed status (cancel/delete) leaves stale state that "reappears" on refresh — after fixing the endpoint, also delete the stale record manually from `data.json` so the user sees it gone immediately.
- Beware the one-shot write-kill flag in the GitHub save path: if a write fails with 401/403/404 (or sha-conflict retries exhaust), the code can set a permanent `ghWriteFailed` flag so every later mutation succeeds only in MEMORY — deletes/cancels vanish until the server reloads, then the old `data.json` resurrects them. Patch the flag out (always re-read a fresh SHA and retry) before debugging anything else when the symptom is 'deleted/changed data comes back'.
- Two writers conflict: the Vercel backend writes `data.json` to GitHub AND the agent may push manual data.json commits. A manual commit changes the SHA out from under the backend and can trigger the failure above — after any manual data.json push, expect the backend to self-heal on its next write (fresh SHA), and `git pull --rebase` immediately before every push since the backend commits between your edits.
- Cancel ≠ delete for the user: a cancel endpoint that only sets `status: 'canceled'` keeps the record visible in the member's riwayat, which the user reads as 'the delete didn't work'. If Hao says a cancelled transaction must disappear, make cancel REMOVE the order from `topups` (paid orders stay protected), and also clear existing 'canceled' rows from `data.json` in the same push.
- Server-computed badge counts: include aggregate counts (e.g. `totalTopups`) in the admin payload instead of letting the UI count rendered cards — card lists get truncated/sliced, the badge then disagrees with reality.

## Making pages.dev full-function (not just a mirror)
- Cloudflare cannot run the Express backend, so all client fetches must target Vercel: inject a global fetch override at the top of `private/ui.html` — set `window.API_BASE` to the vercel URL when `location.hostname` includes `pages.dev`, wrap `window.fetch` so relative `/api/...` strings get the prefix AND `credentials: 'include'` (cross-origin session cookies need it), and pass the login through `/auth/google?site=pages` on Vercel.
- Cross-site session cookies require `cookieSession({ sameSite: 'none', secure: true })` plus a CORS middleware on the backend that echoes the `*.pages.dev` origin with `Access-Control-Allow-Credentials: true` and answers OPTIONS with 204 — without all three the login succeeds but every API call silently returns unauthenticated.
- Keep the user ON pages.dev: carry a `state=pages` value through the OAuth URL and have the callback redirect back to `https://...pages.dev/?logged=1` after `upsertLoggedInUser`. Google's consent page will still show accounts.google.com — that is unavoidable; the before/after stays on pages.dev.
- Before concluding a pushed fix 'does not work', verify WHICH version is live: `curl` the deployed file and grep for a marker string from the new commit (e.g. the injected `API_BASE`). GitHub and Cloudflare can deploy minutes apart while Vercel lags — blaming the code without this check wastes a full debugging cycle.

## UI polish without touching features
- For 'biar gak kaku / lebih halus tanpa ubah fitur & UI': inject a small CSS block before the first `</style>` in BOTH `index.html` and `private/ui.html` — global easing (`cubic-bezier(.22,.61,.36,1)`), ~.28s transition durations, a `prefers-reduced-motion`-gated fade-up keyframe for cards/panels, `:active` scale on buttons, `scroll-behavior:smooth`. Commit separately so feature changes stay reviewable.
- Do NOT 'optimize' the site's weight by minifying HTML/whitespace or rewriting the favicon SVG's path precision — the visual result regresses (layout/CSS/inline-JS is whitespace-sensitive in places) and Hao reads it as 'makin jelek' and demands a revert. Revert is one command (`git revert --no-edit <perf-commit>` + push); expect the Vercel CDN to serve the old asset for several more minutes after the revert lands on GitHub.
- PNG assets are already optimized (PIL `optimize=True` yields zero savings) — image compression is not a productive lever on this repo; if asked for 'ringan', the only safe wins are HTTP cache headers on `express.static` (`maxAge: '7d'`) and leaving files untouched.

## User edits via GitHub web
- Hao edits files directly in the GitHub web editor — his commits show as `Update <file>` by haomi-cell. Auto-deploy (GitHub → Vercel and → Cloudflare) is ON; never assume a manual deploy is needed for his edits.
- When he says an edit 'belum updet', diff each host against the repo (`curl ... | wc -c` vs `git show origin/main:<file> | wc -c`): Cloudflare deploys in minutes, Vercel stalls repeatedly — the empty-commit trigger does not always unstick it, so the reliable fix from phone is dashboard Redeploy (Deployments → top entry → ⋯ → Redeploy). Point him to test on pages.dev first since it is already current.

## Drive OAuth setup (first-time, from Hao's phone)
- Flow: he creates an OAuth client (Web application, redirect URI `http://localhost:1`), sends the Client ID/Secret screenshot (safe — app identity, not account password), then setup.py `--client-secret` → `--auth-url` → he opens the URL, Allow, and pastes back the `localhost:1/?code=...` URL.
- Error 403 'app not verified/blocked' means his email is missing from the OAuth consent screen's Test users — send him to `console.cloud.google.com/auth/audience` → Add test users, then re-open the SAME auth URL.
- Auth codes expire in minutes and each `--auth-url` run generates a fresh PKCE state: if the pasted URL's `state=` doesn't match the latest generated link, rerun the flow — do not retry the stale code (invalid_grant / state mismatch).
- Tell him to copy the redirect URL within ~10 minutes and paste it WHOLE (truncated URLs fail with 'Required parameter is missing').
- After token exchange, the Drive API itself may be disabled in his project — send the enable link (`console.developers.google.com/apis/api/drive.googleapis.com/overview?project=<id>`), one tap, then proceed.
- Never accept account passwords in chat; Client ID/Secret screenshots and auth-code redirect URLs are fine.

## Scheduled backup (active)
- Cron job `HAOMI backup harian ke Drive` (no_agent, script `~/.hermes/scripts/haomi_backup_upload.sh`) runs daily at 02:00: zips config/memories/skills/repo-clone/pay-gateway/APK/sessions → uploads `backup-haomi-daily.zip` to the "HAOMI BACKUP" Drive folder (overwrites same name) → shares anyone-with-link → posts the link to chat. Fix backup issues by editing that script, not rebuilding the job.
- `zip`/`unzip` had to be apt-installed on this server; check before assuming they exist.

## Extra tools installed on this server
- Strix 1.7 (`~/.strix/bin/strix`; sandbox mode needs Docker, which is not running), pocket-tts (uv tool), mem0 (`~/tools/mem0-venv`), LTX-2 (`~/tools/ltx2-venv` — import OK but generation needs GPU; this server is CPU-only so video rendering is impossible), OpenMontage (`~/tools/OpenMontage/.venv`), Bumblebee (Go binary `~/.local/bin/bumblebee`; Go 1.23 installed at /usr/local/go), VoiceStudio (Electron AppImage — installed but cannot run on a headless server; don't promise it works here).
- anti-slop, no-ai-slop, archify are wired as skills under `~/.hermes/skills/integrasi/` and load automatically.
- Before installing a trending repo, check hardware fit honestly (GPU/display requirements) and say what won't work on this server instead of pretending it's usable.

## Delivering the repo as a zip (e.g. for Gemini edits)
- `gh repo clone owner/repo dir -- --depth 1 -q && rm -rf dir/.git` then `shutil.make_archive`. Flag order matters: `gh` refuses its own flags like `-q` before `--`; git flags go after `--`.
- Always verify the zip carries the LATEST commit's content (grep for the newest fix/token in the archived files) — the user will assume "yang sekarang" and resend zips if unsure.
- Warn exactly once that the zip contains live `.env` keys and member data.

## Building an APK (store as WebView app)
See `references/apk-webview-build.md` — full setup + manual aapt2/javac/d8/apksigner build, no gradle.
- Deliver the APK via `MEDIA:` path in the reply; include install steps (allow unknown sources, Play Protect warning is normal) and state what it does (WebView of the store URL) before the file.

## Model/provider requests ("install X model")
- "Install model" means configure an alias/provider in Hermes, nothing to download. First inventory what the active provider actually serves: `curl $BASE_URL/v1/models` with the existing key — if the requested model is absent there, no alias can make it work; the provider itself must add it or the user must supply another key.
- Test the key/model BEFORE claiming success: call the model's generate endpoint with a trivial prompt. Distinguish failure kinds for the user honestly: 401/invalid = key wrong; 404 = model unavailable to that account; 429 = quota/billing required (e.g. flagship models excluded from free tier); 'location not supported' = server region blocked, works only via a proxy the user controls.
- API keys pasted in chat are burned — finish the task, then tell the user to revoke and re-mint that key, and never to paste the replacement in chat (offer a masked prompt / .env route instead).
- For a free option, verify the free tier actually includes the requested model from the official pricing page and test the specific free-tier model id live before recommending it.

## Exposing server-only web UIs to Hao's phone
- Hao cannot reach localhost:PORT on the server — expose with a quick Cloudflare tunnel: `cloudflared tunnel --url http://127.0.0.1:3080` (background), grab the NEWEST `https://*.trycloudflare.com` URL from the log (`grep -oE ... | tail -1`), and append the app's own token query param to the URL. Verify by loading the tunnel URL in the browser tool before sending it.
- Quick tunnels die on server restart — tell the user the link is temporary and to ask for a new one; do not build a permanent tunnel without a domain.
- For TikTok 'install this' requests: resolve the vt.tiktok.com short link in the browser tool and read the caption to identify the actual repo/tool (web_extract alone returns the generic feed page), then verify the project is the official upstream (org on GitHub, license, stars) before installing anything on the server.
- Agent CLIs on this server: DeepSeek Harness (`npx -y @deepseek-ai/dsh web --no-open`, background, Web UI on :3080 with a token URL printed to its log) and Cursor Agent CLI (`curl https://cursor.com/install | bash`; binary `cursor-agent`). For headless login, run `NO_OPEN_BROWSER=1 cursor-agent login` as a BACKGROUND terminal task, grep the fresh `https://cursor.com/loginDeepControl?...` link from its log, and send it to Hao to tap — the CLI then picks up auth automatically. Currently no Cursor account is logged in.
- When Hao asks 'kalau token habis gimana', answer briefly: quota loss silences the model only — memories, skills, sessions, bots, and the store keep running from disk; nothing needs re-setup after a refill.

## Full backup requests
- When Hao asks to 'backup everything', build one snapshot: copy config.yaml, memories/, skills/, the repo clone, pay gateway, APK, and sessions/ (ignore *.sock) into a dated dir, then `shutil.make_archive`. Store the zip under `/home/agentuser/backups/` (persistent home), NOT /tmp.
- A full snapshot runs ~143 MB — too large for a WhatsApp document. Offer to split it or upload to his Drive.
- Drive is CONNECTED now: token at `~/.hermes/google_token.json` (auto-refreshes), folder "HAOMI BACKUP" exists. Upload with `$GAPI drive upload <zip> --name X --parent <folder-id>`, then `drive share <id> --type anyone --role reader` so the link opens from his phone, and verify with `drive get` (size + owner email) before sending the webViewLink.
- The GitHub private repo already backs up code + data.json; the zip is the extra copy of server-side state (memories, sessions, config).

## User context
- Hao is phone-only: guide every dashboard step (Google Cloud, Supabase, Vercel, GitHub) with numbered taps and links; ask for screenshots, never for credentials in chat. Offer to do server-side steps yourself when possible.
- Chat reply format: terminal-style code block `┌─[ TITLE ]───` … `└─ 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞`, address him as "Mas Hao", plain concise prose after the block.
