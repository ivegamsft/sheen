#!/usr/bin/env python3
"""Regression checks for the token-free shared action and consumer template."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SharedActionTests(unittest.TestCase):
    def test_composite_action_uses_local_payload_on_both_runner_families(self):
        action = (ROOT / ".github/actions/sync-assets/action.yml").read_text(encoding="utf-8")
        self.assertIn("using: composite", action)
        self.assertIn("required: true", action)
        self.assertIn("SHEEN_SOURCE_COMMIT: ${{ inputs.source_commit }}", action)
        self.assertIn("SHEEN_ACTION_REF: ${{ github.action_ref }}", action)
        self.assertIn("source_commit must be the exact 40-character SHA", action)
        self.assertIn("github.action_repository", action)
        self.assertIn("SHEEN_SOURCE_PATH = $sourcePath", action)
        self.assertIn("SHEEN_SYNC_TEMP_ROOT = Join-Path $env:GITHUB_WORKSPACE '.git\\sheen-sync-staging'", action)
        self.assertIn('SHEEN_SOURCE_PATH="$(cd "$GITHUB_ACTION_PATH/../../.." && pwd)"', action)
        self.assertIn("SHEEN_SYNC_TEMP_ROOT: ${{ github.workspace }}/.git/sheen-sync-staging", action)
        self.assertIn("sync.ps1", action)
        self.assertIn("sync.sh", action)

    def test_release_discovery_exposes_outputs_to_the_consumer_workflow(self):
        action = (ROOT / ".github/actions/discover-release/action.yml").read_text(encoding="utf-8")
        self.assertIn("id: discover", action)
        for output in ("changed", "release_tag", "release_commit"):
            self.assertIn(f"value: ${{{{ steps.discover.outputs.{output} }}}}", action)

    def test_sync_engines_validate_and_stage_local_pinned_payload(self):
        bash = (ROOT / "sync.sh").read_text(encoding="utf-8")
        powershell = (ROOT / "sync.ps1").read_text(encoding="utf-8")
        for text in (bash, powershell):
            self.assertIn("SHEEN_SOURCE_PATH", text)
            self.assertIn("SHEEN_SOURCE_COMMIT", text)
            self.assertIn("templates/sheen-sync.yml", text)
            self.assertIn("Cannot verify legacy agent ownership", text)
        self.assertIn("cp -R \"$SOURCE_PATH\"/. \"$WORK\"/", bash)
        self.assertIn("git -c core.longpaths=true clone", bash)
        self.assertLess(
            bash.index('if [ "$LOCAL_SOURCE" -eq 1 ]; then'),
            bash.index("git -c core.longpaths=true clone"),
        )
        self.assertIn("Copy-Item -LiteralPath $_.FullName -Destination $work -Recurse -Force", powershell)
        self.assertIn("git -c core.longpaths=true clone", powershell)
        self.assertLess(
            powershell.index("if ($localSource) {"),
            powershell.index("git -c core.longpaths=true clone"),
        )

    def test_default_template_separates_release_discovery_from_asset_application(self):
        template = (ROOT / "templates/sheen-sync.yml").read_text(encoding="utf-8")
        self.assertIn("uses: IBuySpy-Shared/basecoat-sheen/.github/actions/discover-release@v1.3.0", template)
        self.assertIn("uses: IBuySpy-Shared/basecoat-sheen/.github/actions/sync-assets@v1.3.0", template)
        self.assertIn("source_commit: v1.3.0", template)
        self.assertIn("source_ref", template)
        self.assertIn("this run still uses the installed SHA", template)
        self.assertIn("Open release pin-bump PR", template)
        self.assertIn("Open asset update PR", template)
        self.assertIn("secrets.SHEEN_UPDATE_TOKEN || github.token", template)
        self.assertIn("manual workflow_dispatch run", template)
        jobs = template.split("# For custom or non-Git source repositories, use", 1)[0]
        self.assertNotIn("check-sheen-version-callable.yml@", jobs)
        self.assertNotIn("SHEEN_FETCH_TOKEN", jobs)
        self.assertIn("SHEEN_FETCH_TOKEN", template)

    def test_publication_preserves_only_public_action_entries_and_resolver(self):
        publisher = (ROOT / ".github/workflows/publish-to-production.yml").read_text(encoding="utf-8")
        for path in (
            ".github/actions/sync-assets/action.yml",
            ".github/actions/discover-release/action.yml",
            "scripts/discover-sheen-release.py",
        ):
            self.assertIn(path, publisher)
        self.assertIn("PUBLIC_ACTIONS", publisher)
        self.assertIn("is_public_action", publisher)
        for path in (
            "scripts/test-sheen-shared-action.py",
            "scripts/test-sheen-release-discovery.py",
        ):
            self.assertIn(path, publisher)
        self.assertIn("release-provenance.json", publisher)
        self.assertIn("source_commit", publisher)


if __name__ == "__main__":
    unittest.main()
