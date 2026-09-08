#!/usr/bin/env python3
"""Execute workflow Bash and the real publication helper with offline transport fixtures."""
import importlib.util
import contextlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import unittest
from unittest.mock import patch
import uuid
import zipfile

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("publisher", ROOT / "scripts" / "publish-release.py")
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)
BASH = r"C:\Program Files\Git\bin\bash.exe" if os.name == "nt" else "bash"
TAG = "v1.2.3"
SOURCE = "IBuySpy-Shared/basecoat-sheen"


def remove_fixture(root):
    def writable_retry(function, path, error):
        if not isinstance(error[1], PermissionError):
            raise error[1]
        os.chmod(path, stat.S_IWRITE | stat.S_IREAD)
        function(path)
    shutil.rmtree(root, onerror=writable_retry)


def workflow_steps(name):
    # Deliberately limited to this repository's named step/run-block convention.
    text = (ROOT / ".github" / "workflows" / name).read_text(encoding="utf-8")
    steps = {}
    for block in re.split(r"(?m)^      - name: ", text)[1:]:
        title = block.splitlines()[0]
        match = re.search(r"(?m)^        run: \|\n((?:          .*\n|\n)*)", block + "\n")
        steps[title] = (block, "".join(line[10:] if line.startswith("          ") else line
                                     for line in match[1].splitlines(keepends=True)) if match else "")
    return steps


