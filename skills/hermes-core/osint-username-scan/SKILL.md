---
name: osint-username-scan
description: Use when scanning a username/email across platforms (OSINT).
---

# OSINT Username Scan & Server Tool Venvs

## Tool locations (already installed)

- `~/tools/user-scanner-venv/bin/user-scanner` — OSINT suite (2521 username modules, 210+ email modules). MCP server: `user-scanner-venv/bin/user-scanner-mcp` (stdio).
- `~/tools/scrapling-venv/` — Scrapling (Fetcher = curl_cffi TLS-impersonated HTTP; StealthyFetcher = headless browser for anti-bot pages).
- Repo sources for all installed tools live in `~/tools/` (cloned shallow).

## Installing/updating a tool into a venv

1. Create/refresh with `uv venv ~/tools/<name>-venv`, then install with `uv pip install --python <venv>/bin/python <pkg>`.
   - NEVER call `<venv>/bin/pip` — `uv venv` does not create a pip binary; the call fails with 'No such file or directory' and wastes a cycle.
   - Python 3.11 is the system interpreter; some tools demand Node >= 24 while the server has Node 22 — prefer the prebuilt npm package over a source build in that case.
2. For Scrapling install the extra, not the bare package: `uv pip install "scrapling[all]"` — bare install omits curl_cffi and the fetchers raise ModuleNotFoundError on import. Then run `scrapling install` for browser engines; if its bundled `playwright install-deps` step fails (needs sudo), run `<venv>/bin/python -m playwright install chromium` directly — the browser is what matters.
3. Verify every install with a live call, not `--help`: e.g. `Fetcher.get('https://example.com')` must return status 200.

## Running a username scan

```bash
cd ~/tools && user-scanner-venv/bin/user-scanner -u USERNAME --all --no-nsfw -f json -o ~/.hermes/cache/scratch/<name>.json
```

- Add `-m <module>` or `-c <category>` to narrow; `--all` + `--no-nsfw` is the default for a full footprint request.
- Expect ~half the modules to error (403/timeout) from a datacenter IP — that is regional blocking, not a tool fault. Mention it; do not retry them without a proxy file (`-P`).
- Report as: counts (Found / Not Found / Error), then each Found entry with URL + extra metadata, then the JSON path.

## Verifying 'Found' hits before reporting

user-scanner's Found verdicts include false positives. For each hit, probe the URL yourself and compare against a baseline:

1. Fetch the profile URL with `Fetcher.get(..., impersonate='chrome')`; confirm the page actually renders the username (soft-404s and SPA shells return 200 with no profile).
2. Probe a BASELINE: the same site with a username you know is fake (random string). If the baseline shows the same 200/'found' behavior, the site is blanket-blocking and the hit is unverifiable — say so instead of reporting it as confirmed.
3. Cross-check a claimed platform hit against search engines (`"<username>" <platform>`) and Wayback (`archive.org/wayback/available?url=<url>`) before calling it confirmed.

## Anti-block fallbacks

- Instagram blocks datacenter IPs at the HTTP layer (429 via user-scanner; `ERR_HTTP_RESPONSE_CODE_FAILURE` even in StealthyFetcher). Don't burn minutes retrying; fall back to: IG topsearch API, Wayback availability, Ghostarchive search, and web_search for `"<username>"` — and state plainly that IG itself is unverifiable from this server without residential proxies.
- Sites behind an anti-bot interstitial ('One moment, please...' / wsidchk JS) will not yield content even in StealthyFetcher; treat them as unverifiable rather than looping on fetch variants.
