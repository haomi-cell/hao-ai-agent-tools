# Contoh pemakaian Tools AI Agen Hao

Semua contoh diasumsikan install sudah jalan (`./install.sh`) dan tools ada di `~/tools/`.

## 1. OSINT scan username (user-scanner)
```bash
# scan 1 username di semua platform (2.521 modul)
~/tools/user-scanner-venv/bin/user-scanner -u "namatarget" --all --no-nsfw -f json -o hasil.json

# scan email
~/tools/user-scanner-venv/bin/user-scanner -e "target@email.com" -f json -o hasil.json

# lihat semua kategori/modul
~/tools/user-scanner-venv/bin/user-scanner -lu
```
Hasil JSON: daftar status per platform (Found/Not Found/Error) + metadata profil (bio, avatar, follower).

## 2. Web scraping (Scrapling)
```bash
~/tools/scrapling-venv/bin/python -c "
from scrapling.fetchers import Fetcher, StealthyFetcher

# fetch cepat dengan TLS impersonation
r = Fetcher.get('https://example.com', impersonate='chrome')
print(r.status, len(r.body))

# situs anti-bot: pakai stealth browser
p = StealthyFetcher.fetch('https://situs-berat.com', headless=True, block_images=True)
print(p.status)
"
```

## 3. Coding agent headless (openclaude)
```bash
openclaude --version
openclaude -p "jelaskan struktur repo ini"   # butuh provider diset: `openclaude` lalu /provider
```

## 4. AI video generator (MoneyPrinterTurbo)
```bash
# 1) isi API keys dulu: ~/tools/MoneyPrinterTurbo/config.toml (LLM + Pexels)
cd ~/tools/MoneyPrinterTurbo
~/tools/mpt-venv/bin/python cli.py --help
```

## 5. Pakai skills (di Hermes Agent)
Skills otomatis ter-load dari `~/.hermes/skills/integrasi/` (357+ skill).
Contoh memicu skill archify (buat diagram HTML):
> "Buatkan architecture diagram dari flow checkout ini"

Contoh skill lain:
- `tdd-workflow` → "tulis test dulu untuk fitur login"
- `security-scan` → "scan keamanan repo ini"
- `osint-username-scan` → "riset username @target"

## 6. MCP: hubungkan user-scanner ke agent
Config sudah disalin ke `~/.hermes/mcp-user-scanner.json` oleh setup2.sh.
Struktur JSON-nya ada di `mcp/user-scanner.mcp.json`.
```
