#!/usr/bin/env python3
"""Find string across all wiki articles."""
import pathlib, sys

root = pathlib.Path("/home/chad/workspace/tmp/drone-wiki-cc/wiki/articles")
needle = sys.argv[1] if len(sys.argv) > 1 else "BATT_CURR_MULT"

for f in sorted(root.rglob("*.md")):
    text = f.read_text()
    if needle in text:
        for i, line in enumerate(text.splitlines(), 1):
            if needle in line:
                print(f"{f.relative_to(root.parent.parent)}:{i}: {line.strip()}")
