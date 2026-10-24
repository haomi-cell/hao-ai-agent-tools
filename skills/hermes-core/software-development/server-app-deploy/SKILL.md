---
name: server-app-deploy
description: Use when deploying a web app as a persistent HTTPS service.
---

# Deploying Apps on This Server

## Procedure

1. **Audit third-party repos BEFORE running anything**: read the deploy script + main server file via `gh api repos/<owner>/<repo>/contents/<file> -q '.content' | base64 -d`. Check for shell=True / eval / exec, suspicious hardcoded hosts, and that auth is enforced (owner allowlist, not open). Explain findings before installing.
2. **Clone to `~/<appname>/`**, build frontend with Node from `~/.n-node/bin` (system Node is older — prepend it to PATH in every command).
3. **Deploy into the target install dir** with plain `cp` (backup the replaced file first). Repo deploy.sh scripts often assume a git checkout — if the target is not a git repo, run the copy steps manually instead of the script.
4. **Secrets go in `~/.hermes/.env`** — append `KEY=value` lines; never echo values back into chat.
5. **Run as a persistent user service**, never a foreground/background terminal process:
   ```
   systemd-run --user --unit=<app> --property=Restart=on-failure --property=RestartSec=5 \
     env KEY=... venv/bin/python -m uvicorn module:app --host 127.0.0.1 --port <PORT>
   ```
   Run this through execute_code (subprocess) — the terminal tool refuses long-lived server starts.
6. **Verify**: `curl -s http://127.0.0.1:<PORT>/api/health` (expect 200/JSON) and `systemctl --user is-active <unit>`.
7. **Public HTTPS via cloudflared quick tunnel**: single binary to /tmp, `nohup cloudflared tunnel --url http://127.0.0.1:<PORT> &`, extract the `https://...trycloudflare.com` URL from the log with a regex. Quick-tunnel URLs CHANGE on every restart — for a fixed URL, set up a named tunnel (needs Cloudflare account).
8. **Telegram wiring**: `setChatMenuButton` with `{"type":"web_app","text":"...","web_app":{"url":<tunnel URL>}}` using the bot token from `~/.hermes/.env`. Repeat after every tunnel URL change.

## Pitfalls

- **Check the port is free BEFORE starting**: `ss -tlnp | grep <PORT>`. Hermes built-ins (dashboard etc.) may already hold the port — kill the stale PID, then start the unit. Symptom of a stale occupant: a 4xx with an error message that exists NOWHERE in your deployed source — check what actually listens before debugging your own code.
- **Never kill or restart the Hermes gateway from inside the gateway** (execute_code/terminal in-session is a gateway child; SIGTERM kills the script). Use `systemd-run --user --on-active=3 /bin/kill <PID>` for delayed kills of OTHER processes (e.g. a bridge); the gateway auto-respawns its bridge with the new code.
- **Editable installs (.pth/finder in site-packages) resolve modules to the source dir** — after replacing a source file, RESTART the service; a health check right after deploy still runs the old module.
- **After editing a Baileys WhatsApp bridge script, restart via the delayed systemd kill above** — never from the session directly.

## Legality gate (always-on)

Refuse DDoS/attack tooling and any request to attack any target, regardless of the target's nature (gambling/scam sites included). Offer legal alternatives: official abuse-report channels (aduankonten.id — Cloudflare-gated from headless browsers; lapor.go.id — needs reCAPTCHA + account), so recommend the official WhatsApp report line the user sends themselves, or offer to send it from the user's own WA only with explicit consent. Load testing is legitimate only with strict caps (≤2 req/s, few workers, short duration) against infrastructure the user controls.