"""Source-document contract regressions, not research or LLM behavior validation.

Run from the source checkout with Python 3; no consumer runtime tooling required.
"""

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
OWNERS = ("user-research", "design-bootstrap", "design-exploration")


def read(relative):
    return (ROOT / relative).read_text(encoding="utf-8")


class DiscoveryContractTests(unittest.TestCase):
    def test_skill_bodies_and_required_intake(self):
        for owner in OWNERS:
            with self.subTest(owner=owner):
                text = read(Path("skills") / owner / "SKILL.md")
                body = text.split("---", 2)[2]
                self.assertLessEqual(len(body), 2500)
                self.assertRegex(body, r"Read/apply the \[")
                for section in ("Workflow", "Guardrails", "Output", "Delegates / pairs with"):
                    self.assertIn("## " + section, body)
                self.assertIn("USE FOR:", text)
                self.assertIn("DO NOT USE FOR:", text)

    def test_complete_skill_local_links(self):
        for owner in OWNERS:
            folder = ROOT / "skills" / owner
            for document in folder.rglob("*.md"):
                for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", document.read_text(encoding="utf-8")):
                    with self.subTest(document=document.name, target=target):
                        self.assertNotRegex(target, r"^(https?:|/|[A-Z]:)")
                        resolved = (document.parent / target.split("#")[0]).resolve()
                        self.assertTrue(resolved.is_relative_to(folder.resolve()))
                        self.assertTrue(resolved.is_file())

    def test_blank_portable_brief_contract(self):
        text = read(Path("skills/user-research/templates/discovery-brief.md"))
        for field in (
            "Brief ID/revision/date", "Client/product context", "success/acceptance criteria",
            "Scope/exclusions", "Audience/recruitment", "accessibility needs",
            "Known inputs", "Deliverable destination", "voluntary informed consent",
            "Collection/use authorization", "Separate recording permission",
            "Access/sharing restrictions", "Retention period / deletion owner",
            "Withdrawal handling", "A- assumption or U- unknown", "Impact",
            "Validation question/method", "Owner", "Checkpoint",
            "Neutral questions", "Authorized method / roles / schedule",
            "Starting condition", "Success criterion", "Observation method",
            "Stop condition", "Receiving skill/owner", "Closure criteria",
        ):
            with self.subTest(field=field):
                self.assertIn(field, text)
        self.assertIn("No study has been performed", text)
        rows = [line for line in text.splitlines() if line.startswith("| `<")]
        self.assertEqual(len(rows), 2)
        self.assertTrue(all("<...>" in row for row in rows))

    def test_register_traceability_and_nonfabrication(self):
        text = read(Path("skills/user-research/templates/evidence-findings.md"))
        for field in (
            "Evidence ID (E-)", "exact locator", "Date/version / method/context",
            "Availability", "authorization reference", "Access/sharing restrictions",
            "withdrawal status", "Finding ID (F-)", "hypothesis, unresolved",
            "Observation", "Interpretation", "Recommendation", "Evidence IDs",
            "Confidence and rationale", "Limitations / conflicting evidence",
            "assumption and unknown IDs", "Severity/impact", "Remediation owner",
            "closure criteria", "escalation threshold", "Persona synthesis provenance",
            "Stale/withdrawn evidence reassessment", "Decision ID (D-)",
            "Brief ID/revision and scope", "Restricted locators", "Receiving skill/owner",
            "Next validation / acceptance checkpoint", "not granted by findings",
        ):
            with self.subTest(field=field):
                self.assertIn(field, text)
        self.assertIn("Blank template", text)
        contract = read(Path("skills/user-research/references/discovery-contract.md"))
        for boundary in (
            "Unknown permission", "blocks the affected activity",
            "Do not contact participants, record, scrape, publish or transfer",
            "Missing, inaccessible, stale, withdrawn or unauthorized",
            "unresolved or a hypothesis, never evidence-backed",
            "Never fabricate interviews", "otherwise paraphrase with attribution",
            "qualitative anecdotes", "Hypothetical personas",
            "remove evidence from active synthesis", "dependent",
            "Do not assert", "anonymity or legal compliance",
            "Keep raw participant data out by default",
        ):
            with self.subTest(boundary=boundary):
                self.assertIn(boundary, contract)

    def test_no_evidence_allows_only_bounded_hypothesis_directions(self):
        skill = read(Path("skills/design-exploration/SKILL.md"))
        self.assertNotIn("Do not make directional claims without evidence collection", skill)
        self.assertIn(
            "Do not present directional claims as evidence-backed without authorized supporting evidence.",
            skill,
        )
        self.assertIn(
            "Without evidence, allow explicitly provisional hypothesis directions "
            "with assumptions, limits and validation checkpoints.",
            skill,
        )
        self.assertIn("never invent research or treat concepts as user validation", skill)
        intake = read(Path("skills/design-exploration/references/discovery-intake.md"))
        self.assertIn("provisional concept exploration with explicit gaps", intake)
        self.assertIn("not a completed", intake)
        self.assertIn("not hypothesis-labeled exploration", intake)
        evaluation = read(Path("skills/design-exploration/eval.yaml"))
        scenario = evaluation.split('id: "pos-hypothesis-directions"', 1)[1].split("  - id:", 1)[0]
        self.assertIn("unresearched new product", scenario)
        self.assertIn("label assumptions as hypotheses", scenario)
        self.assertIn("expect_activation: true", scenario)

    def test_discovery_preserves_capabilities_without_expanding_scope(self):
        contract = read(Path("skills/user-research/references/discovery-contract.md"))
        normalized = " ".join(contract.split())
        self.assertNotIn("Do not skip prior", normalized)
        self.assertIn("Include a usability protocol when requested and authorized", normalized)
        self.assertIn(
            "Preserve research planning, persona synthesis, usability testing and governance "
            "review as available capabilities within the requested and authorized scope.",
            normalized,
        )
        self.assertIn(
            "Do not expand a discovery brief into new research, persona synthesis, usability "
            "testing or governance review that was not requested or authorized.",
            normalized,
        )
        self.assertIn("Mark excluded activities not applicable with a scope reason", normalized)
        self.assertIn("gaps become proposed follow-ups, not permission to conduct a study", normalized)
        self.assertIn("With no authorized evidence, output a plan and hypotheses", normalized)

    def test_prior_capabilities_and_ownership(self):
        expected = {
            "user-research": ("interview/persona synthesis", "usability test protocols",
                              "severity", "remediation owners", "decision log",
                              "exception path", "style preference"),
            "design-bootstrap": ("core + semantic", "light/dark/high-contrast",
                                 "component/spec", "IA/navigation", "accessibility",
                                 "staged rollout"),
            "design-exploration": ("creative calibration", "anti-template comparison",
                                   "rejected-alternatives log", "Accepted system/product",
                                   "risks and dependency map", "design-debate"),
        }
        for owner, terms in expected.items():
            skill = read(Path("skills") / owner / "SKILL.md")
            for term in terms:
                with self.subTest(owner=owner, term=term):
                    self.assertIn(term, skill)
        for owner in OWNERS[1:]:
            intake = read(Path("skills") / owner / "references/discovery-intake.md")
            for term in ("user-research", "unknown", "restrictions", "checkpoint",
                         "raw participant data", "explicit", "authorization"):
                with self.subTest(owner=owner, term=term):
                    self.assertIn(term, intake)
        agent = read(Path("agents/ux-designer.agent.md"))
        self.assertIn("    - user-research", agent)
        self.assertIn("without raw participant data", agent)
        catalog = read(Path("skills/_catalog.md"))
        for owner in OWNERS:
            self.assertIn("skills/" + owner + "/", catalog)

    def test_routing_preserves_prior_and_adds_boundaries(self):
        # Schema/scoring is exercised by the existing PowerShell routing gate.
        required = {
            "user-research": ("pos-1", "pos-2", "pos-3", "pos-client-discovery",
                              "pos-evidence-conflict", "pos-no-evidence",
                              "neg-concepts-only", "neg-backend"),
            "design-bootstrap": ("pos-1", "pos-2", "pos-3",
                                 "pos-discovery-foundations", "neg-discovery-only",
                                 "neg-backend"),
            "design-exploration": ("pos-divergent-concepts", "pos-anti-template-check",
                                   "pos-evidence-directions", "pos-hypothesis-directions",
                                   "neg-research-only", "neg-production-code"),
        }
        for owner, ids in required.items():
            text = read(Path("skills") / owner / "eval.yaml")
            for scenario in ids:
                with self.subTest(owner=owner, scenario=scenario):
                    self.assertIn('id: "' + scenario + '"', text)
            self.assertGreaterEqual(text.count("expect_activation: true"), 3)
            self.assertGreaterEqual(text.count("expect_activation: false"), 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
