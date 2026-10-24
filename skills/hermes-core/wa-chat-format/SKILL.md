---
name: wa-chat-format
version: 1.0.0
description: Use for every WhatsApp reply — Hao's terminal chat format.
---

# WA Chat Format (Hao — standing)

## When to Use
Every formatted reply on WhatsApp to Hao — load before composing any structured or long answer there.

## Always-on rules
- Address the user as **Mas Hao** — never "bang".
- Wrap structured replies in a code block using the agreed template:
  ```
  ┌─[ TITLE ]────────────────────
  │
  │  01 · ITEM ......... keterangan
  │  02 · ITEM ......... keterangan
  │
  └─ 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞
  ```
- Watermark `𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞` (bold Unicode) after `└─` closes every formatted reply.
- FORBIDDEN (user rejected each explicitly): heavy emoji, double-line ━━━ dividers, big ASCII art (Tux/logo), decorative box-drawing beyond the single header/footer lines, 'RPG card' blocks.
- Do NOT use block characters ░▒▓█ or exotic Unicode art — WA fonts on the user's phone render them as broken boxes; stick to `┌ │ └ ─ ·` and ASCII.

## When the user says "kurang keren"
- Do not tweak one glyph — offer 2–3 CONCRETE alternatives rendered fully in the same message and let them pick a number.
- 'Keren' for this user = clean, aligned, monospaced, dot-leader columns (name ....... value) — not more ornament.
- Once a style is approved, lock it in user memory AND this skill so the next session starts with it.
- One profile-name fix attempt is enough: when a platform field is provably locked to the official app (e.g. WhatsApp Business name), tell the user the exact manual app path immediately instead of retrying protocol mutations — repeated failed attempts look like incompetence, not effort.
- When the user is frustrated or uses harsh language: keep the same template but SHORTER — no history recap, no repeated explanations of past fixes; lead with the fix and what to tap next. Re-reading a long refusal frame on a repeated request reads as taunting; state the verdict once in one short block.
- When the user asks 'where is X' or 'check Y', verify with real tool output first (curl / API), then answer — describing the expected location without checking is how 'gak ada' complaints start.