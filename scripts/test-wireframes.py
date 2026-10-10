#!/usr/bin/env python3
import copy
import importlib.util
import json
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills" / "wireframing"
spec = importlib.util.spec_from_file_location("renderer", SKILL / "scripts" / "render-wireframes.py")
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)


class WireframeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.model = json.loads((SKILL / "templates" / "task-flow.json").read_text())
        self.input = self.root / "model.json"
        self.save()

    def tearDown(self):
        self.temp.cleanup()

    def save(self):
        self.input.write_text(json.dumps(self.model), encoding="utf-8")

    def test_three_formats_and_noop(self):
        for format_name in ["spec", "svg", "html"]:
            output = self.root / ("output." + format_name)
            self.assertEqual(renderer.write(self.input, output, format_name), "written")
            before = output.stat().st_mtime_ns
            sidecar = output.with_name(output.name + ".sheen-wireframe.json")
            before_sidecar = sidecar.stat().st_mtime_ns
            self.assertEqual(renderer.write(self.input, output, format_name), "unchanged")
            self.assertEqual(before, output.stat().st_mtime_ns)
            self.assertEqual(before_sidecar, sidecar.stat().st_mtime_ns)
            if format_name == "svg":
                svg = ET.fromstring(output.read_text())
                self.assertEqual(svg.attrib["role"], "img")
                self.assertIn("list-empty", output.read_text())
            elif format_name == "html":
                self.assertIn("Content-Security-Policy", output.read_text())
                self.assertNotIn("https://", output.read_text())
            else:
                self.assertIn("## Flows", output.read_text())

    def test_dangling_duplicate_and_invalid_references(self):
        mutations = [
            lambda m: m["screens"][0].update(page="missing"),
            lambda m: m["screens"][1].update(id=m["screens"][0]["id"]),
            lambda m: m.update(start="missing"),
            lambda m: m["screens"][0]["regions"][0]["blocks"][-1].update(target="missing"),
            lambda m: m["flows"][0].update(steps=["saved", "edit"]),
            lambda m: m["flows"].append(copy.deepcopy(m["flows"][0])),
            lambda m: m["screens"][0].update(id="../../unsafe"),
            lambda m: m["screens"][0]["regions"][0]["blocks"][0].update(kind="script"),
            lambda m: m.update(unknown="silent loss"),
            lambda m: m["screens"][0].update(state="ready"),
            lambda m: m.update(pages=["views", "views"]),
            lambda m: m.update(screens=[]),
        ]
        for mutate in mutations:
            with self.subTest(mutation=mutate):
                model = copy.deepcopy(self.model)
                mutate(model)
                with self.assertRaises(ValueError):
                    renderer.validate(model)

    def test_unreachable_and_wrong_type(self):
        other = copy.deepcopy(self.model["screens"][0])
        other["id"] = "unreachable"
        self.model["screens"].append(other)
        with self.assertRaisesRegex(ValueError, "Unreachable"):
            renderer.validate(self.model)
        self.model["screens"].pop()
        self.model["screens"][0]["regions"][0]["blocks"] = ["wrong"]
        with self.assertRaises(ValueError):
            renderer.validate(self.model)

    def test_untrusted_text_is_literal(self):
        self.model["title"] = '</title><script>alert("bad")</script>'
        self.model["screens"][0]["regions"][0]["blocks"][0]["label"] = '<img src="https://external.invalid" onerror="alert(1)">'
        renderer.validate(self.model)
        for render in [renderer.prototype, renderer.svg, renderer.markdown]:
            output = render(self.model)
            self.assertNotIn('<script>alert("bad")', output)
            self.assertNotIn('<img src=', output)
        ET.fromstring(renderer.svg(self.model))

    def test_collision_modified_and_explicit_refresh(self):
        output = self.root / "prototype.html"
        output.write_text("consumer")
        with self.assertRaisesRegex(ValueError, "ownership"):
            renderer.write(self.input, output, "html")
        self.assertEqual(output.read_text(), "consumer")
        output.unlink()
        renderer.write(self.input, output, "html")
        self.model["title"] = "Revised"
        self.save()
        before = output.read_bytes()
        with self.assertRaisesRegex(ValueError, "replace-owned"):
            renderer.write(self.input, output, "html")
        self.assertEqual(before, output.read_bytes())
        renderer.write(self.input, output, "html", True)
        self.assertIn("Revised", output.read_text())
        output.write_text("custom edit")
        with self.assertRaisesRegex(ValueError, "Modified"):
            renderer.write(self.input, output, "html", True)
        self.assertEqual(output.read_text(), "custom edit")

    def test_input_collision_and_symlinks(self):
        with self.assertRaisesRegex(ValueError, "collide"):
            renderer.write(self.input, self.input, "spec")
        link = self.root / "linked.html"
        try:
            link.symlink_to(self.input)
        except OSError:
            self.skipTest("Host does not permit symbolic link creation")
        with self.assertRaisesRegex(ValueError, "Symbolic"):
            renderer.write(self.input, link, "html")

    def test_duplicate_json_fields_refuse_before_writes(self):
        self.input.write_text('{"schema":"one","schema":"two"}')
        output = self.root / "output.html"
        with self.assertRaisesRegex(ValueError, "Duplicate JSON"):
            renderer.write(self.input, output, "html")
        self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
