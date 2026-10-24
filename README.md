# Tools AI Agen Hao — by 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞

**Creator & Owner: 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞** — semua tools, skill, dan konfigurasi dalam repositori ini dikurasi dan dipasang oleh 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞.

Repositori rangkuman + skrip setup otomatis untuk semua tool & skill AI agent yang terpasang di server `/home/agentuser/tools/` dan `~/.hermes/skills/integrasi/`. Jalankan `./setup.sh` untuk meng-install ulang semuanya dari nol di mesin baru — fungsi dan fitur 100% sama dengan yang ada di server asli.

## Isi (5 komponen utama)

### 1. user-scanner — OSINT Scanner (dengan MCP)
- Sumber: https://github.com/kaifcodec/user-scanner (v1.5.2.3, PyPI: `user-scanner`)
- Fungsi: 2-in-1 OSINT suite — scan **username** (2.521 modul, 17 kategori) & **email** (210+ layanan) di seluruh platform. Ekstrak metadata profil (bio, avatar, follower, UID), cross-scan & pivot, generator permutasi username, proxy rotation, laporan PDF/JSON/CSV.
- **MCP Server** built-in (`user-scanner-mcp`) untuk integrasi AI agent via stdio.
- Install: `pip install "user-scanner[mcp]"` (extra `mcp` WAJIB untuk MCP server; plain install tidak menyertakannya).
- Verifikasi di server: scan live `-u <user> -m github` sukses; `-lu` menampilkan 2.521 modul; MCP start OK.

### 2. Scrapling — Web Scraping Framework
- Sumber: https://github.com/D4Vinci/Scrapling
- Fungsi: scraping adaptif anti-ban — auto-healing selector, Fetcher (curl_cffi TLS impersonation), StealthyFetcher (Camoufox/patchright stealth browser), DynamicFetcher (Playwright), `scrapling install` untuk browser engine.
- Install: `pip install "scrapling[all]"` lalu `scrapling install`. **Penting:** plain `pip install scrapling` TIDAK cukup (CLI & fetchers error tanpa extras).
- Catatan server: `playwright install-deps` butuh sudo → browser chromium di-install manual via `python -m playwright install chromium`.
- Verifikasi: `Fetcher.get('https://example.com')` → 200; `StealthyFetcher` juga 200.

### 3. Andrej Karpathy Skills — CLAUDE.md
- Sumber: https://github.com/multica-ai/Andrej-karpathy-skills
- Fungsi: guidelines perilaku coding LLM — think before coding, simplicity first, surgical changes, goal-driven execution.
- Install: salin `skills/karpathy-guidelines/` (SKILL.md + CLAUDE.md) ke folder skills agent.

### 4. ECC Skills — Agent Harness (311 skills)
- Sumber: https://github.com/affaan-m/ECC (v2.2.3)
- Fungsi: 311 workflow skills untuk software development — TDD, code review, security scan, agent orchestration, dll.
- Install: salin semua folder di `ECC/skills/` yang punya `SKILL.md` ke folder skills agent.

### 5. openclaude — Coding Agent CLI
- Sumber: https://github.com/gitlawb/openclaude (npm: `@twigpine/openclaude` v0.33.0)
- Fungsi: open-source coding-agent CLI — multi provider (OpenAI-compatible, Gemini, Ollama, dll), MCP, streaming, headless mode (`-p/--print`).
- Install ringan (headless-friendly): `npm install @twigpine/openclaude` — **butuh Node ≥ 24** (server ini pakai Node 22, pakai paket prebuilt npm, bukan build from source).
- Verifikasi: `openclaude --version` → 0.33.0; `openclaude -p "..."` merespons (butuh login provider via `/provider` untuk pemakaian penuh).

## Struktur repo
```
├── README.md
├── setup.sh             ← installer otomatis semua komponen
├── verify.sh            ← cek semua tool terpasang & jalan
├── mcp/
│   └── user-scanner.mcp.json   ← konfigurasi MCP client
└── skills/
    └── README.md        ← cara install skill ke agent
```

## Cara pakai di mesin baru
```bash
git clone https://github.com/haomi-cell/hao-ai-agent-tools && cd hao-ai-agent-tools
./setup.sh      # bagian 1: 5 tools utama + MPT + public-apis + archify
./setup2.sh     # bagian 2: Hermes Agent, semua skills, 15 repo pendukung
./verify.sh     # verifikasi semua jalan
```

## Komponen lengkap (bagian 2 — setup2.sh)

### Hermes Agent — "otak" AI agent
- Sumber: https://github.com/NousResearch/hermes-agent (docs: https://hermes-agent.nousresearch.com/docs)
- Fungsi: AI agent runtime — skills, cron, memory, MCP, multi-platform (WhatsApp/Telegram). Struktur config dibuat di `~/.hermes/`.

### openclaude / openclaw
- openclaude (npm `@twigpine/openclaude` v0.33.0): coding-agent CLI multi-provider, headless `-p` mode.
- Juga tersedia sebagai paket prebuilt di `~/tools/openclaude-pkg` (Node 22 fallback).

### Skills (330+ SKILL.md di `~/.hermes/skills/integrasi/`)
- `karpathy-guidelines` (SKILL.md + CLAUDE.md)
- `ecc-skills/` — 311 workflow skills
- skill bawaan Hermes: ai-memory-*, android-apk-triage, api-portal-builder, autonomous-ai-agents, dll.

### Repo pendukung (di-clone ke `~/tools/`)
- ai-memory, bumblebee, context7, galaxy, motion, rea, caveman, anti-slop, no-ai-slop, daisyui, tabler-icons, dealtech-ui-for-public-component, video, VoiceStudio, OpenMontage

## Catatan penting
- Semua repo sumber tetap tersedia di `~/tools/` untuk referensi.
- Skill hasil install (330 entri) ada di `~/.hermes/skills/integrasi/`.
- ECC skills disalin ke subfolder `ecc-skills/` agar tidak menimpa skill `integrasi` bawaan.
