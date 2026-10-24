---
name: cloudflare-tunnel-expose
description: Use when a local service needs a public URL, ports closed.
version: 1.0.0
---

# Exposing a local/private service via Cloudflare Tunnel

## When to Use
A service runs on a server with no public inbound access (NAT VPS, closed security group, home server) and the user wants a public URL. This beats buying a public IP or waiting for a reseller to open firewall rules.

## Decision: quick test vs permanent URL
- **Quick share/demo (no domain needed):** `cloudflared tunnel --url http://localhost:PORT` prints a random `https://*.trycloudflare.com` URL. Zero setup, URL dies when the process does. Use for demos.
- **Permanent (needs a domain on Cloudflare):** `cloudflared tunnel login` → `cloudflared tunnel create <name>` → config the ingress in `~/.cloudflared/config.yml` (tunnel ID + `hostname:` + `service: http://localhost:PORT`) → `cloudflared tunnel route dns <name> <hostname>` → run as a service (`cloudflared service install`).

## Rules
- Outbound-only: works through NAT/closed inbound ports because the daemon dials out; only outbound 443 to Cloudflare edges must be allowed.
- Never tunnel an unauthenticated service to a public URL without at least a token check — Cloudflare Access or app-level auth first, then expose.
- Pair with the user's constraints: they can't push to GitHub and won't run local CLIs — generate the config and commands server-side and only hand them clickable links (auth URLs) and final URLs.
- Quick tunnels drop connections on their own (process exits or edge connection dies; user sees Error 1016/1033/530) — normal, not a config mistake. If the URL backs a Telegram Mini App menu button, anything that restarts the gateway/supervisor kills the tunnel child too. Run a keeper loop (systemd user unit, ~5 min check: restart cloudflared if dead, grep the NEWEST `trycloudflare.com` URL from the log, re-POST it to `setChatMenuButton`). Repeated drop complaints = trigger to ask for a domain and go permanent.
- Start cloudflared with `setsid nohup ... &`, not as a child of an agent tool session — a supervisor restart kills its process tree, which is how the tunnel disappears. Pin the binary under `~/.local/bin/`, not `/tmp`.
- The tunnel log accumulates URLs across restarts: `grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' | tail -1` — always take the NEWEST match, not the first, or you re-POST a dead URL.
- After any gateway restart, assume the tunnel and the bot's menu-button URL are stale until re-verified; re-check with `curl -w '%{http_code}'` before telling the user it works.
- The agent tool layer forbids `nohup`/`setsid ... &` wrappers in foreground terminal calls — run `cloudflared tunnel --url ...` via the background terminal option instead, then grep the log for the URL in a separate call. (This supersedes the older setsid advice when driving through agent tools.)
