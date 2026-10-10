#!/usr/bin/env python3
"""Remove explicitly internal-only guidance before public identifier rewrites."""

import argparse
from pathlib import Path
import re


MARKER = re.compile(
    r"^\s*(?:#|<!--)\s*sheen-internal-only:(start|end)(?:\s*-->)?\s*$"
)
FILES = (
    "README.md",
    ".sheen.yml.example",
    "templates/sheen-sync.yml",
    "bootstrap.ps1",
    "bootstrap.sh",
    "docs/guides/upgrading-sheen.md",
    ".github/workflows/check-sheen-version-callable.yml",
    ".github/workflows/generate-design-md-callable.yml",
)


def public_text(text: str) -> str:
    result = []
    internal = False
    for line in text.splitlines(keepends=True):
        marker = MARKER.fullmatch(line.rstrip("\r\n"))
        if marker:
            opening = marker[1] == "start"
            if opening == internal:
                raise ValueError("Nested or unmatched internal-only marker")
            internal = opening
        elif not internal:
            result.append(line)
    if internal:
        raise ValueError("Unclosed internal-only marker")
    return "".join(result)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    root = parser.parse_args().root
    updates = {}
    for relative in FILES:
        path = root / relative
        if path.is_file():
            text = path.read_bytes().decode("utf-8")
            updates[path] = public_text(text)
    for path, text in updates.items():
        path.write_bytes(text.encode("utf-8"))


if __name__ == "__main__":
    main()
