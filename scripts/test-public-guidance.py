#!/usr/bin/env python3
"""Exercise source preparation and the publisher's actual identifier rewrite."""

import importlib.util
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid


ROOT = Path(__file__).resolve().parent.parent
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location(
    "prepare", ROOT / "scripts" / "prepare-public-guidance.py"
)
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


def runtime(name):
    if os.name == "nt":
        git = Path(shutil.which("git")).resolve()
        candidate = git.parent.parent / "usr" / "bin" / f"{name}.exe"
        if candidate.is_file():
            return str(candidate)
    return shutil.which(name)


def check_resolver(workflow, root, bash, config, private=False):
    match = re.search(
        r"(?ms)^      - name: Resolve sync configuration.*?^        run: \|\r?\n"
        r"(.*?)(?=^      - name: )", workflow
    )
    assert match, "Missing resolver"
    body = "\n".join(line[10:] for line in match[1].splitlines())
    for name in ("source_repo", "source_ref", "pr_branch_prefix"):
        body = body.replace("${{ inputs." + name + " }}", "")
    if config is None:
        (root / ".sheen.yml").unlink(missing_ok=True)
    else:
        (root / ".sheen.yml").write_text(config, encoding="utf-8")
    script = root / "resolve.sh"
    script.write_text(body, encoding="utf-8", newline="\n")
    output = root / "github-output.txt"
    output.unlink(missing_ok=True)
    env = dict(os.environ, SHEEN_FETCH_TOKEN="", GITHUB_OUTPUT=output.as_posix())
    if os.name == "nt":
        env["PATH"] = str(Path(bash).parent) + os.pathsep + env["PATH"]
    result = subprocess.run(
        [bash, script.as_posix()], cwd=root, env=env, text=True, capture_output=True
    )
    if private:
        assert result.returncode != 0, "Internal source must still fail without token"
        assert "centrally managed organization SHEEN_FETCH_TOKEN" in result.stdout
        assert "Do not create a repository secret" in result.stdout
        return
    assert result.returncode == 0, result.stdout + result.stderr
    assert "Missing Sheen fetch token" not in result.stdout, result.stdout
    values = dict(line.split("=", 1) for line in output.read_text().splitlines())
    assert values["source_url"] == "https://github.com/ivegamsft/sheen.git", values
    assert values["ref"] == "main", values


def main():
    publisher = (ROOT / ".github/workflows/publish-to-production.yml").read_text()
    match = re.search(r"(?s)perl -pi -e '\n(.*?)\n\s*' -- \"\$f\"", publisher)
    assert match, "Test must execute the publisher's actual Perl rewrite"
    perl, bash = runtime("perl"), runtime("bash")
    assert perl and bash, "Perl and Bash are required for public resolver proof"
    fixture = ROOT / (".sheen-public-guidance-" + uuid.uuid4().hex)
    fixture.mkdir()
    try:
        for relative in prepare.FILES:
            target = fixture / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)
        subprocess.run(
            [sys.executable, str(ROOT / "scripts/prepare-public-guidance.py"),
             "--root", str(fixture)], check=True
        )
        for relative in prepare.FILES:
            target = fixture / relative
            subprocess.run([perl, "-pi", "-e", match[1], str(target)], check=True)
            text = target.read_text(encoding="utf-8")
            if relative != ".github/workflows/check-sheen-version-callable.yml":
                assert "SHEEN_FETCH_TOKEN" not in text, (relative, "public org secret requirement")
            for forbidden in (
                "sheen-internal-only:", "IBuySpy-Shared", "ibuyspy-shared",
                "centrally managed", "organization secret administrators",
                "inherit", "Contents: Read only", "Central ownership and rotation",
                "central-ownership-and-rotation", "which is private/internal to consumers",
            ):
                assert forbidden not in text, (relative, forbidden)
            assert "no fetch token" in text or "no\n# extra fetch credential" in text or (
                "need a fetch credential" in text and "do not" in text
            ), f"{relative}: missing public no-token guidance"
        public = (fixture / ".github/workflows/check-sheen-version-callable.yml").read_text()
        assert '== "ivegamsft/sheen" && -z' not in public
        template = (fixture / "templates/sheen-sync.yml").read_text()
        assert "fetch_token:" not in template, "Public template must not request org fetch secret"
        assert "uses: ivegamsft/sheen/" in template
        check_resolver(public, fixture, bash, None)
        check_resolver(public, fixture, bash, "")
        check_resolver(public, fixture, bash, "source: https://github.com/ivegamsft/sheen.git\nref: main\n")
        internal = (ROOT / ".github/workflows/check-sheen-version-callable.yml").read_text()
        check_resolver(internal, fixture, bash, "source: https://github.com/IBuySpy-Shared/basecoat-sheen.git\n", private=True)
        check_resolver(internal, fixture, bash, "source: https://GitHub.com/ibuyspy-shared/basecoat-sheen.Git\n", private=True)
        for malformed in (
            "# sheen-internal-only:start\n",
            "# sheen-internal-only:end\n",
            "# sheen-internal-only:start\n# sheen-internal-only:start\n",
        ):
            try:
                prepare.public_text(malformed)
            except ValueError:
                pass
            else:
                raise AssertionError("Malformed internal-only markers must fail closed")
        print("Public guidance semantics and actual sanitized anonymous resolver passed.")
    finally:
        shutil.rmtree(fixture)


if __name__ == "__main__":
    main()
