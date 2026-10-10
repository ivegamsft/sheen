#!/usr/bin/env python3
"""Stage pinned Sheen agent definitions in a governed central repository checkout."""

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

MANIFEST = "sheen-agents-manifest.json"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def stage(source, target, source_repo, ref):
    if (target / "agents").is_symlink() or (target / MANIFEST).is_symlink():
        raise ValueError("Central publication paths must not be symbolic links")
    commit = subprocess.check_output(
        ["git", "-C", str(source), "rev-parse", "HEAD"], text=True
    ).strip()
    resolved = subprocess.check_output(
        ["git", "-C", str(source), "rev-parse", f"{ref}^{{commit}}"], text=True
    ).strip()
    if not re.fullmatch(r"[0-9a-f]{40}", commit) or resolved != commit:
        raise ValueError("Source checkout must match the pinned source ref")
    definitions = [
        source / name
        for name in subprocess.check_output(
            ["git", "-C", str(source), "ls-tree", "-r", "--name-only", "HEAD", "agents"],
            text=True,
        ).splitlines()
        if re.fullmatch(r"agents/[A-Za-z0-9._-]+\.agent\.md", name)
    ]
    if not definitions:
        raise ValueError("Source contains no agent definitions")
    desired = {}
    contents = {}
    for path in definitions:
        if path.is_symlink() or not re.fullmatch(r"[A-Za-z0-9._-]+\.agent\.md", path.name):
            raise ValueError(f"Unsafe source agent: {path.name}")
        raw = subprocess.check_output(["git", "-C", str(source), "show", f"HEAD:agents/{path.name}"])
        text = raw.decode("utf-8")
        if not re.match(r"\A---\r?\n.*?\r?\n---\r?\n", text, re.S):
            raise ValueError(f"Missing agent frontmatter: {path.name}")
        name = f"agents/{path.name}"
        contents[name] = raw
        desired[name] = hashlib.sha256(raw).hexdigest()
    manifest_path = target / MANIFEST
    previous = {}
    if manifest_path.exists():
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        if data.get("schema") != "sheen-org-agents/v1" or data.get("source") != source_repo:
            raise ValueError("Unknown central publication ownership")
        previous = data["files"]
        if not isinstance(previous, dict):
            raise ValueError("Invalid central publication file map")
    # Preflight the complete owned set before any writes or stale-file removal.
    for name in sorted(previous.keys() | desired.keys()):
        if not re.fullmatch(r"agents/[A-Za-z0-9._-]+\.agent\.md", name):
            raise ValueError(f"Unsafe managed path: {name}")
        path = target / name
        if path.is_symlink() or (path.exists() and not path.is_file()):
            raise ValueError(f"Non-regular central agent: {name}")
        if path.exists():
            if name not in previous:
                raise ValueError(f"Consumer-owned central agent collision: {name}")
            if digest(path) != previous[name]:
                raise ValueError(f"Locally modified central agent: {name}")
    for name in previous.keys() - desired.keys():
        path = target / name
        if path.exists():
            path.unlink()
    for name, expected in desired.items():
        path = target / name
        if not path.exists() or digest(path) != expected:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(contents[name])
    payload = {
        "schema": "sheen-org-agents/v1",
        "source": source_repo,
        "ref": ref,
        "commit": commit,
        "files": desired,
    }
    content = json.dumps(payload, indent=2) + "\n"
    if not manifest_path.exists() or manifest_path.read_text(encoding="utf-8") != content:
        manifest_path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Staged {len(desired)} agent definitions from {source_repo}@{ref} ({commit})")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--target", type=Path, required=True)
    parser.add_argument("--source-repo", required=True)
    parser.add_argument("--ref", required=True)
    args = parser.parse_args()
    stage(args.source, args.target, args.source_repo, args.ref)
