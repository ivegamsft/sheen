#!/usr/bin/env python3
"""Render validated wireframe models as Markdown, static SVG or offline HTML."""
import argparse
import base64
import hashlib
import html
import json
import re
import stat
import sys
import textwrap
from pathlib import Path

ID = re.compile(r"[A-Za-z][A-Za-z0-9_-]{0,63}")


def fields(value, names, context):
    if not isinstance(value, dict) or set(value) != set(names):
        raise ValueError(f"{context}: expected fields {', '.join(names)}")


def text(value, context):
    if not isinstance(value, str) or not value.strip() or len(value) > 2000:
        raise ValueError(f"{context}: expected nonempty text up to 2000 characters")
    if any(ord(c) < 32 and c not in "\n\t" for c in value):
        raise ValueError(f"{context}: control characters are not supported")


def identifier(value):
    if not isinstance(value, str) or not ID.fullmatch(value):
        raise ValueError(f"Invalid identifier: {value!r}")


def nonempty_list(value, context):
    if not isinstance(value, list) or not value:
        raise ValueError(f"{context}: expected nonempty list")


def validate(model):
    fields(model, ["schema", "title", "start", "pages", "screens", "flows"], "model")
    if model["schema"] != "sheen-wireframes/v1":
        raise ValueError("Unsupported wireframe schema")
    text(model["title"], "title")
    identifier(model["start"])
    nonempty_list(model["pages"], "pages")
    for page in model["pages"]:
        identifier(page)
    if len(set(model["pages"])) != len(model["pages"]):
        raise ValueError("Duplicate page ID")
    nonempty_list(model["screens"], "screens")
    screens = {}
    edges = {}
    for screen in model["screens"]:
        fields(screen, ["id", "page", "title", "state", "annotations", "regions"], "screen")
        identifier(screen["id"])
        identifier(screen["page"])
        text(screen["title"], "screen title")
        if screen["id"] in screens:
            raise ValueError("Duplicate screen ID")
        if screen["page"] not in model["pages"]:
            raise ValueError("Unresolved page ID")
        if screen["state"] not in ["default", "empty", "loading", "error", "success"]:
            raise ValueError("Unsupported state")
        if not isinstance(screen["annotations"], list):
            raise ValueError("annotations: expected list")
        for note in screen["annotations"]:
            text(note, "annotation")
        nonempty_list(screen["regions"], "regions")
        targets = set()
        for region in screen["regions"]:
            fields(region, ["label", "blocks"], "region")
            text(region["label"], "region label")
            nonempty_list(region["blocks"], "blocks")
            for block in region["blocks"]:
                if not isinstance(block, dict):
                    raise ValueError("block: expected object")
                kind = block.get("kind")
                if kind not in ["text", "input", "placeholder", "action"]:
                    raise ValueError("Unsupported block kind")
                fields(block, ["kind", "label", "target"] if kind == "action" else ["kind", "label"], "block")
                text(block["label"], "block label")
                if kind == "action":
                    identifier(block["target"])
                    targets.add(block["target"])
        screens[screen["id"]] = screen
        edges[screen["id"]] = targets
    if model["start"] not in screens:
        raise ValueError("Unresolved start screen")
    if any(target not in screens for targets in edges.values() for target in targets):
        raise ValueError("Unresolved action target")
    reached, pending = set(), [model["start"]]
    while pending:
        screen = pending.pop()
        if screen not in reached:
            reached.add(screen)
            pending.extend(edges[screen] - reached)
    if reached != set(screens):
        raise ValueError("Unreachable screen")
    nonempty_list(model["flows"], "flows")
    flow_ids = set()
    for flow in model["flows"]:
        fields(flow, ["id", "steps"], "flow")
        identifier(flow["id"])
        if flow["id"] in flow_ids:
            raise ValueError("Duplicate flow ID")
        flow_ids.add(flow["id"])
        nonempty_list(flow["steps"], "flow steps")
        for step in flow["steps"]:
            identifier(step)
            if step not in screens:
                raise ValueError("Unresolved flow screen")
        if any(b not in edges[a] for a, b in zip(flow["steps"], flow["steps"][1:])):
            raise ValueError("Flow edge has no action")


def escaped(value):
    return html.escape(value, quote=True)


def markdown(model):
    lines = [f"# {escaped(model['title'])}", "", "> LOW-FIDELITY PROTOTYPE - not production UI.", "",
             f"Start: `{model['start']}`. Regions stack in source order at all widths.", ""]
    for screen in model["screens"]:
        lines += [f"## {escaped(screen['title'])}", "",
                  f"Screen `{screen['id']}` / page `{screen['page']}` / state `{screen['state']}`", ""]
        for region in screen["regions"]:
            lines += [f"### {escaped(region['label'])}", ""]
            for block in region["blocks"]:
                target = f" -> `{block['target']}`" if block["kind"] == "action" else ""
                lines.append(f"- **{block['kind']}**: {escaped(block['label'])}{target}")
        lines += ["", "Annotations:"] + [f"- {escaped(note)}" for note in screen["annotations"]] + [""]
    lines += ["## Flows", ""] + [
        f"- `{flow['id']}`: " + " -> ".join(f"`{step}`" for step in flow["steps"]) for flow in model["flows"]
    ]
    lines += ["", "## Review", "", "Verify state omissions, keyboard/task paths, content priority and responsive order before handoff."]
    return "\n".join(lines) + "\n"


