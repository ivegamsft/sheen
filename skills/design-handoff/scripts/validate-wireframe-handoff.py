#!/usr/bin/env python3
"""Read-only checks for optional wireframes in the reference blueprint shape."""
import argparse
import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path


def load_validator():
    path = Path(__file__).resolve().parents[2] / "wireframing" / "scripts" / "render-wireframes.py"
    if not path.is_file():
        raise ValueError("Sync the sibling wireframing skill for model validation")
    spec = importlib.util.spec_from_file_location("handoff_wireframes", path)
    module = importlib.util.module_from_spec(spec)
    previous = sys.dont_write_bytecode
    try:
        sys.dont_write_bytecode = True
        spec.loader.exec_module(module)
    finally:
        sys.dont_write_bytecode = previous
    return module


def indexed(items, context, validator, safe_ids=True):
    validator.nonempty_list(items, context)
    result = {}
    for item in items:
        if not isinstance(item, dict):
            raise ValueError(f"{context}: expected objects")
        identifier = item.get("id")
        if safe_ids:
            validator.identifier(identifier)
        else:
            validator.text(identifier, context + " ID")
        if identifier in result:
            raise ValueError(f"{context}: duplicate ID")
        result[identifier] = item
    return result


def model_digest(model):
    canonical = json.dumps(model, sort_keys=True, ensure_ascii=True, separators=(",", ":"))
    return "sha256:" + hashlib.sha256(canonical.encode("ascii")).hexdigest()


