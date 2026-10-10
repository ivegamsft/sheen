#!/usr/bin/env python3
"""Release API and static workflow regressions for two-phase action pinning."""

import base64
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "discover_sheen_release", ROOT / "scripts/discover-sheen-release.py"
)
DISCOVERY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DISCOVERY)

OLD_SHA = "1" * 40
PUBLIC_SHA = "2" * 40
PRIVATE_SHA = "3" * 40
ANNOTATED_TAG_SHA = "4" * 40
RELEASE = {"tag_name": "v9.8.7", "draft": False, "prerelease": False}


def workflow(repository, line_ending="\n"):
    return line_ending.join(
        [
            "name: Sheen",
            "jobs:",
            "  discover:",
            f"    uses: {repository}/.github/actions/discover-release@{OLD_SHA}",
            "  sync:",
            f"    uses: {repository}/.github/actions/sync-assets@{OLD_SHA}",
            "    with:",
            f"      source_commit: {OLD_SHA}",
            "",
        ]
    )


class DiscoveryResolutionTests(unittest.TestCase):
    def setUp(self):
        test_root = ROOT / ".test-work"
        test_root.mkdir(exist_ok=True)
        self.scratch = Path(tempfile.mkdtemp(prefix="sheen-discovery-", dir=test_root))
        self.workflow_path = self.scratch / ".github/workflows/sheen-sync.yml"
        self.workflow_path.parent.mkdir(parents=True)

    def tearDown(self):
        import shutil
        shutil.rmtree(self.scratch, ignore_errors=True)

    def test_public_annotated_release_resolves_public_mirror_commit_and_is_idempotent(self):
        self.workflow_path.write_text(workflow("ivegamsft/sheen"), encoding="utf-8")

        def api(url):
            if url.endswith("/releases/latest"):
                return RELEASE
            if url.endswith("/git/ref/tags/v9.8.7"):
                return {"object": {"type": "tag", "sha": ANNOTATED_TAG_SHA}}
            if url.endswith(f"/git/tags/{ANNOTATED_TAG_SHA}"):
                return {"object": {"type": "commit", "sha": PUBLIC_SHA}}
            raise AssertionError(f"unexpected public API URL: {url}")

        with patch.object(DISCOVERY, "_request_json", side_effect=api) as calls:
            first = DISCOVERY.update_action_pins(self.workflow_path)
            first_content = self.workflow_path.read_text(encoding="utf-8")
            second = DISCOVERY.update_action_pins(self.workflow_path)
            self.assertEqual(calls.call_count, 6)

        self.assertTrue(first["changed"])
        self.assertEqual(first["commit"], PUBLIC_SHA)
        self.assertIs(second["changed"], False)
        self.assertEqual(second["commit"], PUBLIC_SHA)
        self.assertIn(f"discover-release@{PUBLIC_SHA}", first_content)
        self.assertIn(f"sync-assets@{PUBLIC_SHA}", first_content)
        self.assertIn(f"source_commit: {PUBLIC_SHA}", first_content)

    def test_internal_action_uses_private_source_provenance_not_public_commit(self):
        self.workflow_path.write_text(workflow("IBuySpy-Shared/basecoat-sheen"), encoding="utf-8")
        provenance = {
            "schema": "basecoat-sheen-release-provenance/v1",
            "source_tag": "v9.8.7",
            "source_commit": PRIVATE_SHA,
        }
        contents = {
            "encoding": "base64",
            "content": base64.b64encode(json.dumps(provenance).encode()).decode(),
        }

        def api(url):
            if url.endswith("/releases/tags/v9.8.7"):
                return RELEASE
            if "/contents/release-provenance.json?" in url:
                return contents
            raise AssertionError(f"unexpected internal provenance URL: {url}")

        with patch.object(DISCOVERY, "_request_json", side_effect=api):
            result = DISCOVERY.update_action_pins(self.workflow_path, "v9.8.7")

        content = self.workflow_path.read_text(encoding="utf-8")
        self.assertTrue(result["changed"])
        self.assertEqual(result["commit"], PRIVATE_SHA)
        self.assertIn(f"discover-release@{PRIVATE_SHA}", content)
        self.assertIn(f"sync-assets@{PRIVATE_SHA}", content)
        self.assertIn(f"source_commit: {PRIVATE_SHA}", content)
        self.assertNotIn(PUBLIC_SHA, content)

    def test_branch_refs_and_expression_injection_are_rejected_before_api_access(self):
        self.workflow_path.write_text(workflow("ivegamsft/sheen"), encoding="utf-8")
        with patch.object(DISCOVERY, "_request_json") as api:
            for requested in ("main", "refs/heads/main", "${{ github.event.issue.title }}"):
                with self.subTest(requested=requested):
                    with self.assertRaisesRegex(DISCOVERY.DiscoveryError, "published vX.Y.Z"):
                        DISCOVERY.update_action_pins(self.workflow_path, requested)
            api.assert_not_called()

    def test_missing_private_provenance_fails_closed_without_changing_workflow(self):
        original = workflow("IBuySpy-Shared/basecoat-sheen")
        self.workflow_path.write_text(original, encoding="utf-8")

        def api(url):
            if url.endswith("/releases/latest"):
                return RELEASE
            return {"encoding": "base64", "content": ""}

        with patch.object(DISCOVERY, "_request_json", side_effect=api):
            with self.assertRaisesRegex(DISCOVERY.DiscoveryError, "provenance"):
                DISCOVERY.update_action_pins(self.workflow_path)
        self.assertEqual(self.workflow_path.read_text(encoding="utf-8"), original)

    def test_duplicate_or_missing_action_refs_fail_closed(self):
        for invalid in (
            "uses: ivegamsft/sheen/.github/actions/sync-assets@sha\n",
            workflow("other-owner/repo"),
            workflow("ivegamsft/sheen").replace(
                f"discover-release@{OLD_SHA}", f"sync-assets@{OLD_SHA}"
            ),
        ):
            with self.subTest(invalid=invalid):
                self.workflow_path.write_text(invalid, encoding="utf-8")
                with patch.object(DISCOVERY, "_request_json") as api:
                    with self.assertRaises(DISCOVERY.DiscoveryError):
                        DISCOVERY.update_action_pins(self.workflow_path)
                    api.assert_not_called()