class ProvenanceTests(unittest.TestCase):
    def setUp(self):
        self.root = ROOT / "dist" / f"release-tests-{uuid.uuid4().hex}"
        self.root.mkdir(parents=True)
        self.addCleanup(remove_fixture, self.root)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.output = self.root / "outputs"
        self.capture = self.root / "capture"
        self.capture.mkdir()
        self.env = dict(os.environ, REQUESTED_TAG=TAG, GITHUB_REPOSITORY=SOURCE,
                        GITHUB_OUTPUT=self.output.as_posix(), CAPTURE_DIR=self.capture.as_posix())
        self.steps = workflow_steps("release.yml")
        self.git("init", "--quiet", "-b", "dispatch")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "core.autocrlf", "false")
        self.write_payload("BASE", "1.2.2")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "BASE-HISTORY")
        self.git("tag", "v1.2.2")
        self.write_payload("TAG", "1.2.3")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "TAG-HISTORY")
        self.git("tag", TAG)
        self.tag_sha = self.git("rev-parse", "HEAD").strip()
        self.write_payload("DISPATCH", "9.9.9")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "DISPATCH-HISTORY")
        self.dispatch_sha = self.git("rev-parse", "HEAD").strip()
        self.env["GITHUB_SHA"] = self.dispatch_sha
        tools = self.root / "bin"
        tools.mkdir()
        (tools / "gh").write_text(
            '#!/usr/bin/env bash\nset -euo pipefail\n'
            'case "$1 $2" in\n'
            '  "pr list") echo "[]" ;;\n'
            '  "release view") if [[ "$*" == *"--json"* ]]; then printf "sync.ps1\\nsync.sh\\n"; '
            'else [[ "${EXISTING_RELEASE:-no}" == yes ]]; fi ;;\n'
            '  "release create"|"release upload") cp "$4" sync.ps1 sync.sh "$CAPTURE_DIR"; '
            'printf "%s\\n" "$@" > "$CAPTURE_DIR/args" ;;\n'
            '  "release edit") : ;;\n'
            '  *) echo "Unexpected gh call" >&2; exit 90 ;;\n'
            'esac\n'
            'if [[ "$1 $2" == "release create" || "$1 $2" == "release edit" ]]; then '
            'cp release-notes.md "$CAPTURE_DIR"; fi\n', encoding="utf-8", newline="\n",
        )
        (tools / "gh").chmod(0o755)
        self.env["PATH"] = str(tools) + os.pathsep + self.env["PATH"]

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.repo), *args], text=True,
                              capture_output=True, check=True).stdout

    def write_payload(self, marker, version):
        (self.repo / "scripts").mkdir(exist_ok=True)
        generator = (ROOT / "scripts" / "generate-release-notes.sh").read_text(encoding="utf-8")
        (self.repo / "scripts" / "generate-release-notes.sh").write_text(
            generator + f'\nprintf "\\n{marker}-GENERATOR\\n" >> "$notes_file"\n', encoding="utf-8", newline="\n")
        (self.repo / "version.json").write_text(json.dumps({"version": version}), encoding="utf-8")
        (self.repo / "CHANGELOG.md").write_text(
            f"## [{version}]\n\n{marker}-CHANGELOG\n", encoding="utf-8", newline="\n")
        for name in ("sync.ps1", "sync.sh", "rollback.ps1", "rollback.sh"):
            (self.repo / name).write_text(f"{marker}-{name}\n", encoding="utf-8", newline="\n")

    def run_step(self, title, expected=0, override=None):
        body = self.steps[title][1] if override is None else override
        outputs = dict(line.split("=", 1) for line in self.output.read_text().splitlines()) \
            if self.output.exists() else {}
        values = {f"steps.{step}.outputs.{key}": outputs[key]
                  for step, key in (("tag", "tag"), ("tag", "version"),
                                    ("package", "artifact"), ("notes", "notes")) if key in outputs}
        body = re.sub(r"\$\{\{\s*(.*?)\s*\}\}", lambda m: values[m[1]], body)
        result = subprocess.run([BASH, "-c", body], cwd=self.repo, env=self.env,
                                text=True, capture_output=True, timeout=30)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def payload_steps(self):
        for title in ("Validate version.json matches tag", "Validate sync scripts present",
                      "Wave/sprint label coverage gate", "Build repository zip artifact",
                      "Generate release notes", "Create or update GitHub release"):
            self.run_step(title)

    def assert_tag_payload(self):
        outputs = dict(line.split("=", 1) for line in self.output.read_text().splitlines())
        self.assertEqual(outputs["tag"], TAG)
        self.assertEqual(outputs["version"], "1.2.3")
        self.assertEqual(self.git("rev-parse", "HEAD").strip(), self.tag_sha)
        self.assertEqual(json.loads((self.repo / "version.json").read_text())["version"], "1.2.3")
        for name in ("sync.ps1", "sync.sh"):
            self.assertEqual((self.capture / name).read_bytes(), f"TAG-{name}\n".encode())
        notes = (self.capture / "release-notes.md").read_text()
        self.assertIn("TAG-CHANGELOG", notes)
        self.assertIn("TAG-GENERATOR", notes)
        self.assertNotIn("DISPATCH", notes)
        self.assertIn(TAG, (self.capture / "args").read_text().splitlines())
        with zipfile.ZipFile(self.capture / f"basecoat-sheen-{TAG}.zip") as archive:
            for name in ("sync.ps1", "sync.sh", "rollback.ps1", "rollback.sh"):
                self.assertEqual(archive.read(name), f"TAG-{name}\n".encode())
            self.assertIn(b"TAG-CHANGELOG", archive.read("CHANGELOG.md"))
            self.assertIn(b"TAG-GENERATOR", archive.read("scripts/generate-release-notes.sh"))
            self.assertEqual(json.loads(archive.read("version.json"))["version"], "1.2.3")

    def test_dispatch_selects_tag_for_all_payloads_and_rerun_updates(self):
        self.assertNotEqual(self.dispatch_sha, self.tag_sha)
        self.assertFalse((self.repo / "scripts" / "publish-release.py").exists())
        self.run_step("Resolve and check out release tag")
        self.payload_steps()
        self.assert_tag_payload()
        self.env["EXISTING_RELEASE"] = "yes"
        self.run_step("Resolve and check out release tag")
        self.payload_steps()
        self.assert_tag_payload()
        self.assertEqual((self.capture / "args").read_text().splitlines()[1], "upload")

    def test_push_tag_checkout(self):
        self.git("checkout", "--quiet", "--detach", f"refs/tags/{TAG}")
        self.env["GITHUB_SHA"] = self.tag_sha
        self.run_step("Resolve and check out release tag")
        self.payload_steps()
        self.assert_tag_payload()

    def test_exact_tag_not_same_named_branch(self):
        self.git("tag", "-d", TAG)
        self.git("branch", TAG)
        self.run_step("Resolve and check out release tag", expected=1)
        self.assertFalse(self.output.exists())

    def test_public_resolver_explicit_push_and_latest_valid_tag(self):
        body = workflow_steps("publish-to-production.yml")["Resolve publish tag"][1]
        self.git("tag", "v99.0.0-rc.1")
        self.git("tag", "v98.0.0suffix")
        for event, requested, ref in (("workflow_dispatch", TAG, "dispatch"),
                                      ("push", "$(touch INJECTED)", TAG),
                                      ("workflow_dispatch", "", "dispatch")):
            with self.subTest(event=event, requested=requested):
                self.env.update(GITHUB_EVENT_NAME=event, REQUESTED_TAG=requested, GITHUB_REF_NAME=ref)
                self.run_step("", override=body)
                outputs = dict(line.split("=", 1) for line in self.output.read_text().splitlines())
                self.assertEqual(outputs, {"tag": TAG, "version": "1.2.3"})
                self.assertFalse((self.repo / "INJECTED").exists())
                self.assertEqual(self.git("rev-parse", "HEAD").strip(), self.dispatch_sha)
                self.output.unlink()

    def test_public_resolver_rejects_invalid_and_missing_tags_before_outputs(self):
        body = workflow_steps("publish-to-production.yml")["Resolve publish tag"][1]
        self.git("branch", "v9.8.7")
        for tag in ("v9.8.7", "1.2.3", "v1.2.3-rc.1", "--help", "refs/tags/v1.2.3",
                    "v1.2.3\ninjected=1", '$(touch INJECTED)',
                    'v1.2.3"; touch INJECTED; #', "v1.2.3`touch INJECTED`"):
            for event in ("workflow_dispatch", "push"):
                with self.subTest(tag=tag, event=event):
                    self.env.update(GITHUB_EVENT_NAME=event, REQUESTED_TAG=tag, GITHUB_REF_NAME=tag)
                    self.run_step("", expected=1, override=body)
                    self.assertFalse(self.output.exists())
                    self.assertFalse((self.repo / "INJECTED").exists())
                    self.assertEqual(self.git("rev-parse", "HEAD").strip(), self.dispatch_sha)

    def test_public_latest_requires_a_valid_tag(self):
        body = workflow_steps("publish-to-production.yml")["Resolve publish tag"][1]
        self.git("tag", "-d", TAG, "v1.2.2")
        self.env.update(GITHUB_EVENT_NAME="workflow_dispatch", REQUESTED_TAG="", GITHUB_REF_NAME="dispatch")
        for invalid_tag in (None, "v99.0.0-rc.1"):
            if invalid_tag:
                self.git("tag", invalid_tag)
            self.run_step("", expected=1, override=body)
            self.assertFalse(self.output.exists())

    def test_bad_and_missing_refs_never_execute_or_output(self):
        for tag in ("v9.8.7", "1.2.3", "v1.2", "v1.2.3-rc.1", "--help",
                    "refs/tags/v1.2.3", "v1.2.3\ninjected=1", '$(touch INJECTED)',
                    'v1.2.3"; touch INJECTED; #', "v1.2.3`touch INJECTED`"):
            with self.subTest(tag=tag):
                self.env["REQUESTED_TAG"] = tag
                self.run_step("Resolve and check out release tag", expected=1)
                self.assertFalse(self.output.exists())
                self.assertFalse((self.repo / "INJECTED").exists())
                self.assertEqual(self.git("rev-parse", "HEAD").strip(), self.dispatch_sha)

    def test_mismatched_and_duplicate_version_fail(self):
        for contents in ('{"version":"8.8.8"}', '{\n"version":"1.2.3",\n"version":"1.2.3"\n}'):
            with self.subTest(contents=contents):
                self.git("checkout", "--quiet", "dispatch")
                (self.repo / "version.json").write_text(contents, encoding="utf-8")
                self.git("add", ".")
                self.git("commit", "--quiet", "-m", "bad version")
                self.git("tag", "-f", TAG)
                self.run_step("Resolve and check out release tag")
                self.run_step("Validate version.json matches tag", expected=1)
                self.assertEqual(list(self.capture.iterdir()), [])

    def test_old_dispatch_wiring_reproduces_original_mixed_payload(self):
        body = self.steps["Resolve and check out release tag"][1].replace(
            'git checkout --detach "refs/tags/$tag"', ": # original did not check out the tag")
        self.run_step("Resolve and check out release tag", override=body)
        self.run_step("Validate version.json matches tag", expected=1)
        (self.repo / "version.json").write_text('{"version":"1.2.3"}', encoding="utf-8")
        self.payload_steps()
        self.assertIn("DISPATCH", (self.capture / "sync.sh").read_text())
        self.assertIn("DISPATCH", (self.capture / "release-notes.md").read_text())
        with zipfile.ZipFile(self.capture / f"basecoat-sheen-{TAG}.zip") as archive:
            self.assertIn(b"TAG-sync.sh", archive.read("sync.sh"))

    def test_history_fallback_uses_tag_not_dispatch_sha(self):
        self.git("checkout", "--quiet", "--detach", f"refs/tags/{TAG}")
        (self.repo / "CHANGELOG.md").write_text("", encoding="utf-8")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "TAG-FALLBACK")
        self.git("tag", "-f", TAG)
        self.git("checkout", "--quiet", "dispatch")
        self.run_step("Resolve and check out release tag")
        self.payload_steps()
        notes = (self.capture / "release-notes.md").read_text()
        self.assertIn("TAG-FALLBACK", notes)
        self.assertIn("TAG-HISTORY", notes)
        self.assertNotIn("DISPATCH", notes)

    def test_older_tag_fallback_ignores_later_and_nonancestor_tags(self):
        self.git("tag", "v1.2.4")
        self.git("tag", "v99.0.0-rc.1")
        self.git("tag", "v1.2.1", "refs/tags/v1.2.2")
        self.git("tag", "-f", "v1.2.2", self.dispatch_sha)
        self.git("checkout", "--quiet", "--detach", f"refs/tags/{TAG}")
        (self.repo / "CHANGELOG.md").write_text("", encoding="utf-8")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "OLDER-TAG-FALLBACK")
        self.git("tag", "-f", TAG)
        self.git("checkout", "--quiet", "dispatch")
        self.run_step("Resolve and check out release tag")
        self.payload_steps()
        notes = (self.capture / "release-notes.md").read_text()
        self.assertIn("since v1.2.1", notes)
        self.assertIn("OLDER-TAG-FALLBACK", notes)
        self.assertIn("TAG-HISTORY", notes)
        self.assertNotIn("DISPATCH", notes)
        self.assertNotIn("No commits found", notes)
        self.assertEqual(self.git("tag", "--list").splitlines(), ["v1.2.1", TAG])

    def test_first_release_fallback_with_later_tags_uses_initial_history(self):
        self.git("tag", "v1.2.4")
        self.git("tag", "-d", "v1.2.2")
        self.git("checkout", "--quiet", "--detach", f"refs/tags/{TAG}")
        (self.repo / "CHANGELOG.md").write_text("", encoding="utf-8")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "FIRST-RELEASE-FALLBACK")
        self.git("tag", "-f", TAG)
        self.git("checkout", "--quiet", "dispatch")
        self.run_step("Resolve and check out release tag")
        self.payload_steps()
        notes = (self.capture / "release-notes.md").read_text()
        self.assertIn("since the initial commit", notes)
        self.assertIn("BASE-HISTORY", notes)
        self.assertIn("TAG-HISTORY", notes)
        self.assertNotIn("DISPATCH", notes)
        self.assertNotIn("No commits found", notes)
        self.assertEqual(self.git("tag", "--list").splitlines(), [TAG])

    def test_retained_helper_executes_after_old_tag_checkout_and_fails_closed(self):
        steps = workflow_steps("publish-to-production.yml")
        shutil.copyfile(ROOT / "scripts" / "publish-release.py", self.repo / "scripts" / "publish-release.py")
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "Dispatch-only helper")
        retained = self.root / "retained"
        retained.mkdir()
        self.env.update(RUNNER_TEMP=retained.as_posix(), TAG=TAG, GITHUB_TOKEN="fixture-source",
                        PRODUCTION_TOKEN="fixture-public", MOCK_CURL_COUNT=(self.root / "curl-count").as_posix())
        self.run_step("", override=steps["Retain source release completion helper"][1])
        self.run_step("Resolve and check out release tag")
        self.assertFalse((self.repo / "scripts" / "publish-release.py").exists())
        self.assertTrue((retained / "sheen-publish-release.py").is_file())
        tools = self.root / "bin"
        bootstrap = self.root / "offline-python.py"
        bootstrap.write_text(
            "import json, os, runpy, subprocess, sys\n"
            "from pathlib import Path\n"
            "from unittest.mock import patch\n"
            "def transport(command, **kwargs):\n"
            "    path = Path(os.environ['MOCK_CURL_COUNT'])\n"
            "    count = int(path.read_text()) + 1 if path.exists() else 1\n"
            "    path.write_text(str(count))\n"
            f"    body = {record()!r}\n"
            "    if count == 1: status = os.environ.get('MOCK_SOURCE_STATUS', '200')\n"
            "    elif count == 2: status, body = '404', {}\n"
            "    elif count == 3:\n"
            "        status = '201'\n"
            "        (Path(os.environ['CAPTURE_DIR']) / 'public-payload').write_text(kwargs['input'])\n"
            "    else: raise AssertionError('Unexpected transport call')\n"
            "    return subprocess.CompletedProcess(command, 0, json.dumps(body) + '\\n' + status, '')\n"
            "with patch('subprocess.run', side_effect=transport):\n"
            "    runpy.run_path(sys.argv[1], run_name='__main__')\n", encoding="utf-8", newline="\n")
        (tools / "python3").write_text(
            f'#!/usr/bin/env bash\nexec "{Path(sys.executable).as_posix()}" "{bootstrap.as_posix()}" "$@"\n',
            encoding="utf-8", newline="\n")
        (tools / "python3").chmod(0o755)
        result = self.run_step("", override=steps["Create GitHub release on production repository"][1])
        self.assertIn("Verified public release", result.stdout)
        self.assertEqual(json.loads((self.capture / "public-payload").read_text())["tag_name"], TAG)
        (self.root / "curl-count").unlink()
        (self.capture / "public-payload").unlink()
        self.env["MOCK_SOURCE_STATUS"] = "401"
        result = self.run_step("", expected=1,
                               override=steps["Create GitHub release on production repository"][1])
        self.assertIn("::error::", result.stderr)
        self.assertNotIn("Verified public release", result.stdout)
        self.assertEqual((self.root / "curl-count").read_text().strip(), "1")
        self.assertFalse((self.capture / "public-payload").exists())
        self.run_step("", override=steps["Remove retained release completion helper"][1])
        self.assertFalse((retained / "sheen-publish-release.py").exists())

    def test_actual_strip_removes_internal_helpers_and_preserves_public_assets(self):
        steps = workflow_steps("publish-to-production.yml")
        internal = ("publish-release.py", "test-release-reliability.py",
                    "test-release-reliability.ps1", "build-metadata.ps1",
                    "test-downstream-token-hygiene.ps1", "test-downstream-token-hygiene.py")
        for name in internal:
            shutil.copyfile(ROOT / "scripts" / name, self.repo / "scripts" / name)
        workflows = self.repo / ".github" / "workflows"
        workflows.mkdir(parents=True)
        for name in ("release.yml", "publish-to-production.yml", "docs.yml"):
            shutil.copyfile(ROOT / ".github" / "workflows" / name, workflows / name)
        self.git("add", ".")
        self.git("commit", "--quiet", "-m", "Current-tag internal tooling")
        retained = self.root / "retained"
        retained.mkdir()
        self.env.update(RUNNER_TEMP=retained.as_posix(), TAG=TAG)
        self.run_step("", override=steps["Retain source release completion helper"][1])
        self.run_step("", override=steps["Remove internal-only content before publish"][1])
        tracked = self.git("ls-files").splitlines()
        for name in internal:
            self.assertFalse((self.repo / "scripts" / name).exists())
            self.assertNotIn(f"scripts/{name}", tracked)
        for name in ("sheen-build-metadata.ps1", "sheen-publish-release.py"):
            self.assertTrue((retained / name).is_file())
            self.assertNotIn(name, tracked)
        self.assertEqual(sorted(path.name for path in workflows.iterdir()), ["docs.yml"])
        for name in ("sync.ps1", "sync.sh", "rollback.ps1", "rollback.sh"):
            self.assertTrue((self.repo / name).is_file())
            self.assertIn(name, tracked)
        self.run_step("", override=steps["Remove retained release completion helper"][1])
        self.assertFalse((retained / "sheen-publish-release.py").exists())


