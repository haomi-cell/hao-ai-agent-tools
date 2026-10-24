#!/usr/bin/env bash
# Tools AI Agen Hao — installer SEMUA komponen (by xMSHaomi)
# Bagian 2: Hermes Agent, openclaude/openclaw, semua skills, repo pendukung
set -e
BASE="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="${TOOLS_DIR:-$HOME/tools}"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.hermes/skills/integrasi}"
HERMES_DIR="${HERMES_DIR:-$HOME/.hermes}"
mkdir -p "$TOOLS_DIR" "$SKILLS_DIR"

clone() { # clone <url> <dir>
  [ -d "$TOOLS_DIR/$2" ] && { echo "  $2 sudah ada, skip"; return; }
  git clone --depth 1 "$1" "$TOOLS_DIR/$2" 2>/dev/null && echo "  ✅ $2" || echo "  ⚠️ $2 gagal"
}

echo "== 9/8+ Hermes Agent (otak AI agent) =="
if command -v hermes >/dev/null 2>&1; then
  echo "  hermes sudah terpasang: $(command -v hermes)"
else
  git clone --depth 1 https://github.com/NousResearch/hermes-agent "$TOOLS_DIR/hermes-agent" && \
    echo "  → install: cd $TOOLS_DIR/hermes-agent && pip install -e . (atau ikut README)"
  echo "  → referensi docs: https://hermes-agent.nousresearch.com/docs"
fi
# struktur folder config hermes
mkdir -p "$HERMES_DIR/skills/integrasi" "$HERMES_DIR/cron" "$HERMES_DIR/memories"

echo "== Skills: salin SEMUA skill dari repo ini ke $SKILLS_DIR =="
# skill bundled di repo (karpathy + ECC subset referensi)
if [ -d "$BASE/skills/karpathy-guidelines" ]; then
  cp -r "$BASE/skills/karpathy-guidelines" "$SKILLS_DIR/" 2>/dev/null || true
fi
if [ -d "$BASE/skills/ecc-skills" ]; then
  mkdir -p "$SKILLS_DIR/ecc-skills"
  cp -r "$BASE/skills/ecc-skills/." "$SKILLS_DIR/ecc-skills/" 2>/dev/null || true
fi
# ECC penuh dari source
if [ -d "$TOOLS_DIR/ECC/skills" ]; then
  mkdir -p "$SKILLS_DIR/ecc-skills"
  for d in "$TOOLS_DIR"/ECC/skills/*/; do
    n=$(basename "$d"); [ -f "$d/SKILL.md" ] && cp -r "$d" "$SKILLS_DIR/ecc-skills/$n"
  done
fi
echo "  total skill terpasang: $(find "$SKILLS_DIR" -name SKILL.md | wc -l)"

echo "== Repo pendukung di ~/tools (semua yang ada di server asli) =="
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

echo ""
echo "✅ Bagian 2 selesai. Jalankan ./verify.sh untuk cek."
