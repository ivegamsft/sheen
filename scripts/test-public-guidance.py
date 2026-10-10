#!/usr/bin/env python3
"""Exercise source preparation and the publisher's actual identifier rewrite."""

import importlib.util
import os
from pathlib import Path
import re
import shutil
import stat
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


def remove_readonly(function, path, _error):
    os.chmod(path, stat.S_IWRITE)
    function(path)


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


def run_callable_source_regression(workflow, fixture, bash):
    def step_script(name):
        match = re.search(
            rf"(?ms)^      - name: {re.escape(name)}.*?^        run: \|\r?\n"
            r"(.*?)(?=^      - name: |\Z)",
            workflow,
        )
        assert match, f"Missing callable step {name}"
        return "\n".join(
            line[10:] if line.startswith("          ") else line
            for line in match[1].splitlines()
        ) + "\n"

    git = shutil.which("git")
    assert git, "Git is required for pinned-source collision proof"
    source = fixture / "callable-source"
    source.mkdir()
    subprocess.run([git, "init", "-b", "main", str(source)], check=True, capture_output=True)
    subprocess.run([git, "-C", str(source), "config", "user.name", "Sheen test"], check=True)
    subprocess.run([git, "-C", str(source), "config", "user.email", "sheen-test@example.com"], check=True)
    (source / "sync.sh").write_text(
        "#!/usr/bin/env bash\n"
        "# sync.sh --- basecoat-sheen consumer sync (POSIX shell)\n"
        "set -euo pipefail\n"
        "printf '%s\\n%s\\n' \"$SHEEN_REF\" "
        "\"$(git -C \"$SHEEN_SOURCE_PATH\" rev-parse HEAD)\" "
        "> \"$GITHUB_WORKSPACE/sheen-script-source.txt\"\n",
        encoding="utf-8",
        newline="\n",
    )
    subprocess.run([git, "-C", str(source), "add", "sync.sh"], check=True)
    subprocess.run([git, "-C", str(source), "commit", "-m", "Sheen source payload"], check=True, capture_output=True)
    source_commit = subprocess.run(
        [git, "-C", str(source), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()

    stage_script = fixture / "stage-pinned-source.sh"
    run_script = fixture / "run-pinned-source.sh"
    stage_script.write_text(
        step_script("Stage sync engine from the resolved Sheen source revision"),
        encoding="utf-8",
        newline="\n",
    )
    run_script.write_text(step_script("Run sheen sync"), encoding="utf-8", newline="\n")

    for case in ("mixed-basecoat-sheen", "sheen-only"):
        consumer = fixture / case
        consumer.mkdir()
        if case == "mixed-basecoat-sheen":
            (consumer / ".basecoat.yml").write_text("source: https://example.invalid/basecoat.git\n", encoding="utf-8")
            root_sync = (
                "#!/usr/bin/env bash\n"
                "touch \"$GITHUB_WORKSPACE/basecoat-sync-was-run\"\n"
            ).encode()
            (consumer / "sync.sh").write_bytes(root_sync)
        else:
            root_sync = None
        (consumer / ".sheen.yml").write_text(
            f"source: {source.as_posix()}\nref: main\n",
            encoding="utf-8",
        )
        output = fixture / f"{case}-github-output.txt"
        output.unlink(missing_ok=True)
        runner_temp = fixture / f"{case}-runner"
        runner_temp.mkdir()
        env = dict(
            os.environ,
            GITHUB_WORKSPACE=consumer.as_posix(),
            GITHUB_OUTPUT=output.as_posix(),
            GITHUB_RUN_ID="304309",
            GITHUB_RUN_ATTEMPT="1",
            RUNNER_TEMP=runner_temp.as_posix(),
            SHEEN_REPO=source.as_posix(),
            SHEEN_REF="main",
            SHEEN_FETCH_TOKEN="",
        )
        if os.name == "nt":
            env["PATH"] = str(Path(bash).parent) + os.pathsep + env["PATH"]
        staged = subprocess.run(
            [bash, stage_script.as_posix()],
            cwd=consumer,
            env=env,
            text=True,
            capture_output=True,
        )
        assert staged.returncode == 0, staged.stdout + staged.stderr
        outputs = dict(line.split("=", 1) for line in output.read_text(encoding="utf-8").splitlines())
        assert outputs["source_commit"] == source_commit, outputs
        env["SHEEN_SOURCE_PATH"] = outputs["source_path"]
        env["SHEEN_REF"] = outputs["source_commit"]
        synced = subprocess.run(
            [bash, run_script.as_posix()],
            cwd=consumer,
            env=env,
            text=True,
            capture_output=True,
        )
        assert synced.returncode == 0, synced.stdout + synced.stderr
        assert (consumer / "sheen-script-source.txt").read_text(encoding="utf-8").splitlines() == [
            source_commit,
            source_commit,
        ]
        assert not (consumer / "basecoat-sync-was-run").exists()
        if root_sync is not None:
            assert (consumer / "sync.sh").read_bytes() == root_sync, "Consumer BaseCoat sync.sh was modified"
            assert (consumer / ".basecoat.yml").read_text(encoding="utf-8") == (
                "source: https://example.invalid/basecoat.git\n"
            )
        assert not Path(outputs["source_path"]).exists(), "Staged source clone must be cleaned after sync"


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
        run_callable_source_regression(internal, fixture, bash)
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
        shutil.rmtree(fixture, onerror=remove_readonly)


if __name__ == "__main__":
    main()
