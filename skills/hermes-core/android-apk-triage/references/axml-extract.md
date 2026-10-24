# Extracting strings from compiled AndroidManifest.xml (AXML)

AXML stores strings as UTF-16LE; plain `strings` misses them entirely.

```python
import re
d = open('AndroidManifest.xml','rb').read()
s = re.findall(rb'(?:[\x20-\x7e]\x00){4,}', d)
outs = list(dict.fromkeys(x.decode('utf-16-le') for x in s))
import re as r
for o in outs:
    if r.search(r'(Activity|Service|Receiver|perm|package|version|com\.)', o, r.I):
        print(o)
```

Quirks:
- Some strings carry a leading length byte before the text (e.g. `1android.accessibilityservice...`) — strip one leading non-alnum char when it looks attached.
- `strings AndroidManifest.xml` returns nothing useful; do not conclude the file is empty.
- For dex files, plain `strings` works (UTF-8) — grep for `https://`, package names, and domain patterns after filtering known library noise.