#!/usr/bin/env bash
# Tools AI Agen Hao — installer bagian 1 (by xMSHaomi)
# Semua komponen dibundel di repo ini; installer meng-copy skill & men-setup tools.
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="${TOOLS_DIR:-$HOME/tools}"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.hermes/skills/integrasi}"
mkdir -p "$TOOLS_DIR" "$SKILLS_DIR"

echo "== 1/6 user-scanner (OSINT + MCP) =="
uv venv "$TOOLS_DIR/user-scanner-venv" 2>/dev/null || python3 -m venv "$TOOLS_DIR/user-scanner-venv"
uv pip install --python "$TOOLS_DIR/user-scanner-venv/bin/python" "user-scanner[mcp]==1.5.2.3" \
  || "$TOOLS_DIR/user-scanner-venv/bin/pip" install "user-scanner[mcp]"

echo "== 2/6 Scrapling (web scraping) =="
uv venv "$TOOLS_DIR/scrapling-venv" 2>/dev/null || python3 -m venv "$TOOLS_DIR/scrapling-venv"
uv pip install --python "$TOOLS_DIR/scrapling-venv/bin/python" "scrapling[all]==0.5" \
  || "$TOOLS_DIR/scrapling-venv/bin/pip" install "scrapling[all]==0.5"
"$TOOLS_DIR/scrapling-venv/bin/scrapling" install || echo "[!] browser deps gagal — lanjut (stealth fetcher butuh ini)"
"$TOOLS_DIR/scrapling-venv/bin/python" -m playwright install chromium || true

echo "== 3/6 Skills: hermes-core (45 skill bawaan) =="
cp -r "$BASE/skills/hermes-core/." "$SKILLS_DIR/" 2>/dev/null || true

echo "== 3b/6 Skills: karpathy-guidelines =="
cp -r "$BASE/skills/karpathy-guidelines" "$SKILLS_DIR/" 2>/dev/null || true

echo "== 4/6 Skills: ECC (311 workflow skills) =="
mkdir -p "$SKILLS_DIR/ecc-skills"
cp -r "$BASE/skills/ecc-skills/." "$SKILLS_DIR/ecc-skills/" 2>/dev/null || true

echo "== 5/6 openclaude (coding agent CLI) =="
if command -v npm >/dev/null; then
  npm install --omit=dev --prefix "$TOOLS_DIR/openclaude-pkg" @twigpine/openclaude \
    || echo "[!] butuh node >=24, pakai prebuilt pkg"
  mkdir -p "$HOME/.local/bin"
  ln -sf "$TOOLS_DIR/openclaude-pkg/node_modules/.bin/openclaude" "$HOME/.local/bin/openclaude" 2>/dev/null || true
fi

echo "== 6/6 MoneyPrinterTurbo + public-apis =="
uv venv "$TOOLS_DIR/mpt-venv" 2>/dev/null || python3 -m venv "$TOOLS_DIR/mpt-venv"
uv pip install --python "$TOOLS_DIR/mpt-venv/bin/python" moviepy edge-tts fastapi uvicorn openai loguru pydub toml pyyaml requests \
  || "$TOOLS_DIR/mpt-venv/bin/pip" install moviepy edge-tts fastapi uvicorn openai loguru pydub toml pyyaml requests
echo "    -> isi API keys (LLM + Pexels) di \$TOOLS_DIR/MoneyPrinterTurbo/config.toml setelah clone repo MPT (setup2.sh)"

echo ""
echo "✅ Bagian 1 selesai. Lanjut ./setup2.sh"