class TwoPhaseWorkflowTests(unittest.TestCase):
    def test_pin_discovery_only_changes_workflow_and_later_run_applies_pin(self):
        template = (ROOT / "templates/sheen-sync.yml").read_text(encoding="utf-8")
        self.assertIn("Open release pin-bump PR", template)
        self.assertIn("Assets apply on a later workflow run", template)
        self.assertIn("uses: IBuySpy-Shared/basecoat-sheen/.github/actions/sync-assets@v1.3.0", template)
        self.assertNotIn(
            "uses: IBuySpy-Shared/basecoat-sheen/.github/actions/sync-assets@${{",
            template,
        )
        self.assertNotIn("source_commit: ${{ steps.discovery.outputs.release_commit", template)
        self.assertNotIn("needs: [discover-release]", template)
        self.assertIn('paths:\n      - ".github/workflows/sheen-sync.yml"', template)
        self.assertIn("gh pr create", template)
        self.assertIn("gh pr merge", template)

    def test_publication_sanitizes_pins_and_keeps_runtime_provenance(self):
        publisher = (ROOT / ".github/workflows/publish-to-production.yml").read_text(encoding="utf-8")
        self.assertIn("Sanitize internal identifiers for production", publisher)
        self.assertIn("release-provenance.json", publisher)
        self.assertIn("PUBLIC_ACTIONS", publisher)
        self.assertIn("scripts/discover-sheen-release.py", publisher)


if __name__ == "__main__":
    unittest.main()
