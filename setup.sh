#!/usr/bin/env bash
# Tools AI Agen Hao — installer semua komponen
# Butuh: python3, pip/uv, node>=22, npm, git
set -e

BASE="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="${TOOLS_DIR:-$HOME/tools}"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.hermes/skills/integrasi}"
mkdir -p "$TOOLS_DIR" "$SKILLS_DIR"

echo "== 1/8 user-scanner (OSINT + MCP) =="
uv venv "$TOOLS_DIR/user-scanner-venv" 2>/dev/null || python3 -m venv "$TOOLS_DIR/user-scanner-venv"
uv pip install --python "$TOOLS_DIR/user-scanner-venv/bin/python" "user-scanner[mcp]" \
  || "$TOOLS_DIR/user-scanner-venv/bin/pip" install "user-scanner[mcp]"

echo "== 2/8 Scrapling (web scraping) =="
uv venv "$TOOLS_DIR/scrapling-venv" 2>/dev/null || python3 -m venv "$TOOLS_DIR/scrapling-venv"
uv pip install --python "$TOOLS_DIR/scrapling-venv/bin/python" "scrapling[all]" \
  || "$TOOLS_DIR/scrapling-venv/bin/pip" install "scrapling[all]"
"$TOOLS_DIR/scrapling-venv/bin/scrapling" install || echo "[!] scrapling install: browser deps gagal (coba sudo apt install deps playwright) — lanjut"
"$TOOLS_DIR/scrapling-venv/bin/python" -m playwright install chromium || true

echo "== 3/8 Andrej Karpathy Skills =="
git clone --depth 1 https://github.com/multica-ai/Andrej-karpathy-skills "$TOOLS_DIR/Andrej-karpathy-skills" 2>/dev/null || true
cp -r "$TOOLS_DIR/Andrej-karpathy-skills/skills/karpathy-guidelines" "$SKILLS_DIR/"
cp "$TOOLS_DIR/Andrej-karpathy-skills/CLAUDE.md" "$SKILLS_DIR/karpathy-guidelines/CLAUDE.md"

echo "== 4/8 ECC skills (311 skills) =="
git clone --depth 1 https://github.com/affaan-m/ECC "$TOOLS_DIR/ECC" 2>/dev/null || true
mkdir -p "$SKILLS_DIR/ecc-skills"
for d in "$TOOLS_DIR"/ECC/skills/*/; do
  n=$(basename "$d")
  [ -f "$d/SKILL.md" ] && cp -r "$d" "$SKILLS_DIR/ecc-skills/$n"
done

echo "== 5/8 openclaude (coding agent CLI) =="
# butuh node >= 24 untuk install npm resmi; fallback: pakai paket prebuilt
if command -v npm >/dev/null; then
  npm install --omit=dev --prefix "$TOOLS_DIR/openclaude-pkg" @twigpine/openclaude \
    || echo "[!] openclaude npm gagal — cek versi node (butuh >=24), atau build from source"
  ln -sf "$TOOLS_DIR/openclaude-pkg/node_modules/.bin/openclaude" "$HOME/.local/bin/openclaude" 2>/dev/null || true
fi

echo "== 6/8 MoneyPrinterTurbo (AI video generator, mode ringan) =="
git clone --depth 1 https://github.com/harry0703/MoneyPrinterTurbo "$TOOLS_DIR/MoneyPrinterTurbo" 2>/dev/null || true
uv venv "$TOOLS_DIR/mpt-venv" 2>/dev/null || python3 -m venv "$TOOLS_DIR/mpt-venv"
uv pip install --python "$TOOLS_DIR/mpt-venv/bin/python" moviepy edge-tts fastapi uvicorn openai loguru pydub toml pyyaml requests \
  || "$TOOLS_DIR/mpt-venv/bin/pip" install moviepy edge-tts fastapi uvicorn openai loguru pydub toml pyyaml requests
# config: copy example
[ -f "$TOOLS_DIR/MoneyPrinterTurbo/config.toml" ] || cp "$TOOLS_DIR/MoneyPrinterTurbo/config.example.toml" "$TOOLS_DIR/MoneyPrinterTurbo/config.toml" 2>/dev/null || true
echo "    -> isi API keys di $TOOLS_DIR/MoneyPrinterTurbo/config.toml (LLM + Pexels)"

echo "== 7/8 public-apis (katalog referensi) =="
git clone --depth 1 https://github.com/public-apis/public-apis "$TOOLS_DIR/public-apis" 2>/dev/null || true

echo "== 8/8 archify (skill arsitektur) =="
if [ -f "$SKILLS_DIR/archify/SKILL.md" ]; then
  echo "    sudah ada, skip"
else
  # archify: salin dari package lokal jika ada, atau dari repo skill terkait
  echo "    [!] archify butuh package lokal ~/tools/archify — salin manual SKILL.md-nya"
fi

echo ""
echo "✅ Selesai. Jalankan ./verify.sh untuk cek semua."