def record(**changes):
    result = dict(id=42, tag_name=TAG, body="Source notes\n", draft=False,
                  prerelease=False, published_at="2026-09-07T00:00:00Z")
    result.update(changes)
    return result


def response(status=200, body=None, code=0):
    if body is None:
        body = record()
    return subprocess.CompletedProcess([], code, (json.dumps(body) if not isinstance(body, str)
                                                  else body) + f"\n{status}", "")


class CompletionTests(unittest.TestCase):
    def exercise(self, responses, error=None):
        output = io.StringIO()
        with patch.object(publisher.subprocess, "run", side_effect=responses) as transport, \
                patch.object(publisher.time, "sleep") as sleep, contextlib.redirect_stdout(output):
            if error:
                with self.assertRaisesRegex(publisher.ReleaseError, error):
                    publisher.publish(TAG, SOURCE, "source-fixture-token", "public-fixture-token")
            else:
                publisher.publish(TAG, SOURCE, "source-fixture-token", "public-fixture-token")
            if error:
                self.assertNotIn("Verified public release", output.getvalue())
            else:
                self.assertIn("Verified public release", output.getvalue())
            for call in transport.call_args_list:
                command = call.args[0]
                self.assertIn("--max-time", command)
                self.assertEqual(command[command.index("--max-time") + 1], "20")
                self.assertEqual(command[command.index("--connect-timeout") + 1], "10")
                self.assertEqual(call.kwargs["timeout"], 25)
                self.assertTrue(call.kwargs["capture_output"])
                self.assertNotIn("--retry", command)
            return transport.call_args_list, sleep.call_count

    def test_immediate_create_and_existing_update(self):
        for existing in (False, True):
            with self.subTest(existing=existing):
                calls, sleeps = self.exercise([
                    response(), response() if existing else response(404, {}),
                    response(200 if existing else 201),
                ])
                self.assertEqual(sleeps, 0)
                self.assertEqual(len(calls), 3)
                self.assertIn(f"{publisher.API}/{SOURCE}/releases/tags/{TAG}", calls[0].args[0])
                self.assertIn(f"{publisher.API}/{publisher.PUBLIC_REPO}/releases/tags/{TAG}", calls[1].args[0])
                command = calls[2].args[0]
                self.assertIn("PATCH" if existing else "POST", command)
                self.assertIn(f"{publisher.API}/{publisher.PUBLIC_REPO}/releases" +
                              ("/42" if existing else ""), command)
                self.assertEqual(json.loads(calls[2].kwargs["input"])["body"], "Source notes\n")
                self.assertIn("Authorization: token source-fixture-token", calls[0].args[0])
                self.assertIn("Authorization: token public-fixture-token", calls[2].args[0])

    def test_delayed_source_and_public_transient_then_create(self):
        calls, sleeps = self.exercise([
            response(404, {}), response(503, {}), response(429, {}), response(),
            response(502, {}), response(404, {}), response(201),
        ])
        self.assertEqual(sleeps, 4)
        self.assertEqual(len(calls), 7)
        self.assertIn("POST", calls[-1].args[0])
        self.assertTrue(all("GET" in call.args[0] for call in calls[:-1]))

    def test_source_exhaustion_never_writes(self):
        for status in (404, 408, 429, 500, 502, 503, 504):
            with self.subTest(status=status):
                calls, sleeps = self.exercise([response(status, {})] * publisher.ATTEMPTS, "exhausted")
                self.assertEqual(len(calls), publisher.ATTEMPTS)
                self.assertEqual(sleeps, publisher.ATTEMPTS - 1)
                self.assertTrue(all("GET" in call.args[0] for call in calls))

    def test_public_transient_exhaustion_is_not_absence(self):
        calls, sleeps = self.exercise([response()] + [response(503, {})] * publisher.ATTEMPTS, "exhausted")
        self.assertEqual(len(calls), publisher.ATTEMPTS + 1)
        self.assertEqual(sleeps, publisher.ATTEMPTS - 1)
        self.assertTrue(all("GET" in call.args[0] for call in calls))

    def test_permanent_source_and_public_errors_fail_immediately(self):
        for status in (301, 400, 401, 403, 405, 410, 422):
            for public in (False, True):
                with self.subTest(status=status, public=public):
                    calls, sleeps = self.exercise(([response()] if public else []) +
                                                 [response(status, {})], f"HTTP {status}")
                    self.assertEqual(sleeps, 0)
                    self.assertEqual(len(calls), 2 if public else 1)

    def test_invalid_source_is_not_ready_or_retried(self):
        invalid = ["null", "{", "[]", record(tag_name="v9.9.9"), record(draft=True),
                   record(body=None), record(body=" \n"), record(body={}), record(id=True),
                   record(id=-1), record(prerelease="false"), record(published_at=None)]
        for body in invalid:
            with self.subTest(body=body):
                calls, sleeps = self.exercise([response(body=body)], "Release")
                self.assertEqual(len(calls), 1)
                self.assertEqual(sleeps, 0)

    def test_invalid_public_lookup_never_creates(self):
        for body in ("null", "{", record(tag_name="v0.0.1"), record(id="42"), record(draft=None)):
            with self.subTest(body=body):
                calls, _ = self.exercise([response(), response(body=body)], "Release")
                self.assertEqual(len(calls), 2)

    def test_existing_empty_draft_can_be_repaired(self):
        calls, _ = self.exercise([response(), response(body=record(body=None, draft=True)),
                                 response()])
        self.assertIn("PATCH", calls[-1].args[0])
        self.assertFalse(json.loads(calls[-1].kwargs["input"])["draft"])

    def test_write_failure_and_invalid_response_fail_without_retry(self):
        invalid_writes = [response(401, {}), response(403, {}), response(422, {}),
                          response(500, {}), response(200, {}),
                          response(201, "{"), response(201, record(tag_name="v9.9.9")),
                          response(201, record(draft=True)), response(201, record(body="wrong")),
                          response(201, record(prerelease=True)), response(201, record(published_at=None)),
                          response(201, record(body="")), response(0, {}, code=28)]
        for write in invalid_writes:
            with self.subTest(write=write.stdout):
                calls, sleeps = self.exercise([response(), response(404, {}), write], "Release|Public")
                self.assertEqual(len(calls), 3)
                self.assertEqual(sleeps, 0)
        for write in (response(500, {}), response(body=record(id=43)), response(201)):
            calls, _ = self.exercise([response(), response(), write], "Release|Public")
            self.assertEqual(len(calls), 3)
            self.assertIn("PATCH", calls[-1].args[0])

    def test_transport_retry_and_permanent_failure(self):
        for code in sorted(publisher.RETRY_CURL):
            calls, sleeps = self.exercise([response(0, {}, code), response(),
                                         response(404, {}), response(201)])
            self.assertEqual(sleeps, 1)
            self.assertEqual(len(calls), 4)
        calls, sleeps = self.exercise([subprocess.TimeoutExpired("curl", 25), response(),
                                     response(404, {}), response(201)])
        self.assertEqual(sleeps, 1)
        for code in (2, 3, 35, 60):
            calls, sleeps = self.exercise([response(0, {}, code)], "transport failed")
            self.assertEqual(sleeps, 0)
            self.assertEqual(len(calls), 1)
        calls, sleeps = self.exercise([subprocess.TimeoutExpired("curl", 25)] * publisher.ATTEMPTS,
                                     "exhausted")
        self.assertEqual(len(calls), publisher.ATTEMPTS)
        self.assertEqual(sleeps, publisher.ATTEMPTS - 1)

    def test_bad_status_and_configuration_never_succeed(self):
        for stdout in ("", "garbage", "{}\n000", "{}\n200garbage"):
            self.exercise([subprocess.CompletedProcess([], 0, stdout, "")], "invalid HTTP status")
        with patch.object(publisher.subprocess, "run") as transport:
            for args in (("$(touch bad)", SOURCE, "s", "p"), (TAG, "../bad", "s", "p"),
                         (TAG, SOURCE, "", "p"), (TAG, SOURCE, "s", "")):
                with self.assertRaises(publisher.ReleaseError):
                    publisher.publish(*args)
            transport.assert_not_called()

    def test_notes_are_sanitized_before_writes_and_response_checked(self):
        notes = (
            'Notes "quoted" ☃\nhttps://github.com/IBuySpy-Shared/basecoat-sheen.git\n'
            'IBuySpy-Shared/basecoat-sheen. IBuySpy-Shared/basecoat\n'
            'https://github.com/IBuySpy-Shared/basecoat\n'
            'https://raw.githubusercontent.com/IBuySpy-Shared/basecoat-sheen/main/a\n'
            'https://ibuyspy-shared.github.io/basecoat-sheen/\n'
            'https://ibuyspy-shared.github.io/basecoat/ IBuySpy-Shared\n'
        )
        expected = (
            'Notes "quoted" ☃\nhttps://github.com/ivegamsft/sheen.git\n'
            'ivegamsft/sheen. upstream-basecoat\n'
            'https://github.com/ivegamsft/sheen\n'
            'https://raw.githubusercontent.com/ivegamsft/sheen/main/a\n'
            'https://ivegamsft.github.io/sheen/\n'
            'https://ivegamsft.github.io/sheen/ ivegamsft\n'
        )
        calls, _ = self.exercise([response(body=record(body=notes, prerelease=True)), response(404, {}),
                                 response(201, record(body=expected, prerelease=True))])
        payload = json.loads(calls[-1].kwargs["input"])
        self.assertEqual(payload["body"], expected)
        self.assertEqual(payload["tag_name"], TAG)
        self.assertTrue(payload["prerelease"])
        self.assertNotIn("IBuySpy-Shared", calls[-1].kwargs["input"])
        calls, _ = self.exercise([response(body=record(body="IBUYSPY-SHARED/private"))], "Internal identifiers")
        self.assertEqual(len(calls), 1)

    def test_worst_case_budget_fits_workflow_step(self):
        per_lookup = publisher.ATTEMPTS * (publisher.REQUEST_SECONDS + 5) + \
            (publisher.ATTEMPTS - 1) * publisher.DELAY_SECONDS
        self.assertEqual(2 * per_lookup + publisher.REQUEST_SECONDS + 5, 565)
        self.assertLess(565, 10 * 60)


