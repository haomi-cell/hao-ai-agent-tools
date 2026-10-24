#!/usr/bin/env bash
# Tools AI Agen Hao — verifikasi semua komponen
set -e
TOOLS_DIR="${TOOLS_DIR:-$HOME/tools}"
PASS=0; FAIL=0
ok()   { echo "✅ $1"; PASS=$((PASS+1)); }
bad()  { echo "❌ $1"; FAIL=$((FAIL+1)); }

# 1. user-scanner
if "$TOOLS_DIR/user-scanner-venv/bin/user-scanner" --help >/dev/null 2>&1; then
  ok "user-scanner CLI jalan"
else bad "user-scanner CLI"; fi
if "$TOOLS_DIR/user-scanner-venv/bin/python" -c "import user_scanner.mcp" 2>/dev/null; then
  ok "user-scanner MCP server module"
else bad "user-scanner MCP (install 'user-scanner[mcp]')"; fi

# 2. scrapling
if "$TOOLS_DIR/scrapling-venv/bin/python" -c "from scrapling.fetchers import Fetcher" 2>/dev/null; then
  ok "scrapling import + fetchers"
else bad "scrapling"; fi
if "$TOOLS_DIR/scrapling-venv/bin/python" -c "
from scrapling.fetchers import Fetcher
r = Fetcher.get('https://example.com')
assert r.status == 200" 2>/dev/null; then
  ok "scrapling live fetch (example.com = 200)"
else bad "scrapling live fetch"; fi

# 3. karpathy skills
[ -f "$HOME/.hermes/skills/integrasi/karpathy-guidelines/SKILL.md" ] \
  && ok "karpathy-guidelines skill" || bad "karpathy-guidelines skill"

# 4. ECC skills
N=$(find "$HOME/.hermes/skills/integrasi/ecc-skills" -name SKILL.md 2>/dev/null | wc -l)
[ "$N" -ge 300 ] && ok "ECC skills ($N SKILL.md)" || bad "ECC skills (hanya $N)"

# 5. openclaude
if command -v openclaude >/dev/null && openclaude --version >/dev/null 2>&1; then
  ok "openclaude $(openclaude --version 2>/dev/null)"
else bad "openclaude"; fi

# 6. MoneyPrinterTurbo
if "$TOOLS_DIR/mpt-venv/bin/python" -c "import moviepy, edge_tts, fastapi" 2>/dev/null; then
  ok "MoneyPrinterTurbo venv (deps ringan)"
else bad "MoneyPrinterTurbo venv"; fi
[ -f "$TOOLS_DIR/MoneyPrinterTurbo/config.toml" ] && ok "MPT config.toml ada" || bad "MPT config.toml (isi API keys!)"

# 7. public-apis
[ -f "$TOOLS_DIR/public-apis/README.md" ] && ok "public-apis katalog" || bad "public-apis"

echo ""
echo "Hasil: $PASS OK, $FAIL GAGAL"
[ $FAIL -eq 0 ]
