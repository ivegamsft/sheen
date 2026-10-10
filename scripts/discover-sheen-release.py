#!/usr/bin/env python3
"""Resolve a published Sheen release and update only the installed action pins."""

from __future__ import annotations

import base64
import json
import os
import re
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen


PUBLIC_REPOSITORY = "ivegamsft/sheen"
PRIVATE_REPOSITORY = "IBuySpy-Shared/basecoat-sheen"
RELEASE_TAG = re.compile(r"^v[0-9]+\.[0-9]+\.[0-9]+$")
COMMIT_SHA = re.compile(r"^[0-9a-f]{40}$")
ACTION_USE = re.compile(
    r"(?m)^(?P<prefix>[ \t]*uses:[ \t]*)"
    r"(?P<repository>IBuySpy-Shared/basecoat-sheen|ivegamsft/sheen)"
    r"/\.github/actions/(?P<action>sync-assets|discover-release)"
    r"@(?P<ref>[^\s#]+)(?P<suffix>[ \t]*(?:\#.*)?\r?)$"
)
SOURCE_COMMIT = re.compile(
    r"(?m)^(?P<prefix>[ \t]*source_commit:[ \t]*)[^\s#]+(?P<suffix>[ \t]*(?:\#.*)?\r?)$"
)


class DiscoveryError(RuntimeError):
    """A safe, actionable failure while resolving release metadata."""


def _request_json(url: str) -> dict:
    request = Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "basecoat-sheen-release-pin-discovery",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    try:
        with urlopen(request, timeout=20) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except HTTPError as exc:
        raise DiscoveryError(f"GitHub API request failed ({exc.code}) for {url}") from exc
    except (URLError, TimeoutError, OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise DiscoveryError(f"Could not read published Sheen release metadata: {exc}") from exc
    if not isinstance(payload, dict):
        raise DiscoveryError(f"GitHub API returned an unexpected response for {url}")
    return payload


def _published_release(desired_tag: str) -> str:
    if desired_tag:
        if not RELEASE_TAG.fullmatch(desired_tag):
            raise DiscoveryError("source_ref is a discovery-only input and must be a published vX.Y.Z release tag")
        endpoint = f"https://api.github.com/repos/{PUBLIC_REPOSITORY}/releases/tags/{quote(desired_tag, safe='')}"
    else:
        endpoint = f"https://api.github.com/repos/{PUBLIC_REPOSITORY}/releases/latest"
    release = _request_json(endpoint)
    tag = release.get("tag_name")
    if not isinstance(tag, str) or not RELEASE_TAG.fullmatch(tag):
        raise DiscoveryError("The public Sheen release API returned no valid vX.Y.Z tag")
    if release.get("draft") is True or release.get("prerelease") is True:
        raise DiscoveryError(f"Sheen release {tag} is not a published stable release")
    if desired_tag and tag != desired_tag:
        raise DiscoveryError(f"GitHub returned release {tag} when {desired_tag} was requested")
    return tag


def _public_tag_commit(tag: str) -> str:
    encoded_tag = quote(tag, safe="")
    response = _request_json(
        f"https://api.github.com/repos/{PUBLIC_REPOSITORY}/git/ref/tags/{encoded_tag}"
    )
    target = response.get("object")
    for _ in range(10):
        if not isinstance(target, dict):
            break
        sha = target.get("sha")
        kind = target.get("type")
        if not isinstance(sha, str) or not COMMIT_SHA.fullmatch(sha):
            break
        if kind == "commit":
            return sha
        if kind != "tag":
            break
        target = _request_json(
            f"https://api.github.com/repos/{PUBLIC_REPOSITORY}/git/tags/{sha}"
        ).get("object")
    raise DiscoveryError(f"Could not resolve the public commit behind Sheen release tag {tag}")


def _private_source_commit(tag: str) -> str:
    query = urlencode({"ref": tag})
    response = _request_json(
        f"https://api.github.com/repos/{PUBLIC_REPOSITORY}/contents/release-provenance.json?{query}"
    )
    if response.get("encoding") != "base64" or not isinstance(response.get("content"), str):
        raise DiscoveryError(f"Public release {tag} has no usable source commit provenance")
    try:
        encoded = "".join(response["content"].split())
        decoded = base64.b64decode(encoded, validate=True)
        provenance = json.loads(decoded.decode("utf-8"))
    except (ValueError, UnicodeError, json.JSONDecodeError) as exc:
        raise DiscoveryError(f"Public release {tag} has invalid source commit provenance") from exc
    if not isinstance(provenance, dict) or provenance.get("source_tag") != tag:
        raise DiscoveryError(f"Public release {tag} provenance does not identify the requested source tag")
    commit = provenance.get("source_commit")
    if not isinstance(commit, str) or not COMMIT_SHA.fullmatch(commit):
        raise DiscoveryError(f"Public release {tag} provenance has no valid private source commit")
    return commit


def update_action_pins(workflow: Path, desired_tag: str = "") -> dict[str, str | bool]:
    if not workflow.is_file():
        raise DiscoveryError(f"Managed consumer workflow does not exist: {workflow}")
    content = workflow.read_bytes().decode("utf-8")
    uses = list(ACTION_USE.finditer(content))
    if len(uses) != 2 or {match.group("action") for match in uses} != {"sync-assets", "discover-release"}:
        raise DiscoveryError("Expected exactly one sync-assets and one discover-release composite action pin")
    repositories = {match.group("repository") for match in uses}
    if len(repositories) != 1:
        raise DiscoveryError("The sync and discovery actions must use the same trusted Sheen repository")
    repository = repositories.pop()
    tag = _published_release(desired_tag)
    commit = _private_source_commit(tag) if repository == PRIVATE_REPOSITORY else _public_tag_commit(tag)
    source_matches = list(SOURCE_COMMIT.finditer(content))
    if len(source_matches) != 1:
        raise DiscoveryError("Expected exactly one source_commit input for the pinned sync action")

    updated = ACTION_USE.sub(
        lambda match: (
            f"{match.group('prefix')}{match.group('repository')}/.github/actions/"
            f"{match.group('action')}@{commit}{match.group('suffix')}"
        ),
        content,
    )
    updated = SOURCE_COMMIT.sub(
        lambda match: f"{match.group('prefix')}{commit}{match.group('suffix')}", updated
    )
    changed = updated != content
    if changed:
        workflow.write_bytes(updated.encode("utf-8"))
    return {"changed": changed, "tag": tag, "commit": commit, "repository": repository}


def _write_output(values: dict[str, str | bool]) -> None:
    output_path = os.environ.get("GITHUB_OUTPUT")
    if not output_path:
        return
    with open(output_path, "a", encoding="utf-8", newline="\n") as output:
        output.write(f"changed={str(values['changed']).lower()}\n")
        output.write(f"release_tag={values['tag']}\n")
        output.write(f"release_commit={values['commit']}\n")


def main() -> int:
    workspace = Path(os.environ.get("GITHUB_WORKSPACE", "."))
    workflow = workspace / ".github" / "workflows" / "sheen-sync.yml"
    try:
        result = update_action_pins(workflow, os.environ.get("SHEEN_DESIRED_TAG", "").strip())
        _write_output(result)
        print(
            f"Sheen release {result['tag']} resolves to {result['commit']} "
            f"for {result['repository']}; changed={str(result['changed']).lower()}"
        )
        return 0
    except DiscoveryError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
