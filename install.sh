#!/usr/bin/env bash
# Tools AI Agen Hao — all-in-one installer (by xMSHaomi)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$DIR/setup.sh"
bash "$DIR/setup2.sh"
echo ""
echo "================ VERIFIKASI ================"
bash "$DIR/verify.sh" || true
echo ""
echo "Selesai. Kalau ada yang gagal, baca pesan ❌ di atas."
