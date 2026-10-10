#!/usr/bin/env python3
"""Source-only unittest regression gate for portable blueprint handoff."""
import copy
import importlib.util
import json
import re
import shutil
import subprocess
import sys
import unittest
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "design-handoff"
spec = importlib.util.spec_from_file_location("handoff", SKILL / "scripts" / "validate-wireframe-handoff.py")
handoff = importlib.util.module_from_spec(spec)
spec.loader.exec_module(handoff)
validator = handoff.load_validator()
SAMPLE = SKILL / "templates" / "wireframe-blueprint.json"
ORIGINAL = ROOT / "skills" / "wireframing" / "templates" / "task-flow.json"


class HandoffTests(unittest.TestCase):
    def setUp(self):
        self.blueprint = json.loads(SAMPLE.read_bytes())
        self.original = json.loads(ORIGINAL.read_bytes())

    def test_modes_and_original_model_identity(self):
        original = json.loads((ROOT / "skills" / "wireframing" / "templates" / "task-flow.json").read_bytes())
        for mode in ["audit", "generate"]:
            with self.subTest(mode=mode):
                self.blueprint["mode"] = mode
                before = copy.deepcopy(self.blueprint)
                self.assertEqual(handoff.validate(self.blueprint, validator, [self.original]), [("wf-saved-views", "pending")])
                self.assertEqual(self.blueprint, before)
                self.assertEqual(self.blueprint["wireframes"][0]["model"], original)
        result = subprocess.run(
            ["pwsh", "-NoProfile", "-File", str(ROOT / "scripts" / "audit-experience-blueprint.ps1"),
             "-Path", str(SAMPLE), "-OriginalModelPath", str(ORIGINAL), "-Quiet"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_legacy_blueprints_do_not_require_wireframes(self):
        for mode in ["audit", "generate"]:
            self.blueprint["mode"] = mode
            self.blueprint.pop("wireframes", None)
            self.assertEqual(handoff.validate(self.blueprint, validator), [])
        legacy = json.loads((ROOT / "tests" / "fixtures" / "experience-blueprints" / "valid-sample.json").read_bytes())
        self.assertEqual(handoff.validate(legacy, validator), [])

    def test_unrelated_blueprint_ids_and_ordered_state_mapping(self):
        self.blueprint["pages"].append({
            "id": "other/page#detail", "layout": "layout-workspace",
            "states": {"default": "not modeled"}
        })
        self.blueprint["flows"].append({"id": "other/flow#detail", "steps": [{"page": "other/page#detail"}]})
        self.assertEqual(handoff.validate(self.blueprint, validator, [self.original]), [("wf-saved-views", "pending")])

    def test_screen_ids_are_scoped_to_model_not_blueprint_artifacts(self):
        renamed = json.loads(json.dumps(self.blueprint).replace('"list-empty"', '"views"'))
        original = json.loads(json.dumps(self.original).replace('"list-empty"', '"views"'))
        attachment = renamed["wireframes"][0]
        attachment["baseline"]["digest"] = handoff.model_digest(original)
        attachment["baseline"]["revision"] = handoff.model_digest(original)
        self.assertEqual(handoff.validate(renamed, validator, [original]), [("wf-saved-views", "pending")])
        second = copy.deepcopy(attachment)
        second["id"] = "wf-second-view"
        second["model"]["title"] = "Independent second exploration"
        second_original = copy.deepcopy(second["model"])
        second["baseline"]["digest"] = handoff.model_digest(second_original)
        second["baseline"]["revision"] = handoff.model_digest(second_original)
        renamed["wireframes"].append(second)
        self.assertEqual(
            handoff.validate(renamed, validator, [second_original, original]),
            [("wf-saved-views", "pending"), ("wf-second-view", "pending")])

    def test_audit_findings_resolve_validated_attachment_text_ids(self):
        scratch = ROOT / (".handoff-regression-" + uuid.uuid4().hex)
        scratch.mkdir()
        try:
            sample = scratch / "audit.json"
            for identifier in ["wf-saved-views", "source/wireframe#saved"]:
                with self.subTest(identifier=identifier):
                    blueprint = copy.deepcopy(self.blueprint)
                    blueprint["mode"] = "audit"
                    blueprint["wireframes"][0]["id"] = identifier
                    blueprint["evidence"] = [{"id": "example-evidence"}]
                    blueprint["findings"] = [{
                        "id": "example-finding", "evidenceIds": ["example-evidence"],
                        "artifactIds": [identifier]
                    }]
                    self.assertEqual(handoff.validate(blueprint, validator, [self.original]), [(identifier, "pending")])
                    sample.write_text(json.dumps(blueprint), encoding="utf-8")
                    command = ["pwsh", "-NoProfile", "-File", str(ROOT / "scripts" / "audit-experience-blueprint.ps1"),
                               "-Path", str(sample), "-OriginalModelPath", str(ORIGINAL), "-Json"]
                    result = subprocess.run(command, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                    self.assertFalse(any(f["severity"] == "error" for f in json.loads(result.stdout)["findings"]))
                    for collision in ["views", "example-evidence", "example-finding"]:
                        invalid = copy.deepcopy(blueprint)
                        invalid["wireframes"][0]["id"] = collision
                        invalid["findings"][0]["artifactIds"] = [collision]
                        with self.assertRaisesRegex(ValueError, "Duplicate attachment artifact ID"):
                            handoff.validate(invalid, validator, [self.original])
                        sample.write_text(json.dumps(invalid), encoding="utf-8")
                        result = subprocess.run(command, capture_output=True, text=True)
                        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                        self.assertTrue(any(f["rule"] == "wireframe-handoff" for f in json.loads(result.stdout)["findings"]))
                    duplicate = copy.deepcopy(blueprint)
                    duplicate["wireframes"].append(copy.deepcopy(duplicate["wireframes"][0]))
                    with self.assertRaisesRegex(ValueError, "duplicate ID"):
                        handoff.validate(duplicate, validator, [self.original, self.original])
        finally:
            shutil.rmtree(scratch)

    def test_invalid_models_reuse_existing_validation(self):
        mutations = [
            lambda m: m.update(schema="invented/v2"),
            lambda m: m.update(start="missing"),
            lambda m: m.update(unknown="discard me"),
            lambda m: m["screens"][0].update(page="missing"),
            lambda m: m["screens"][1].update(id=m["screens"][0]["id"]),
            lambda m: m["screens"][0]["regions"][0]["blocks"][-1].update(target="missing"),
            lambda m: m["flows"][0].update(steps=["saved", "edit"]),
            lambda m: m["screens"].append(dict(copy.deepcopy(m["screens"][0]), id="unreachable")),
        ]
        for mutate in mutations:
            with self.subTest(mutation=mutate):
                blueprint = copy.deepcopy(self.blueprint)
                mutate(blueprint["wireframes"][0]["model"])
                with self.assertRaises(ValueError):
                    handoff.validate(blueprint, validator, [self.original])

    def test_incomplete_or_unsafe_handoffs_block(self):
        mutations = [
            lambda b, a: a.pop("baseline"),
            lambda b, a: a.update(baseline={}),
            lambda b, a: a["baseline"].update(revision=""),
            lambda b, a: a["baseline"].update(revision="main"),
            lambda b, a: a["baseline"].update(revision="git:short"),
            lambda b, a: a["baseline"].update(revision="sha256:" + "0" * 64),
            lambda b, a: a["baseline"].update(approvalEvidence=[]),
            lambda b, a: a["baseline"].update(approvalEvidence=[""]),
            lambda b, a: a["baseline"].update(digest=""),
            lambda b, a: a["baseline"].update(digest="sha256:" + "0" * 64),
            lambda b, a: a.update(simulated=False),
            lambda b, a: a.update(simulated=1),
            lambda b, a: a.update(source=""),
            lambda b, a: a.update(unknown="silently dropped"),
            lambda b, a: a.update(id="views"),
            lambda b, a: a["screens"].pop(),
            lambda b, a: a["screens"][0].update(id="renamed-screen"),
            lambda b, a: a["screens"][0].update(target=""),
            lambda b, a: a["screens"][0].update(components=[]),
            lambda b, a: a["screens"][1]["controls"].pop(),
            lambda b, a: a["screens"][0]["controls"][0].update(block=0),
            lambda b, a: a["screens"][0]["controls"][0].update(region=-1),
            lambda b, a: a["screens"][0]["controls"][0].update(region=False),
            lambda b, a: a["screens"][0]["controls"].append(copy.deepcopy(a["screens"][0]["controls"][0])),
            lambda b, a: a["screens"][0]["controls"][0].update(dependencies=[]),
            lambda b, a: a["screens"][0]["controls"][0].update(limitations=""),
            lambda b, a: b["pages"][0].update(id="renamed-page"),
            lambda b, a: b["pages"][0]["states"].update(empty="not-applicable"),
            lambda b, a: a["states"]["views"].pop("permission"),
            lambda b, a: a["states"]["views"].pop("partial"),
            lambda b, a: a["states"]["views"].update(loading=""),
            lambda b, a: a["flows"][0].update(id="renamed-flow"),
            lambda b, a: b["flows"][0].update(id="different-flow"),
            lambda b, a: a["flows"][0].update(steps=[0, 1, 2]),
            lambda b, a: a["flows"][0].update(steps=[0, 1, 3, 2]),
            lambda b, a: a["flows"][0].update(steps=[0, 1, 2, 9]),
            lambda b, a: a["flows"][0].update(steps=[False, 1, 2, 3]),
            lambda b, a: b["flows"][0]["steps"][1].update(page="views"),
            lambda b, a: b["flows"][0]["steps"][1].update(page=None, external="real-provider"),
            lambda b, a: a["limitations"].update(simulation=""),
            lambda b, a: a["review"].update(status="accepted"),
            lambda b, a: a["review"].update(status="reviewed", evidence=[]),
            lambda b, a: b.update(wireframes=[]),
            lambda b, a: b["wireframes"].append(copy.deepcopy(a)),
        ]
        for mutate in mutations:
            with self.subTest(mutation=mutate):
                blueprint = copy.deepcopy(self.blueprint)
                mutate(blueprint, blueprint["wireframes"][0])
                with self.assertRaises(ValueError):
                    handoff.validate(blueprint, validator, [self.original])

    def test_review_evidence_and_partial_flow_mapping(self):
        attachment = self.blueprint["wireframes"][0]
        attachment["review"] = {"status": "reviewed", "evidence": ["review-session: visual/task paths, limitations recorded"]}
        attachment["model"]["flows"][0]["steps"] = ["list-empty", "edit", "saved"]
        attachment["flows"][0]["steps"] = [0, 1, 2]
        attachment["flows"][0]["limitations"] = "Return step omitted; cancellation not exercised"
        attachment["flows"][1]["steps"] = [0, 0, 2, 3]
        revised_original = copy.deepcopy(self.original)
        revised_original["flows"][0]["steps"] = ["list-empty", "edit", "saved"]
        attachment["baseline"]["digest"] = handoff.model_digest(revised_original)
        attachment["baseline"]["revision"] = handoff.model_digest(revised_original)
        self.assertEqual(handoff.validate(self.blueprint, validator, [revised_original]), [("wf-saved-views", "reviewed")])

    def test_synced_pair_is_read_only_and_dependency_failure_is_clear(self):
        scratch = ROOT / (".handoff-regression-" + uuid.uuid4().hex)
        scratch.mkdir()
        try:
            for name in ["design-handoff", "wireframing"]:
                shutil.copytree(ROOT / "skills" / name, scratch / name, ignore=shutil.ignore_patterns("__pycache__"))
            script = scratch / "design-handoff" / "scripts" / "validate-wireframe-handoff.py"
            sample = scratch / "design-handoff" / "templates" / "wireframe-blueprint.json"
            original = scratch / "wireframing" / "templates" / "task-flow.json"
            before = {p.relative_to(scratch): (p.read_bytes(), p.stat().st_mtime_ns)
                      for p in scratch.rglob("*") if p.is_file()}
            result = subprocess.run([sys.executable, str(script), "--input", str(sample), "--original-model", str(original)],
                                    cwd=scratch, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("review pending", result.stdout)
            self.assertIn("no production approval", result.stdout)
            after = {p.relative_to(scratch): (p.read_bytes(), p.stat().st_mtime_ns)
                     for p in scratch.rglob("*") if p.is_file()}
            self.assertEqual(before, after)
            renamed = json.dumps(self.blueprint).replace('"views"', '"renamed-page"')
            sample.write_text(renamed, encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(script), "--input", str(sample), "--original-model", str(original)],
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertIn("differs from approved original", result.stderr)
            invalid = copy.deepcopy(self.blueprint)
            invalid["wireframes"][0]["simulated"] = False
            sample.write_text(json.dumps(invalid), encoding="utf-8")
            result = subprocess.run(
                ["pwsh", "-NoProfile", "-File", str(ROOT / "scripts" / "audit-experience-blueprint.ps1"),
                 "-Path", str(sample), "-OriginalModelPath", str(original)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("wireframe-handoff", result.stdout)
            sample.write_text('{"mode":"audit","mode":"generate"}', encoding="utf-8")
            result = subprocess.run([sys.executable, str(script), "--input", str(sample)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertIn("Duplicate JSON", result.stderr)
            shutil.rmtree(scratch / "wireframing")
            result = subprocess.run([sys.executable, str(script), "--input", str(sample)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertIn("Sync the sibling wireframing", result.stderr)
        finally:
            shutil.rmtree(scratch)

    def test_skills_remain_bounded_with_local_contracts(self):
        for name in ["experience-blueprint", "design-handoff"]:
            document = (ROOT / "skills" / name / "SKILL.md").read_text(encoding="utf-8")
            body = document.split("---", 2)[2].replace("\r\n", "\n").strip()
            self.assertLessEqual(len(body), 2500)
            self.assertIn("sheen-wireframes/v1", body)
        self.assertTrue((SKILL / "references" / "wireframe-contract.md").is_file())
        self.assertTrue((ROOT / "skills" / "experience-blueprint" / "references" / "wireframe-intake.md").is_file())

    def test_handoff_template_has_portable_omission_and_limitation_records(self):
        document = (ROOT / "templates" / "experience-blueprint" / "handoff.md").read_text(encoding="utf-8")
        portable = document.split("## 5. Optional portable wireframe intake", 1)[1]
        self.assertIn("| Page ID | Omitted state | Omission reason | Source page-state contract |", portable)
        self.assertIn("including permission and partial", portable)
        self.assertIn("| Source artifact / screen IDs | Dimension | Limitation / unresolved behavior | Review status and evidence | Follow-up owner / validation task |", portable)
        for dimension in ["Responsive", "Accessibility"]:
            self.assertIn(f"| | {dimension} |", portable)
        self.assertIn("Missing visual/task evidence remains pending", portable)
        self.assertIn("| Source artifact ID | Original model baseline location | Immutable revision / approval evidence | Canonical baseline SHA-256 |", portable)

    def test_canonical_baseline_digest_is_portable_and_not_independent_trust(self):
        lf = json.dumps(self.original, ensure_ascii=False, indent=2) + "\n"
        crlf = lf.replace("\n", "\r\n")
        reordered = {key: self.original[key] for key in reversed(self.original)}
        expected = self.blueprint["wireframes"][0]["baseline"]["digest"]
        for original in [json.loads(lf), json.loads(crlf), reordered]:
            self.assertEqual(handoff.model_digest(original), expected)
            self.assertEqual(handoff.validate(self.blueprint, validator, [original]), [("wf-saved-views", "pending")])
        attachment = self.blueprint["wireframes"][0]
        attachment["model"]["title"] = "Self-declared revised model"
        attachment["baseline"]["digest"] = handoff.model_digest(attachment["model"])
        attachment["baseline"]["revision"] = attachment["baseline"]["digest"]
        with self.assertRaisesRegex(ValueError, "differs from approved original"):
            handoff.validate(self.blueprint, validator, [self.original])
        self.assertIn("synthetic", attachment["baseline"]["approvalEvidence"][0])

    def test_missing_original_blocks_cli_and_auditor(self):
        with self.assertRaisesRegex(ValueError, "requires separately supplied"):
            handoff.validate(self.blueprint, validator)
        auditor = ROOT / "scripts" / "audit-experience-blueprint.ps1"
        narrow_command = (
            "function Format-Table { param([switch]$Wrap, [switch]$AutoSize, "
            "[Parameter(ValueFromPipeline)]$InputObject) begin { $rows = @() } "
            "process { $rows += $InputObject } end { "
            "$rows | Microsoft.PowerShell.Utility\\Format-Table -Wrap -AutoSize | Out-String -Width 60 } }; "
            f"& '{str(auditor).replace(chr(39), chr(39) * 2)}' "
            f"-Path '{str(SAMPLE).replace(chr(39), chr(39) * 2)}'"
        )
        commands = [
            ([sys.executable, str(SKILL / "scripts" / "validate-wireframe-handoff.py"), "--input", str(SAMPLE)], False),
            (["pwsh", "-NoProfile", "-File", str(auditor), "-Path", str(SAMPLE)], True),
            (["pwsh", "-NoProfile", "-Command", narrow_command], True),
        ]
        for command, is_auditor in commands:
            with self.subTest(command=command):
                result = subprocess.run(command, capture_output=True, text=True)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                output = result.stdout + result.stderr
                if is_auditor:
                    # Console Format-Table may split words.
                    self.assertIn("wireframe-handoff", output)
                    self.assertIn("1 error(s)", output)
                else:
                    self.assertIn("requires separately supplied", output)

    def test_coordinated_renaming_cannot_replace_approved_original(self):
        for old, new in [("views", "renamed-page"), ("edit", "renamed-screen"), ("create-view", "renamed-flow")]:
            with self.subTest(identity=old):
                # Replace every exact identifier in model, index and mappings.
                encoded = json.dumps(self.blueprint).replace(json.dumps(old), json.dumps(new))
                renamed = json.loads(encoded)
                validator.validate(renamed["wireframes"][0]["model"])
                with self.assertRaisesRegex(ValueError, "differs from approved original"):
                    handoff.validate(renamed, validator, [self.original])
        changed = copy.deepcopy(self.blueprint)
        changed["wireframes"][0]["model"]["title"] = "Changed source"
        with self.assertRaisesRegex(ValueError, "differs from approved original"):
            handoff.validate(changed, validator, [self.original])

    def test_auditor_python3_only_selection_runs_real_checker(self):
        auditor = ROOT / "scripts" / "audit-experience-blueprint.ps1"
        # Exercise the non-Windows selection even on Windows, with only python3
        # discoverable through this process's command lookup. Execute real Python.
        def quoted(value):
            return "'" + str(value).replace("'", "''") + "'"
        command = (
            "Set-Variable -Name IsWindows -Value $false -Force; "
            "function Get-Command { param($Name, $CommandType, $ErrorAction) "
            "if ($Name -ne 'python3') { throw 'Only python3 is available' }; "
            "Write-Host 'selected:python3'; "
            f"Microsoft.PowerShell.Core\\Get-Command {quoted(sys.executable)} -CommandType Application }}; "
            f"& {quoted(auditor)} -Path {quoted(SAMPLE)} -OriginalModelPath {quoted(ORIGINAL)} -Quiet"
        )
        result = subprocess.run(["pwsh", "-NoProfile", "-Command", command], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("selected:python3", result.stdout)

    def test_legacy_auditor_valid_and_invalid_without_baseline(self):
        for fixture, expected in [("valid-sample.json", 0), ("invalid-sample.json", 1)]:
            result = subprocess.run(
                ["pwsh", "-NoProfile", "-File", str(ROOT / "scripts" / "audit-experience-blueprint.ps1"),
                 "-Path", str(ROOT / "tests" / "fixtures" / "experience-blueprints" / fixture), "-Quiet"],
                capture_output=True, text=True)
            self.assertEqual(result.returncode, expected, result.stdout + result.stderr)

    def test_successful_auditor_keeps_structural_and_pending_boundaries_in_report(self):
        command = ["pwsh", "-NoProfile", "-File", str(ROOT / "scripts" / "audit-experience-blueprint.ps1"),
                   "-Path", str(SAMPLE), "-OriginalModelPath", str(ORIGINAL)]
        result = subprocess.run(command + ["-Json", "-Quiet"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(report["errorCount"], 0)
        boundary = next(f for f in report["findings"] if f["rule"] == "wireframe-handoff-boundary")
        self.assertEqual(boundary["severity"], "warning")
        self.assertTrue(boundary["details"]["structuralOnly"])
        self.assertTrue(boundary["details"]["noProductionApproval"])
        self.assertTrue(boundary["details"]["noWriteAuthorization"])
        self.assertEqual(boundary["details"]["reviews"], [{"artifactId": "wf-saved-views", "visualTaskReview": "pending"}])
        self.assertIn("review pending", boundary["message"])
        self.assertIn("no production approval", boundary["message"])
        console = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(console.returncode, 0, console.stdout + console.stderr)
        self.assertIn("wireframe-handoff-boundary", console.stdout)
        compact = "".join(console.stdout.split())
        self.assertIn("reviewpending", compact)
        self.assertIn("noproductionapproval", compact)
        legacy = subprocess.run(
            ["pwsh", "-NoProfile", "-File", str(ROOT / "scripts" / "audit-experience-blueprint.ps1"),
             "-Path", str(ROOT / "tests" / "fixtures" / "experience-blueprints" / "valid-sample.json"), "-Json"],
            capture_output=True, text=True)
        self.assertEqual(legacy.returncode, 0, legacy.stdout + legacy.stderr)
        self.assertFalse(any(f["rule"] == "wireframe-handoff-boundary" for f in json.loads(legacy.stdout)["findings"]))

    def test_source_regression_is_registered_and_stripped_from_production(self):
        ci = (ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
        self.assertIn(
            "run: |\n          python scripts/test-wireframes.py\n          python scripts/test-wireframe-handoff.py",
            ci)
        publication = (ROOT / ".github" / "workflows" / "publish-to-production.yml").read_text(encoding="utf-8")
        required = {
            "scripts/test-wireframes.py", "scripts/test-wireframe-handoff.py",
            "tests/visual-regression/requirements.txt",
            "tests/visual-regression/style-guide-evidence.js",
            "tests/visual-regression/style-guide-html.spec.js",
            "tests/visual-regression/style-guide-print.py",
        }

        def assert_exclusions(document):
            arrays = re.findall(r"(?ms)^\s*INTERNAL_PATTERNS=\(\s*\n(.*?)^\s*\)", document)
            self.assertEqual(len(arrays), 1, "Expected one publication INTERNAL_PATTERNS array")
            entries = set(re.findall(r"(?m)^\s*'([^']+)'\s*$", arrays[0]))
            self.assertTrue(required <= entries, f"Missing source-only exclusions: {required - entries}")

        assert_exclusions(publication)
        additional = publication.replace(
            "'scripts/test-wireframes.py'",
            "'scripts/test-wireframes.py'\n            'scripts/test-guide-source-only.py'", 1)
        assert_exclusions(additional)
        for entry in required:
            with self.subTest(missing=entry):
                missing = additional.replace(f"'{entry}'", "'scripts/unrelated-source-only.py'")
                # An occurrence outside the strip array must not mask absence.
                missing += f"\n# '{entry}'\n"
                with self.assertRaises(AssertionError):
                    assert_exclusions(missing)


if __name__ == "__main__":
    unittest.main()