def svg(model):
    parts, y = [], 70
    def label(value, x, top, size=16):
        parts.append(f'<text x="{x}" y="{top}" font-size="{size}">{escaped(value)}</text>')
    def wrapped(value, x, top, width=68):
        for line in textwrap.wrap(value, width=width, break_long_words=True) or [""]:
            label(line, x, top)
            top += 22
        return top
    label("LOW-FIDELITY STORYBOARD - static, not clickable", 24, 28)
    y = wrapped(model["title"], 24, y, 70) + 16
    for screen in model["screens"]:
        start = y
        y = wrapped(f"{screen['id']} / {screen['page']} / {screen['state']}: {screen['title']}", 40, y + 28)
        for region in screen["regions"]:
            y = wrapped(region["label"], 48, y + 18)
            for block in region["blocks"]:
                caption = f"{block['kind']}: {block['label']}"
                if block["kind"] == "action":
                    caption += f" -> {block['target']}"
                top = y + 6
                y = wrapped(caption, 60, y + 28, 62) + 10
                parts.append(f'<path d="M48 {top} L747 {top+1} L748 {y} L49 {y+1} Z" fill="none" stroke="#555" stroke-dasharray="5 2"/>')
            y += 12
        for note in screen["annotations"]:
            y = wrapped("Note: " + note, 48, y + 16, 64)
        y += 24
        parts.append(f'<path d="M24 {start} L776 {start+2} L775 {y} L25 {y+1} Z" fill="none" stroke="#222" stroke-width="2"/>')
        y += 30
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="800" height="{y}" viewBox="0 0 800 {y}" role="img" aria-labelledby="title desc">'
        f'<title id="title">{escaped(model["title"])}</title>'
        '<desc id="desc">Static sketch board. Screens, states, control destinations and annotations are shown in reading order.</desc>'
        '<rect width="100%" height="100%" fill="white"/><g fill="#222" font-family="monospace">'
        + "".join(parts) + "</g></svg>\n"
    )


SCRIPT = """'use strict';
const screens=Array.from(document.querySelectorAll('[data-screen]'));
const start=document.body.dataset.start;
const back=document.getElementById('back');
const error=document.getElementById('route-error');
let stack=[];
function show(id,push){
 const next=screens.find(s=>s.dataset.screen===id);
 if(!next){error.hidden=false;error.focus();return;}
 error.hidden=true;
 const current=screens.find(s=>!s.hidden);
 if(push&&current&&current!==next)stack.push(current.dataset.screen);
 screens.forEach(s=>s.hidden=s!==next);
 history.replaceState(null,'','#'+id);
 back.disabled=stack.length===0;
 next.querySelector('h2').focus();
}
document.querySelectorAll('[data-target]').forEach(a=>a.addEventListener('click',e=>{
 e.preventDefault();show(a.dataset.target,true);
}));
back.addEventListener('click',()=>{if(stack.length)show(stack.pop(),false);});
document.getElementById('reset').addEventListener('click',()=>{
 stack=[];document.querySelectorAll('input').forEach(i=>i.value='');show(start,false);
});
function route(){let id;try{id=decodeURIComponent(location.hash.slice(1));}
 catch(e){error.hidden=false;error.focus();return;}show(id||start,false);}
window.addEventListener('hashchange',route);
route();
"""