class WiringTests(unittest.TestCase):
    def test_source_order_and_dispatch_env(self):
        steps = workflow_steps("release.yml")
        names = list(steps)
        resolve = "Resolve and check out release tag"
        self.assertIn("REQUESTED_TAG: ${{ inputs.tag || github.ref_name }}", steps[resolve][0])
        self.assertNotIn("${{", steps[resolve][1])
        self.assertIn("fetch-depth: 0", steps["Check out repository"][0])
        for name in ("Validate version.json matches tag", "Validate sync scripts present",
                     "Build repository zip artifact", "Generate release notes",
                     "Create or update GitHub release"):
            self.assertLess(names.index(resolve), names.index(name))
        self.assertEqual(sum("uses: actions/checkout@" in block for block, _ in steps.values()), 1)

    def test_public_helper_retention_strip_cleanup_and_ci(self):
        steps = workflow_steps("publish-to-production.yml")
        names = list(steps)
        resolve = "Resolve publish tag"
        retain = "Retain source release completion helper"
        checkout = "Check out repository at tag"
        strip = "Remove internal-only content before publish"
        publish = "Create GitHub release on production repository"
        cleanup = "Remove retained release completion helper"
        self.assertLess(names.index(retain), names.index(checkout))
        self.assertLess(names.index(resolve), names.index(checkout))
        self.assertIn("REQUESTED_TAG: ${{ inputs.tag }}", steps[resolve][0])
        self.assertNotIn("${{", steps[resolve][1])
        self.assertLess(names.index("Fetch repository for tag resolution"), names.index(retain))
        self.assertIn("ref: refs/tags/${{ steps.resolve_tag.outputs.tag }}", steps[checkout][0])
        self.assertLess(names.index(checkout), names.index(strip))
        self.assertLess(names.index(strip), names.index(publish))
        self.assertLess(names.index(publish), names.index(cleanup))
        self.assertIn('cp scripts/publish-release.py "${RUNNER_TEMP}/sheen-publish-release.py"',
                      steps[retain][1])
        self.assertIn('python3 "${RUNNER_TEMP}/sheen-publish-release.py"', steps[publish][1])
        self.assertIn("timeout-minutes: 10", steps[publish][0])
        self.assertIn("TAG: ${{ steps.resolve_tag.outputs.tag }}", steps[publish][0])
        self.assertIn("GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}", steps[publish][0])
        self.assertIn("PRODUCTION_TOKEN: ${{ secrets.PRODUCTION_REPO_TOKEN }}", steps[publish][0])
        self.assertNotIn("||", steps[publish][1])
        self.assertIn("if: always()", steps[cleanup][0])
        self.assertIn('rm -f -- "${RUNNER_TEMP}/sheen-publish-release.py"', steps[cleanup][0])
        for path in ("scripts/publish-release.py", "scripts/test-release-reliability.py",
                     "scripts/test-release-reliability.ps1"):
            self.assertIn(f"'{path}'", steps[strip][1])
        sanitize = steps["Sanitize internal identifiers for production"][1]
        self.assertLess(sanitize.index("perl -pi"), sanitize.index("pwsh -NoProfile"))
        self.assertLess(sanitize.index(" -Check"), sanitize.index("FORBIDDEN_MATCHES="))
        self.assertIn("scripts/test-release-reliability.ps1",
                      (ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
