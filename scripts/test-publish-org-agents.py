#!/usr/bin/env python3
import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("publisher", Path(__file__).with_name("publish-org-agents.py"))
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        self.target = self.root / "central"
        (self.source / "agents").mkdir(parents=True)
        self.target.mkdir()
        (self.source / ".gitattributes").write_text("* text eol=lf\n")
        (self.source / "agents" / "test.agent.md").write_bytes(b'---\nname: test\ndescription: Test\n---\nTest.\n')
        (self.source / "agents" / "test.agent.eval.yaml").write_text("not a definition\n")
        self.git("init", "-b", "main")
        self.git("config", "user.name", "test")
        self.git("config", "user.email", "test@example.com")
        self.commit()
        self.git("tag", "v1.0.0")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.source), *args], stderr=subprocess.STDOUT)

    def commit(self):
        self.git("add", "-A")
        self.git("commit", "-m", "fixture")

    def stage(self, ref="v1.0.0"):
        publisher.stage(self.source, self.target, "example/sheen", ref)

    def test_pinned_definitions_only_and_noop(self):
        self.stage()
        manifest = self.target / publisher.MANIFEST
        before = manifest.stat().st_mtime_ns
        self.stage()
        self.assertEqual(before, manifest.stat().st_mtime_ns)
        self.assertFalse((self.target / "agents" / "test.agent.eval.yaml").exists())
        data = json.loads(manifest.read_text())
        self.assertEqual(data["commit"], self.git("rev-parse", "HEAD").decode().strip())
        self.assertEqual(data["files"]["agents/test.agent.md"], publisher.digest(self.target / "agents" / "test.agent.md"))

    def test_modified_owned_file_blocks_all_writes(self):
        self.stage()
        agent = self.target / "agents" / "test.agent.md"
        agent.write_text("custom edit\n")
        before = (self.target / publisher.MANIFEST).read_bytes()
        with self.assertRaisesRegex(ValueError, "Locally modified"):
            self.stage()
        self.assertEqual(agent.read_text(), "custom edit\n")
        self.assertEqual(before, (self.target / publisher.MANIFEST).read_bytes())

    def test_collision_blocks_and_unrelated_files_survive(self):
        agents = self.target / "agents"
        agents.mkdir()
        (agents / "test.agent.md").write_text("custom\n")
        with self.assertRaisesRegex(ValueError, "collision"):
            self.stage()
        (agents / "test.agent.md").unlink()
        (agents / "other.agent.md").write_text("other\n")
        self.stage()
        self.assertEqual((agents / "other.agent.md").read_text(), "other\n")

    def test_stale_owned_removal_and_source_pin_refusal(self):
        self.stage()
        (self.source / "agents" / "test.agent.md").rename(self.source / "agents" / "new.agent.md")
        self.commit()
        with self.assertRaisesRegex(ValueError, "pinned source ref"):
            self.stage()
        self.git("tag", "v1.1.0")
        self.stage("v1.1.0")
        self.assertFalse((self.target / "agents" / "test.agent.md").exists())
        self.assertTrue((self.target / "agents" / "new.agent.md").exists())

    def test_manifest_path_escape_rejected(self):
        self.stage()
        manifest = self.target / publisher.MANIFEST
        data = json.loads(manifest.read_text())
        data["files"]["../outside.agent.md"] = "bad"
        manifest.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, "Unsafe managed path"):
            self.stage()


if __name__ == "__main__":
    unittest.main()
