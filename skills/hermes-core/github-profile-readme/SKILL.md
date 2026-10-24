---
name: github-profile-readme
version: 1.0.0
description: Use when building or fixing Hao's GitHub profile README.
---

# GitHub Profile README (haomi-cell)

## When to Use
User asks to build, beautify, or fix their GitHub profile ("perbaiki profil github", "readme keren") or reports broken images on it.

## Always-on rules
- Identity is **𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞** (bold Unicode) — never "HAOMI OMNI" or any other brand name; the user has rejected that twice. Also rejected: the word "arsenal" anywhere (headers, folder names, project lists) — user finds it cringe/AI-made; use plain terms (`/projects/`, project list).
- Every clickable element (banner, typing SVG, badges) links to `https://Wa.me/+6282231669053`.
- Aesthetic = hacker developer: dark bg (#0D1117/black), matrix-green accent (00ff41) on black; user has iterated away from orange/gold and clean-minimal — current lock is green-on-black terminal style.
- Only include assets you verified return HTTP 200. **Curl-test every external image URL before committing** — dead links render as broken boxes and the user treats that as a broken build ("klo gk buat jangan taruh maksa").
- Per-repo READMEs follow the same hacker-terminal style: green-on-black, `root@xMSHaomi` prompts, tree/HTTP-output blocks; mirror each repo's actual features (read its files via the GitHub contents API before writing) and give each repo its own accent color.

## Working procedure
1. Profile repo is `haomi-cell/haomi-cell` (special repo). Auth already works via `gh` CLI; edit `/tmp/gh-profile/README.md`, then `git init` → remote add → commit → push (fresh clone may fail if repo was just created empty — init locally instead).
2. Use these providers (all support query-string theming, no build needed):
   - Banner: `capsule-render.vercel.app` — use `type=waving` with NO text and put the name as a markdown heading below it. `type=venom` renders a dark CIRCLE in the middle (user circled it as ugly); capsule-render also cannot render Unicode math-bold, so banner-rendered text never matches 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞.
   - Typing text: `readme-typing-svg.demolab.com` — URL-encode lines; the `weight` parameter has produced a broken-image icon twice — if the user reports a broken box, replace the whole typing block rather than tweak params.
   - Stats: `github-readme-stats.vercel.app` (repo stats + top-langs), theme via query params `bg_color`, `title_color`.
   - Streak: `streak-stats.demolab.com` — white NUMBERS need `currStreakNum`, `sideNums`, `total` params; `currStreakLabel`/`sideLabels` alone leave numbers invisible on dark bg.
   - Visitor counter: `komarev.com/ghpvc` (shields.io is 403 to curl and its badges with box-drawing chars/long labels fail).
   - Skills: `skillicons.dev/icons?i=...&theme=dark`.
   - Contribution snake: `raw.githubusercontent.com/platane/platane/output/github-contribution-grid-snake-dark.svg` (uses the user's own commit grid; needs a scheduled workflow to update but displays regardless).
3. Structure: waving banner (textless) → `# 𝐱𝙈𝙎𝙃𝙖𝙤𝙢𝙞` heading + short root-line → dragon GIF → badge row → terminal identity block → stats+streak → PAID SERVICE section (APK premium, web, sosmed setup + benefits, with jawa-ngapak pitch line) → motto log (trilingual EN/KO/jawa ngapak) → snake → footer.
4. To update a repo README: fresh workdir → `git init` → `git remote add origin` → `git fetch -q origin main` → `git reset -q --hard FETCH_HEAD` → overwrite README.md → commit → `git push -q origin HEAD:main`.

## Pitfalls
- GIFs hosted on random `user-images.githubusercontent.com` IDs rot (403/404). Prefer SVG services with query strings (they can't die) — if the user asks for a specific animated image, verify it with curl + `file` (must say `GIF image data`) and view it with vision before embedding.
- Chat-style ASCII art does NOT belong in the README; the profile uses real rendered images/services.
- GitHub caches README images ~1–2 min after push — tell the user to refresh and wait before judging.
- Mobile rendering is the judge: wide ASCII boxes (`╔══╗` rows wider than ~50 chars) get wrapped/split by GitHub mobile into garbage — use narrow left-rail `┃` lists instead of full boxes; keep every line short.
- The user screenshots small regions and says "jelek" pointing at ONE element. Fix that element only, explain the cause in one line, and never rewrite the whole profile per complaint — churn made things worse repeatedly.
- When the complaint is vague "kurang keren", add concrete visual content the user previously approved (dragon GIF, badges, counter) rather than retheming colors again.
- The terminal tool's lifecycle guard can block long pipe-chains and unknown scripts — fall back to `execute_code` subprocess for version checks and git push loops when terminal refuses.