def prototype(model):
    panels = []
    for index, screen in enumerate(model["screens"]):
        regions = []
        for r, region in enumerate(screen["regions"]):
            blocks = []
            for b, block in enumerate(region["blocks"]):
                label = escaped(block["label"])
                if block["kind"] == "action":
                    blocks.append(f'<a class="action" href="#{block["target"]}" data-target="{block["target"]}">{label}</a>')
                elif block["kind"] == "input":
                    key = f"input-{index}-{r}-{b}"
                    blocks.append(f'<label for="{key}">{label}</label><input id="{key}" autocomplete="off" placeholder="Sample only">')
                elif block["kind"] == "placeholder":
                    blocks.append(f'<div class="placeholder">[ {label} ]</div>')
                else:
                    blocks.append(f'<p>{label}</p>')
            regions.append(f'<section class="region"><h3>{escaped(region["label"])}</h3>{"".join(blocks)}</section>')
        panels.append(
            f'<section id="screen-{screen["id"]}" data-screen="{screen["id"]}" hidden><h2 tabindex="-1">{escaped(screen["title"])}</h2>'
            f'<p>Screen: {screen["id"]} | Page: {screen["page"]} | State: {screen["state"]}</p>'
            + "".join(regions) + '<aside aria-label="Wireframe annotations"><ul>'
            + "".join(f"<li>{escaped(note)}</li>" for note in screen["annotations"]) + "</ul></aside></section>"
        )
    sha = base64.b64encode(hashlib.sha256(SCRIPT.encode()).digest()).decode()
    csp = f"default-src 'none'; style-src 'unsafe-inline'; script-src 'sha256-{sha}'; connect-src 'none'; form-action 'none'; base-uri 'none'"
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="{escaped(csp)}">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{escaped(model['title'])}</title>
<style>
*{{box-sizing:border-box}}body{{font-family:system-ui,sans-serif;color:#222;background:#fff;margin:0;padding:1rem;overflow-wrap:anywhere}}
header,main,footer{{max-width:52rem;margin:auto}}h1{{font-size:1.5rem}}h2{{font-size:1.3rem}}
.region{{border:2px dashed #555;padding:1rem;margin:1rem 0}}.placeholder{{border:1px dashed;padding:2rem;margin:1rem 0}}
input{{display:block;width:100%;font:inherit;padding:.7rem;margin:.5rem 0}}button,.action{{font:inherit;display:inline-block;color:#222;background:white;border:2px solid;padding:.7rem;margin:.3rem;min-height:44px}}
:focus-visible{{outline:3px solid #111;outline-offset:3px}}[hidden]{{display:none!important}}
@media(max-width:400px){{.action{{display:block;margin:.5rem 0}}body{{padding:.6rem}}}}
</style></head><body data-start="{model['start']}">
<header><p><strong>LOW-FIDELITY PROTOTYPE - not production UI</strong></p><h1>{escaped(model['title'])}</h1>
<p>Offline simulation. Inputs are sample-only; nothing is submitted or stored. Regions stack in reading order.</p></header>
<main><p id="route-error" role="alert" tabindex="-1" hidden>Unknown screen. Use Reset to recover.</p>
<noscript>This click-through requires JavaScript. Use the screen specification or SVG for static review.</noscript>
{''.join(panels)}</main>
<footer><button id="back" type="button" disabled>Back</button><button id="reset" type="button">Reset prototype</button></footer>
<script>{SCRIPT}</script></body></html>
"""


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def safe_path(path):
    for item in [path, *path.parents]:
        attributes = getattr(item.lstat(), "st_file_attributes", 0) if item.exists() or item.is_symlink() else 0
        if item.is_symlink() or attributes & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400):
            raise ValueError(f"Symbolic link/junction output path: {item}")

def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON field: {key}")
        result[key] = value
    return result


def write(model_path, output, format_name, replace_owned=False):
    safe_path(output)
    sidecar = output.with_name(output.name + ".sheen-wireframe.json")
    safe_path(sidecar)
    if not output.parent.is_dir() or output.resolve() == model_path.resolve() or sidecar.resolve() == model_path.resolve():
        raise ValueError("Output needs an existing parent and must not collide with input")
    raw = model_path.read_bytes()
    model = json.loads(raw, object_pairs_hook=unique_object)
    validate(model)
    content = {"spec": markdown, "svg": svg, "html": prototype}[format_name](model).encode("utf-8")
    evidence = {"schema": "sheen-wireframe-output/v1", "format": format_name,
                "input_sha256": sha256(raw), "output_sha256": sha256(content)}
    metadata = (json.dumps(evidence, indent=2) + "\n").encode()
    if output.exists() or sidecar.exists():
        if not output.is_file() or not sidecar.is_file():
            raise ValueError("Output collision or missing ownership evidence")
        previous = json.loads(sidecar.read_bytes(), object_pairs_hook=unique_object)
        fields(previous, ["schema", "format", "input_sha256", "output_sha256"], "ownership")
        if previous["schema"] != evidence["schema"] or previous["format"] != format_name or previous["output_sha256"] != sha256(output.read_bytes()):
            raise ValueError("Modified or unrecognized owned output")
        if output.read_bytes() == content and sidecar.read_bytes() == metadata:
            return "unchanged"
        if not replace_owned:
            raise ValueError("Refresh requires --replace-owned")
    # All collision and ownership checks complete before either output is written.
    output.write_bytes(content)
    sidecar.write_bytes(metadata)
    return "written"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--format", choices=["spec", "svg", "html"], default="spec")
    parser.add_argument("--replace-owned", action="store_true")
    args = parser.parse_args()
    try:
        print(write(args.input, args.output, args.format, args.replace_owned))
    except (ValueError, OSError) as error:
        print(f"wireframing: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
