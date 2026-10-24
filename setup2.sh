#!/usr/bin/env bash
# Tools AI Agen Hao — installer bagian 2 (by xMSHaomi)
# Hermes Agent (otak), repo pendukung, config MCP
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="${TOOLS_DIR:-$HOME/tools}"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.hermes/skills/integrasi}"
HERMES_DIR="${HERMES_DIR:-$HOME/.hermes}"
mkdir -p "$TOOLS_DIR" "$SKILLS_DIR" "$HERMES_DIR/skills" "$HERMES_DIR/cron" "$HERMES_DIR/memories"

echo "== Hermes Agent (otak AI agent) =="
if command -v hermes >/dev/null 2>&1; then
  echo "  hermes sudah terpasang: $(command -v hermes)"
else
  git clone --depth 1 https://github.com/NousResearch/hermes-agent "$TOOLS_DIR/hermes-agent" 2>/dev/null \
    && echo "  → install: cd $TOOLS_DIR/hermes-agent && pip install -e ." \
    || echo "  ⚠️ clone hermes-agent gagal, cek koneksi"
fi

"
echo "== archify skill + CLI =="
cp -r "$BASE/skills/archify" "$SKILLS_DIR/" && echo "  ✅ archify (skill + bin/archify.mjs)"
clone() { [ -d "$TOOLS_DIR/$2" ] && { echo "  $2 skip"; return; }; git clone --depth 1 "$1" "$TOOLS_DIR/$2" 2>/dev/null && echo "  ✅ $2" || echo "  ⚠️ $2"; }
clone https://github.com/akitaonrails/ai-memory ai-memory
clone https://github.com/perplexityai/bumblebee bumblebee
clone https://github.com/upstash/context7 context7
clone https://github.com/uiverse-io/galaxy galaxy
clone https://github.com/motiondivision/motion motion
clone https://github.com/morluto/rea rea
clone https://github.com/JuliusBrussee/caveman caveman
clone https://github.com/miqdadbadjuber/anti-slop anti-slop
clone https://github.com/petergyang/no-ai-slop no-ai-slop
clone https://github.com/saadeghi/daisyui daisyui
clone https://github.com/tabler/tabler-icons tabler-icons
clone https://github.com/Deal-Tech/dealtech-ui-for-public-component dealtech-ui-for-public-component
clone https://github.com/Isallkun/video video
clone https://github.com/debpalash/VoiceStudio VoiceStudio
clone https://github.com/calesthio/OpenMontage OpenMontage
clone https://github.com/harry0703/MoneyPrinterTurbo MoneyPrinterTurbo
clone https://github.com/public-apis/public-apis public-apis
[ -d "$TOOLS_DIR/MoneyPrinterTurbo" ] && [ ! -f "$TOOLS_DIR/MoneyPrinterTurbo/config.toml" ] && \
  cp "$TOOLS_DIR/MoneyPrinterTurbo/config.example.toml" "$TOOLS_DIR/MoneyPrinterTurbo/config.toml" 2>/dev/null || true

echo "== MCP config =="
sed "s|<TOOLS_DIR>|$TOOLS_DIR|g" "$BASE/mcp/user-scanner.mcp.json" > "$HERMES_DIR/mcp-user-scanner.json" 2>/dev/null \
  && echo "  ✅ $HERMES_DIR/mcp-user-scanner.json"

echo ""
echo "Total skill terpasang: $(find "$SKILLS_DIR" -name SKILL.md | wc -l)"
echo "✅ Selesai. Jalankan ./verify.sh"
