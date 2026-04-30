#!/usr/bin/env python3
"""Check README.md for broken .cursorrules links."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
README = ROOT / "README.md"

pattern = re.compile(r"\(\.\/(rules\/[^)]+\.cursorrules)\)")

content = README.read_text()
links = pattern.findall(content)
missing = [link for link in links if not (ROOT / link).exists()]

if missing:
    print("Broken links detected:")
    for link in missing:
        print(f"- {link}")
    sys.exit(1)

print(f"All {len(links)} links are valid.")
