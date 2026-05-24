#!/usr/bin/env python3
"""Update all linted dates to 2026-05-23."""
import pathlib, re

root = pathlib.Path("/home/chad/workspace/tmp/drone-wiki-cc/wiki/articles")
pattern = re.compile(r'<!-- linted: 2026-05-2[12] -->')
replacement = '<!-- linted: 2026-05-23 -->'

updated = []
for f in root.rglob("*.md"):
    text = f.read_text()
    if pattern.search(text):
        f.write_text(pattern.sub(replacement, text))
        updated.append(f)

for f in sorted(updated):
    print(f.relative_to(root.parent.parent))
print(f"\nUpdated {len(updated)} files.")
