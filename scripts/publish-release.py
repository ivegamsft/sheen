#!/usr/bin/env python3
"""Source-only public release completion gate; no third-party Python packages."""
import json
import os
import re
import subprocess
import sys
import time

ATTEMPTS = 8
DELAY_SECONDS = 10
REQUEST_SECONDS = 20
RETRY_HTTP = {404, 408, 429, 500, 502, 503, 504}
RETRY_CURL = {5, 6, 7, 18, 28, 52, 55, 56}
API = "https://api.github.com/repos"
PUBLIC_REPO = "ivegamsft/sheen"


class ReleaseError(RuntimeError):
    pass


def request(method, repo, path, token, payload=None):
    command = [
        "curl", "--disable", "--silent", "--show-error", "--connect-timeout", "10",
        "--max-time", str(REQUEST_SECONDS), "--request", method,
        "--header", f"Authorization: token {token}",
        "--header", "Accept: application/vnd.github+json",
        "--header", "Content-Type: application/json",
        "--write-out", "\n%{http_code}", f"{API}/{repo}/{path}",
    ]
    if payload is not None:
        command += ["--data-binary", "@-"]
    try:
        result = subprocess.run(
            command, input=json.dumps(payload) if payload is not None else None,
            capture_output=True, text=True, encoding="utf-8", timeout=REQUEST_SECONDS + 5, check=False,
        )
    except subprocess.TimeoutExpired:
        return 0, "", True
    if result.returncode:
        if result.returncode in RETRY_CURL:
            return 0, "", True
        raise ReleaseError(f"{method} transport failed (curl {result.returncode})")
    body, separator, status = result.stdout.rpartition("\n")
    if not separator or not re.fullmatch(r"[1-5][0-9]{2}", status):
        raise ReleaseError(f"{method} returned an invalid HTTP status")
    return int(status), body, False


def release_record(body, tag, published=False):
    try:
        record = json.loads(body)
    except (ValueError, TypeError) as error:
        raise ReleaseError("Release response is not valid JSON") from error
    if (
        not isinstance(record, dict)
        or record.get("tag_name") != tag
        or type(record.get("id")) is not int or record["id"] <= 0
        or type(record.get("draft")) is not bool
        or type(record.get("prerelease")) is not bool
        or (published and (not isinstance(record.get("body"), str) or not record["body"].strip()))
    ):
        raise ReleaseError("Release response has invalid tag, id, state or body")
    if published and (record["draft"] or not isinstance(record.get("published_at"), str)
                      or not record["published_at"].strip()):
        raise ReleaseError("Release is not published")
    return record


def sanitize_notes(body):
    # Match the mirror's URL/owner rewrite order, including bare owner mentions.
    substitutions = [
        (r"IBuySpy-Shared/basecoat-sheen\.git", "ivegamsft/sheen.git"),
        (r"IBuySpy-Shared/basecoat-sheen\.(?![A-Za-z0-9_-])", "ivegamsft/sheen."),
        (r"IBuySpy-Shared/basecoat-sheen(?![A-Za-z0-9_.-])", "ivegamsft/sheen"),
        (r"https://github\.com/IBuySpy-Shared/basecoat", "https://github.com/ivegamsft/sheen"),
        (r"IBuySpy-Shared/basecoat(?!-sheen)", "upstream-basecoat"),
        (r"IBuySpy-Shared/", "ivegamsft/"),
        (r"IBuySpy-Shared", "ivegamsft"),
        (r"ibuyspy-shared\.github\.io/basecoat-sheen", "ivegamsft.github.io/sheen"),
        (r"ibuyspy-shared\.github\.io/basecoat", "ivegamsft.github.io/sheen"),
        (r"ibuyspy-shared\.github\.io", "ivegamsft.github.io"),
    ]
    for pattern, replacement in substitutions:
        body = re.sub(pattern, replacement, body)
    if re.search(r"IBuySpy-Shared|ibuyspy-shared\.github\.io", body, re.IGNORECASE):
        raise ReleaseError("Internal identifiers remain in public release notes")
    return body


def get_release(repo, tag, token, source):
    for attempt in range(1, ATTEMPTS + 1):
        status, body, transient = request("GET", repo, f"releases/tags/{tag}", token)
        if status == 200 and not transient:
            return release_record(body, tag, published=source)
        if status == 404 and not source and not transient:
            return None
        if not transient and status not in RETRY_HTTP:
            raise ReleaseError(f"Release GET failed (HTTP {status})")
        if attempt == ATTEMPTS:
            raise ReleaseError(f"Release readiness exhausted after {ATTEMPTS} attempts (HTTP {status})")
        print(f"Release not ready (HTTP {status}); retry {attempt}/{ATTEMPTS}", flush=True)
        time.sleep(DELAY_SECONDS)
    raise ReleaseError("Release readiness did not complete")


def publish(tag, source_repo, source_token, public_token):
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", tag):
        raise ReleaseError("Tag must be vX.Y.Z")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9][A-Za-z0-9_.-]*", source_repo):
        raise ReleaseError("Invalid source repository")
    if not source_token or not public_token:
        raise ReleaseError("Both release tokens are required")
    source = get_release(source_repo, tag, source_token, source=True)
    notes = sanitize_notes(source["body"])
    existing = get_release(PUBLIC_REPO, tag, public_token, source=False)
    payload = {
        "tag_name": tag, "name": tag, "body": notes, "draft": False,
        "prerelease": source["prerelease"],
    }
    method = "PATCH" if existing else "POST"
    path = f"releases/{existing['id']}" if existing else "releases"
    status, body, transient = request(method, PUBLIC_REPO, path, public_token, payload)
    # Writes are deliberately not retried: a lost response can hide a successful POST.
    if transient or status != (200 if existing else 201):
        raise ReleaseError(f"Release {method} failed (HTTP {status}); inspect before rerunning")
    result = release_record(body, tag, published=True)
    if (result["body"] != notes or result["prerelease"] != source["prerelease"]
            or (existing and result["id"] != existing["id"])):
        raise ReleaseError("Public release write response does not match requested content/state")
    print(f"Verified public release {tag} ({method}, id {result['id']})")


if __name__ == "__main__":
    try:
        publish(os.environ.get("TAG", ""), os.environ.get("GITHUB_REPOSITORY", ""),
                os.environ.get("GITHUB_TOKEN", ""), os.environ.get("PRODUCTION_TOKEN", ""))
    except (ReleaseError, OSError) as error:
        print(f"::error::{error}", file=sys.stderr)
        sys.exit(1)