def validate(blueprint, validator, original_models=None):
    if not isinstance(blueprint, dict) or blueprint.get("mode") not in ["audit", "generate"]:
        raise ValueError("Expected an audit or generate reference blueprint")
    if "wireframes" not in blueprint:
        return []
    if not original_models:
        raise ValueError("Attached handoff requires separately supplied approved original model baseline(s)")
    for original in original_models:
        validator.validate(original)
    pages = indexed(blueprint.get("pages"), "blueprint pages", validator, safe_ids=False)
    flows = indexed(blueprint.get("flows"), "blueprint flows", validator, safe_ids=False)
    attachments = indexed(blueprint["wireframes"], "wireframes", validator, safe_ids=False)
    if len(original_models) != len(attachments):
        raise ValueError("Supply one approved original model baseline per attachment")
    unmatched_originals = list(original_models)
    used = set()
    for collection in ["pages", "flows", "layouts", "evidence", "findings"]:
        items = blueprint.get(collection, [])
        if not isinstance(items, list) or any(not isinstance(item, dict) for item in items):
            raise ValueError(f"blueprint {collection}: expected object list")
        for item in items:
            identifier = item.get("id")
            validator.text(identifier, collection + " ID")
            if identifier in used:
                raise ValueError("Duplicate blueprint artifact ID")
            used.add(identifier)
    results = []
    for attachment in attachments.values():
        validator.fields(attachment, ["id", "source", "baseline", "model", "screens", "flows",
                                     "states", "simulated", "limitations", "review"], "wireframe attachment")
        validator.text(attachment["source"], "prototype provenance")
        model = attachment["model"]
        validator.validate(model)
        if model not in unmatched_originals:
            raise ValueError("Embedded model differs from approved original model baseline; IDs/source behavior must remain unchanged")
        original = unmatched_originals[unmatched_originals.index(model)]
        provenance = attachment["baseline"]
        validator.fields(provenance, ["revision", "approvalEvidence", "digest"], "baseline provenance")
        revision = provenance["revision"]
        if not isinstance(revision, str) or not re.fullmatch(r"(?:git:[0-9a-f]{40}|git:[0-9a-f]{64}|sha256:[0-9a-f]{64})", revision):
            raise ValueError("Baseline revision must be an immutable git commit or sha256 content revision")
        validator.nonempty_list(provenance["approvalEvidence"], "baseline approval evidence")
        for evidence in provenance["approvalEvidence"]:
            validator.text(evidence, "baseline approval evidence")
        digest = model_digest(original)
        if provenance["digest"] != digest:
            raise ValueError("Baseline digest does not match independently supplied original")
        if revision.startswith("sha256:") and revision != digest:
            raise ValueError("Baseline content revision does not match independently supplied original")
        unmatched_originals.remove(model)
        if attachment["id"] in used:
            raise ValueError("Duplicate attachment artifact ID")
        used.add(attachment["id"])
        if not set(model["pages"]) <= pages.keys():
            raise ValueError("Model page IDs must resolve unchanged in the blueprint")
        if attachment["simulated"] is not True:
            raise ValueError("Prototype behavior must remain explicitly simulated")
        validator.fields(attachment["limitations"], ["simulation", "responsive", "accessibility", "scope"], "limitations")
        for note in attachment["limitations"].values():
            validator.text(note, "limitation")
        screen_maps = indexed(attachment["screens"], "screen mappings", validator)
        if set(screen_maps) != {s["id"] for s in model["screens"]}:
            raise ValueError("Screen mappings must preserve every model screen ID")
        for screen in model["screens"]:
            mapping = screen_maps[screen["id"]]
            validator.fields(mapping, ["id", "target", "components", "controls"], "screen mapping")
            validator.text(mapping["target"], "implementation destination")
            validator.nonempty_list(mapping["components"], "component/spec references")
            for reference in mapping["components"]:
                validator.text(reference, "component/spec reference")
            page_states = pages[screen["page"]].get("states")
            if not isinstance(page_states, dict) or not page_states.get(screen["state"]) or page_states[screen["state"]] == "not-applicable":
                raise ValueError("Modeled state must resolve to an applicable blueprint page state")
            expected = {(r, b) for r, region in enumerate(screen["regions"])
                        for b, block in enumerate(region["blocks"]) if block["kind"] in ["input", "action"]}
            controls = mapping["controls"]
            if not isinstance(controls, list):
                raise ValueError("controls: expected list")
            actual = set()
            for control in controls:
                validator.fields(control, ["region", "block", "behavior", "dependencies", "limitations"], "control mapping")
                if any(type(control[key]) is not int for key in ["region", "block"]):
                    raise ValueError("Control positions must be integer indices")
                position = (control["region"], control["block"])
                if position not in expected or position in actual:
                    raise ValueError("Invalid or duplicate control position")
                actual.add(position)
                for key in ["behavior", "limitations"]:
                    validator.text(control[key], key)
                validator.nonempty_list(control["dependencies"], "control dependencies")
                for dependency in control["dependencies"]:
                    validator.text(dependency, "dependency (or reasoned not-applicable)")
            if actual != expected:
                raise ValueError("Every mock input/action needs an explicit production mapping")
        validator.fields(attachment["states"], model["pages"], "omitted states by page")
        for page in model["pages"]:
            present = {s["state"] for s in model["screens"] if s["page"] == page}
            required = set(pages[page]["states"]) | {"default", "loading", "empty", "error", "success", "permission"}
            validator.fields(attachment["states"][page], required - present, "omitted state reasons")
            for reason in attachment["states"][page].values():
                validator.text(reason, "omitted state reason")
        flow_maps = indexed(attachment["flows"], "flow mappings", validator)
        if set(flow_maps) != {f["id"] for f in model["flows"]}:
            raise ValueError("Flow mappings must preserve every model flow ID")
        screens = {s["id"]: s for s in model["screens"]}
        for flow in model["flows"]:
            mapping = flow_maps[flow["id"]]
            validator.fields(mapping, ["id", "steps", "target", "limitations"], "flow mapping")
            for key in ["target", "limitations"]:
                validator.text(mapping[key], key)
            if flow["id"] not in flows:
                raise ValueError("Model flow ID must resolve unchanged in the blueprint")
            steps = mapping["steps"]
            if not isinstance(steps, list) or len(steps) != len(flow["steps"]):
                raise ValueError("Every prototype flow step needs a blueprint step index")
            blueprint_steps = flows[flow["id"]].get("steps")
            if not isinstance(blueprint_steps, list):
                raise ValueError("Blueprint flow steps must be a list")
            previous = -1
            for screen_id, index in zip(flow["steps"], steps):
                if type(index) is not int or index < previous or not 0 <= index < len(blueprint_steps):
                    raise ValueError("Flow indices must resolve in blueprint order")
                if not isinstance(blueprint_steps[index], dict) or blueprint_steps[index].get("page") != screens[screen_id]["page"]:
                    raise ValueError("Flow step page does not match its original screen")
                previous = index
        review = attachment["review"]
        validator.fields(review, ["status", "evidence"], "visual/task review")
        if review["status"] not in ["pending", "reviewed"] or not isinstance(review["evidence"], list):
            raise ValueError("Review must be pending or reviewed with an evidence list")
        if review["status"] == "reviewed":
            validator.nonempty_list(review["evidence"], "visual/task review evidence")
        for evidence in review["evidence"]:
            validator.text(evidence, "review evidence")
        results.append((attachment["id"], review["status"]))
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--original-model", action="append", type=Path, default=[],
                        help="Approved original v1 model from an independent immutable revision; repeat per attachment")
    args = parser.parse_args()
    try:
        validator = load_validator()
        blueprint = json.loads(args.input.read_bytes(), object_pairs_hook=validator.unique_object)
        if any(path.resolve() == args.input.resolve() for path in args.original_model):
            raise ValueError("Original model baseline must be supplied separately from the handoff")
        originals = [json.loads(path.read_bytes(), object_pairs_hook=validator.unique_object)
                     for path in args.original_model]
        results = validate(blueprint, validator, originals)
        print(f"Structural handoff checks passed: {len(results)} attachment(s).")
        for identifier, status in results:
            print(f"{identifier}: visual/task review {status}; no production approval or write authorization.")
        return 0
    except (ValueError, TypeError, KeyError, OSError) as error:
        print(f"Handoff blocked: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
