#!/usr/bin/env python3
"""Exercise both consumer entrypoints against real pinned Git fixtures."""
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASH = Path(r"C:\Program Files\Git\bin\bash.exe") if os.name == "nt" else shutil.which("bash")


def shell_path(path):
    value = str(path).replace("\\", "/")
    return "/" + value[0].lower() + value[2:] if os.name == "nt" else value


class DistributionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="sheen-channels-")
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        (self.source / "agents").mkdir(parents=True)
        (self.source / "templates").mkdir()
        self.definition = "---\nname: fixture\ndescription: Test\n---\nFixture.\n"
        (self.source / "agents" / "fixture.agent.md").write_text(self.definition, newline="\n")
        (self.source / "agents" / "fixture.agent.eval.yaml").write_text("eval: fixture\n", newline="\n")
        (self.source / "templates" / "sheen-sync.yml").write_text(
            "# This file was synced into your repo by basecoat-sheen.\n"
            "jobs:\n  check:\n    uses: IBuySpy-Shared/basecoat-sheen/.github/workflows/check-sheen-version-callable.yml@v1.0.0\n",
            newline="\n",
        )
        self.git(self.source, "init", "-b", "main")
        self.git(self.source, "config", "user.name", "test")
        self.git(self.source, "config", "user.email", "test@example.com")
        self.git(self.source, "add", "-A")
        self.git(self.source, "commit", "-m", "source")
        self.git(self.source, "tag", "v1.0.0")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, path, *args):
        return subprocess.check_output(["git", "-C", str(path), *args], stderr=subprocess.STDOUT)

    def consumer(self, runner, suffix=""):
        path = self.root / (runner + suffix)
        path.mkdir()
        self.git(path, "init", "-b", "main")
        self.git(path, "config", "user.name", "test")
        self.git(path, "config", "user.email", "test@example.com")
        return path

    def sync(self, path, runner, config="", fail=False):
        (path / ".sheen.yml").write_text(config, newline="\n")
        env = os.environ.copy()
        env["SHEEN_REPO"] = shell_path(self.source) if runner == "bash" else str(self.source)
        env["SHEEN_REF"] = "v1.0.0"
        env["SHEEN_SYNC_TEMP_ROOT"] = str(self.root / "staging")
        if runner == "bash":
            command = [str(BASH), shell_path(ROOT / "sync.sh")]
        else:
            command = ["pwsh", "-NoProfile", "-NonInteractive", "-File", str(ROOT / "sync.ps1")]
        result = subprocess.run(command, cwd=path, env=env, capture_output=True, text=True, timeout=90)
        if fail:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout + result.stderr

    def runners(self):
        self.assertIsNotNone(shutil.which("pwsh"), "PowerShell is required")
        self.assertTrue(BASH and Path(BASH).exists(), "Bash is required")
        return ["pwsh", "bash"]

    def test_default_org_and_workflow_absent_repeat_noop(self):
        for runner in self.runners():
            with self.subTest(runner=runner):
                path = self.consumer(runner)
                self.sync(path, runner)
                self.assertFalse((path / ".github" / "agents").exists())
                self.assertFalse((path / ".github" / "workflows" / "sheen-sync.yml").exists())
                manifest = path / ".sheen" / "manifest.json"
                self.assertEqual(json.loads(manifest.read_text(encoding="utf-8-sig"))["agent_distribution"], "organization")
                before = manifest.read_bytes()
                self.sync(path, runner)
                self.assertEqual(before, manifest.read_bytes())

    def test_repository_to_org_verified_cleanup_preserves_custom(self):
        for runner in self.runners():
            with self.subTest(runner=runner):
                path = self.consumer(runner)
                self.sync(path, runner, "agent_distribution: repository\n")
                agents = path / ".github" / "agents"
                self.assertTrue((agents / "fixture.agent.md").exists())
                manifest_path = path / ".sheen" / "manifest.json"
                legacy = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
                del legacy["agent_distribution"]
                manifest_path.write_text(json.dumps(legacy, indent=2) + "\n", newline="\n")
                (agents / "custom.agent.md").write_text("custom\n")
                self.git(path, "add", "-A")
                self.git(path, "commit", "-m", "installed")
                self.sync(path, runner)
                self.assertFalse((agents / "fixture.agent.md").exists())
                self.assertFalse((agents / "fixture.agent.eval.yaml").exists())
                self.assertEqual((agents / "custom.agent.md").read_text(), "custom\n")
                manifest = json.loads((path / ".sheen" / "manifest.json").read_text(encoding="utf-8-sig"))
                self.assertFalse(any(name.startswith(".github/agents/") for name in manifest["files"]))
                before = (path / ".sheen" / "manifest.json").read_bytes()
                self.sync(path, runner)
                self.assertEqual(before, (path / ".sheen" / "manifest.json").read_bytes())

    def test_modified_legacy_agent_blocks_before_any_removal(self):
        for runner in self.runners():
            with self.subTest(runner=runner):
                path = self.consumer(runner)
                self.sync(path, runner, "agent_distribution: repository\n")
                self.git(path, "add", "-A")
                self.git(path, "commit", "-m", "installed")
                agent = path / ".github" / "agents" / "fixture.agent.md"
                agent.write_text("custom edit\n")
                manifest = path / ".sheen" / "manifest.json"
                before = manifest.read_bytes()
                output = self.sync(path, runner, fail=True)
                self.assertIn("Locally modified or unverifiable managed agent", output)
                self.assertEqual("custom edit\n", agent.read_text())
                self.assertTrue((agent.parent / "fixture.agent.eval.yaml").exists())
                self.assertEqual(before, manifest.read_bytes())

    def test_workflow_opt_in_preserve_then_delete_no_recreation(self):
        for runner in self.runners():
            with self.subTest(runner=runner):
                path = self.consumer(runner)
                self.sync(path, runner, "install_sync_workflow: true\n")
                workflow = path / ".github" / "workflows" / "sheen-sync.yml"
                original = workflow.read_bytes()
                self.sync(path, runner)
                self.assertEqual(original, workflow.read_bytes())
                manifest = json.loads((path / ".sheen" / "manifest.json").read_text(encoding="utf-8-sig"))
                self.assertIn(".github/workflows/sheen-sync.yml", manifest["files"])
                workflow.unlink()
                self.sync(path, runner)
                self.assertFalse(workflow.exists())
                manifest = json.loads((path / ".sheen" / "manifest.json").read_text(encoding="utf-8-sig"))
                self.assertNotIn(".github/workflows/sheen-sync.yml", manifest["files"])

    def test_invalid_configuration_fails_without_installing(self):
        for runner in self.runners():
            for config in ["agent_distribution: invalid\n", "install_sync_workflow: perhaps\n"]:
                with self.subTest(runner=runner, config=config):
                    path = self.consumer(runner, str(len(list(self.root.iterdir()))))
                    self.sync(path, runner, config, fail=True)
                    self.assertFalse((path / ".sheen").exists())

    def test_index_flags_block_migration(self):
        for runner in self.runners():
            with self.subTest(runner=runner):
                path = self.consumer(runner)
                self.sync(path, runner, "agent_distribution: repository\n")
                self.git(path, "add", "-A")
                self.git(path, "commit", "-m", "installed")
                self.git(path, "update-index", "--assume-unchanged", ".github/agents/fixture.agent.md")
                output = self.sync(path, runner, fail=True)
                self.assertIn("Index flags block agent migration", output)
                self.assertTrue((path / ".github" / "agents" / "fixture.agent.md").exists())

    def test_previous_commit_fetch_and_staged_refusal(self):
        for runner in self.runners():
            with self.subTest(runner=runner):
                path = self.consumer(runner)
                self.sync(path, runner, "agent_distribution: repository\n")
                self.git(path, "add", "-A")
                self.git(path, "commit", "-m", "installed")
                agent = path / ".github" / "agents" / "fixture.agent.md"
                agent.write_text("staged edit\n")
                self.git(path, "add", ".github/agents/fixture.agent.md")
                agent.write_bytes((self.source / "agents" / "fixture.agent.md").read_bytes())
                self.sync(path, runner, fail=True)
                self.assertTrue(agent.exists())
                self.git(path, "add", ".github/agents/fixture.agent.md")
                (self.source / "agents" / "fixture.agent.md").write_text(self.definition + runner + "\n", newline="\n")
                self.git(self.source, "add", "-A")
                self.git(self.source, "commit", "-m", "new release")
                self.git(self.source, "tag", "-f", "v1.0.0")
                self.sync(path, runner)
                self.assertFalse(agent.exists())


if __name__ == "__main__":
    unittest.main()
