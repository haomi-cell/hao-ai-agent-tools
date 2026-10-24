# Skill files — yang disalin installer ke agent

`setup.sh` menyalin skill berikut ke folder skills agent kamu (`~/.hermes/skills/integrasi/` secara default — ubah lewat env `SKILLS_DIR`):

## 1. karpathy-guidelines
- Sumber: `Andrej-karpathy-skills/skills/karpathy-guidelines/` (SKILL.md + CLAUDE.md)
- Fungsi: behavioral guidelines coding LLM — think before coding, simplicity first, surgical changes, goal-driven execution.

## 2. ecc-skills/ (311 skills)
- Sumber: `ECC/skills/*/SKILL.md`
- Fungsi: workflow development lengkap — TDD, code review, security scan, agent orchestration, framework patterns (django, fastapi, react, golang, dll).
- Disalin ke subfolder `ecc-skills/` agar tidak menimpa skill lain yang namanya sama.

## 3. archify
- Sumber: package lokal (sudah ada di server `~/tools/archify`).
- Installer tidak menyalinnya otomatis — kalau punya repo/paket archify, salin `SKILL.md`-nya ke `$SKILLS_DIR/archify/`.

## Struktur hasil install
```
~/.hermes/skills/integrasi/
├── karpathy-guidelines/
│   ├── SKILL.md
│   └── CLAUDE.md
├── ecc-skills/
│   ├── tdd-workflow/SKILL.md
│   ├── security-scan/SKILL.md
│   └── ... (311 folder)
└── archify/ (manual)
```
