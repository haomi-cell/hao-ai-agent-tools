# Tools AI Agen Hao — by 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞

**Creator & Owner: 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞**

Bundel lengkap AI agent tools + 330+ skills dalam satu repo. Jalankan installer-nya, semua langsung jalan: OSINT scanner, web scraping, coding agent CLI, Hermes Agent (otak agent), video generator, katalog API, dan skills workflow development.

## Isi bundel

### 🧠 Hermes Agent (otak AI agent)
AI agent runtime: skills system, cron, memory, MCP, multi-platform (WhatsApp/Telegram). Installer menyiapkan struktur `~/.hermes/` lengkap.

### 🔍 user-scanner — OSINT Scanner
Scan username di **2.521 platform** (17 kategori) + email di **210+ layanan**. Ekstrak metadata profil (bio, avatar, follower), cross-scan & pivot, permutasi username, proxy rotation, laporan PDF/JSON/CSV. Termasuk **MCP server** untuk integrasi AI agent.

### 🕸️ Scrapling — Web Scraping
Scraping adaptif anti-ban: auto-healing selector, Fetcher dengan TLS impersonation, StealthyFetcher (stealth browser), DynamicFetcher (Playwright).

### 💻 openclaude — Coding Agent CLI
CLI coding agent multi-provider (OpenAI-compatible, Gemini, Ollama, dll), MCP support, streaming, headless mode (`-p`).

### 🎬 MoneyPrinterTurbo — AI Video Generator
Generate video otomatis dari topik: script (LLM) + stock footage + TTS + subtitle. Mode ringan CLI siap pakai; isi API keys di `config.toml`.

### 📚 public-apis — Katalog API
Katalog 1.400+ API gratis per kategori untuk referensi development.

### 🏗️ archify + karpathy-guidelines + Hermes-core + ECC Skills (675+)
- **archify** — validasi arsitektur/workflow/sequence diagram
- **karpathy-guidelines** — disiplin coding LLM: think first, simplicity, surgical changes, goal-driven
- **45 hermes-core skills** — ai-memory (retrieval/routing/handoff), WhatsApp/Telegram ops, website builder, deploy hosting, email triage, productivity (Docs/Sheets/Slides), research (arxiv), software-development (TDD, debugging, deploy), OSINT scan, payment gateway, dll
- **311 ECC skills** — TDD, code review, security scan, agent orchestration, patterns Django/FastAPI/React/Go/Rust/dll

### 🧰 Repo pendukung (15)
ai-memory, bumblebee, context7, galaxy, motion, rea, caveman, anti-slop, no-ai-slop, daisyui, tabler-icons, dealtech-ui, video, VoiceStudio, OpenMontage

## Install (mesin baru)
```bash
git clone https://github.com/haomi-cell/hao-ai-agent-tools && cd hao-ai-agent-tools
./install.sh    # all-in-one: setup1 + setup2 + verify
```
atau step per step:
```bash
./setup.sh      # tools utama + skills
./setup2.sh     # Hermes Agent + repo pendukung
./verify.sh     # cek semua jalan
```
Butuh: Linux, python3, pip/uv, node ≥22, npm, git. (Windows: pakai WSL.)

## Contoh pemakaian
Lihat [`examples/EXAMPLES.md`](examples/EXAMPLES.md) — OSINT scan, scraping, coding agent, video generator, MCP, memicu skills.

## CI
Setiap push diverifikasi otomatis oleh GitHub Actions (`.github/workflows/ci.yml`): setup + verify di runner bersih. Lihat tab **Actions** untuk status terbaru.

## Verifikasi hasil install di server asli
- user-scanner CLI ✅ + MCP ✅ (scan live OK)
- Scrapling live fetch ✅ (HTTP 200)
- 330+ SKILL.md terpasang ✅
- openclaude 0.33.0 ✅ (headless jalan)
- MoneyPrinterTurbo deps ✅

## Struktur
```
├── install.sh                          ← all-in-one installer
├── setup.sh / setup2.sh / verify.sh    ← installer & verifier
├── skills/
│   ├── hermes-core/                    ← 45 skill bawaan agent
│   ├── karpathy-guidelines/            ← SKILL.md + CLAUDE.md
│   ├── archify/                        ← skill diagram + bin/ CLI
│   └── ecc-skills/                     ← 311 skill workflow
├── examples/EXAMPLES.md                ← contoh pemakaian
├── .github/workflows/ci.yml            ← CI verifikasi otomatis
├── mcp/user-scanner.mcp.json           ← konfigurasi MCP
├── THIRD-PARTY-NOTICES                 ← lisensi komponen
└── LICENSE (MIT — 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞)
```
