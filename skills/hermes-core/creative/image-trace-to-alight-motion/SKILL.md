---
name: image-trace-to-alight-motion
description: Use when user wants a photo traced into SVG or AM XML paths.
---

# Image Trace → Alight Motion (SVG / XML)

## Workflow (order matters)

1. **Clarify the deliverable first.** "Trace/tracking foto" is ambiguous: (a) camera-keyframe tracking, (b) color-layer separation, (c) outline-only paths, (d) full part-per-part redraw. Guessing wastes many iterations — one screenshot from the user resolves it. Confirm the target app too: user's Android app is an AM fork whose parser only accepts real-AM-export-shaped XML.
2. **Vectorize with potrace** (install: `sudo apt-get install -y potrace`). Trace per color level, not raw edge detection — see references/trace-recipes.md.
3. **Emit SVG** as the intermediate deliverable; the user's own pipeline (Nexora-style web converters) accepts SVG → XML. Import-tested; this is the DEFAULT offer.
4. **Direct XML** is possible but riskier: only emit after the user proves a sample imports, or match a sample file they provide.

## Always-on rules

- **Never hand-guess AM XML format. Get a known-good sample file from the user** (any preset they successfully imported) and match its header/attributes exactly. Schema docs alone produce files that fail to import; a real export is ground truth.
- **Offer the SVG route by default.** The user already owns a working SVG→XML converter flow; direct XML is only when they ask for one file.
- **Validate XML with `xml.dom.minidom.parse()` before sending**, and send media with `MEDIA:` path.
- **Do not iterate blind on import failures.** If a file fails, stop regenerating variants; request the working sample, or bisect minimal elements (1 rect → 1 stamp path → N paths) to isolate the rejected element.
- Answer in casual Indonesian, short messages, no lecturing. The user is not a programmer: translate technical findings into plain steps.

## Key format facts (verified by import test)

- AM root needs `amver=<full build number>` (e.g. 1028382), NOT the schema-docs value 106 — this alone caused import failures.
- `location` uses 3 components: `x,y,0.000000`. Colors lowercase `#ffrrggbb`.
- Shape layer `s=".stamp"` with custom `<path d>` + `<path-stroke>` and `fillType="none"` DOES import — the element set for outline traces.
- Outline style = `fillType="none"` + `<path-stroke>` (color+size). Fill style = `fillType="color"` + `<fillColor>`.

## Pitfalls

- **potrace needs the bitmap written as PBM (P4) with packed bits — a PIL .bmp with mode 'L' silently yields an empty trace.** Pack with `np.packbits(mask, axis=1)` after a `P4\n<w> <h>\n` header.
- **PIL `FIND_EDGES` polarity: edge pixels are the BRIGHT ones; potrace traces DARK pixels.** Wrong assumption silently traces nothing. Build mask as `arr > threshold` (line=black) and verify black-pixel count before tracing.
- **Soft-shaded art (anime screenshots, smooth-gradient photos) has no ink outline — plain edge detection yields an empty/one-blob trace.** Posterize with `quantize(colors=N)` and trace each level boundary instead.
- **potrace SVG wraps paths in `transform="translate(0,H) scale(0.1,-0.1)"` with relative commands — AM `<path>` has no transform support, so rewrite coordinates into absolute scaled space** (x*0.1*sx, y flipped) rather than copying `d` verbatim.
- **Complexity cap: a 1.7MB multi-path XML was rejected by the user's upload tool while small files passed.** Simplify (fewer colors, coarser threshold, higher `-t`) when output comes out huge.

## references/

- `references/trace-recipes.md` — working recipes: SVG trace, outline XML, part-per-part color XML, coordinate conversion.
