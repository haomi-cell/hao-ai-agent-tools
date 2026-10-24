# Trace Recipes (image → SVG / AM XML)

## Recipe 1: SVG trace (default deliverable)

```python
import subprocess, re
import numpy as np
from PIL import Image, ImageFilter

img = Image.open(src)
img2 = img.resize((img.width*2, img.height*2), Image.LANCZOS)  # upscale for smoother trace
q = img2.quantize(colors=8, method=Image.Quantize.MEDIANCUT)
arr = np.array(q)

# multi-level boundary trace: works on soft-shaded art
bw = np.zeros_like(arr, dtype=bool)
for t in np.unique(arr):
    mask = arr > t
    edges = np.array(Image.fromarray((mask*255).astype(np.uint8)).filter(ImageFilter.FIND_EDGES))
    bw |= (edges > 10)

# potrace traces BLACK; lines are the bright edge pixels -> line=True means black in PBM
h, w = bw.shape
packed = np.packbits(bw.astype(np.uint8), axis=1)
with open('/tmp/t.pbm','wb') as f:
    f.write(b'P4\n%d %d\n' % (w, h)); f.write(packed.tobytes())
subprocess.run(['potrace','/tmp/t.pbm','-s','-o','out.svg','--flat','-a','1.3','-O','0.2','-t','120'],
               check=True, capture_output=True)
```

Tuning: more `colors` / lower `-t` = more paths (finer detail, bigger file). Target ~300-600 subpaths for anime screenshots; keep file under ~600KB for web converters.

Verify result: count subpaths with `len(re.findall(r'[Mm]', d))` on the `<path d>` contents; empty d means polarity/threshold bug.

## Recipe 2: Direct AM XML — outline style (stroke only)

Layer shape that import-tested OK:

```xml
<shape id="10240001" label="path 1" startTime="0" endTime="6000" fillType="none" mediaFillMode="fill" s=".stamp">
  <transform>
    <location value="0.000000,0.000000,0.000000" />
  </transform>
  <path d="M... Z" />
  <path-stroke direction="centered" end-size="1.000000">
    <color value="#ff00ff7a" />
    <size value="3.000000" />
  </path-stroke>
</shape>
```

Root (match user's sample exactly):

```xml
<scene title="..." width="1080" height="1920" exportWidth="1080" exportHeight="1920"
 precompose="dynamicResolution" bgcolor="#ff000000" totalTime="6000" fps="30"
 modifiedTime="..." amver="1028382" ffver="106"
 am="com.alightcreative.motion/5.0.272.1028382" amplatform="android"
 retime="off" retimeAdaptFPS="false">
```

## Recipe 3: Direct AM XML — part-per-part color fill

Posterize to N colors; one `.stamp` layer per color class:

```xml
<shape id="..." label="part 1" ... fillType="color" mediaFillMode="fill" s=".stamp">
  <transform><location value="0.000000,0.000000,0.000000" /></transform>
  <fillColor value="#ffrrggbb" />
  <path d="..." />
</shape>
```

## Coordinate conversion (potrace SVG → AM canvas)

potrace writes `<g transform="translate(0,Hpt) scale(0.1,-0.1)">` and relative `l`/`c` commands. AM `<path>` has no transform. Rewrite by walking the `d` string:

- absolute point: `X = x*0.1*sx`, `Y = (Hpt - y*0.1)*sy` (y flips)
- relative `l dx dy`: accumulate then emit absolute `X Y` after `L`
- relative `c` (6 numbers): convert all 3 control-point pairs the same way, emit after `C`
- where `sx = canvasW / (imgW*0.1)`, `sy = canvasH / (imgH*0.1)`, `Hpt = imgH*0.1`

Bisection trick for import failures: cut a failing file down to its first 3 / 10 layers plus the original header — reuse the known-good `<scene>` opening line verbatim from the user's sample file.
