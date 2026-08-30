#!/usr/bin/env bash
# build-aesthetic-direction.sh — Generate AESTHETIC-DIRECTION.md from sheen
# design values, influence sources, and DTCG tokens.
#
# DESIGN.md (build-design-md.sh) renders mechanical token facts (exact color
# hex values, font sizes, easing curves) for AI design agents. This script is
# additive to that: it renders the *creative direction* narrative — mood,
# color story, type pairing, spacing rhythm, motion character — so a
# downstream team has a single artifact that answers "what should this
# look/feel like" instead of synthesizing it themselves from tokens plus
# docs/design-context.md's review rubric. It intentionally excludes any
# reporting/analytics chart guidance — this is a creative-direction doc, not
# a metrics doc.
#
# Usage:
#   bash scripts/build-aesthetic-direction.sh                      # auto-detect paths
#   bash scripts/build-aesthetic-direction.sh --theme dark         # use dark theme
#   bash scripts/build-aesthetic-direction.sh --out path/AESTHETIC-DIRECTION.md
#   bash scripts/build-aesthetic-direction.sh --check              # validate existing file

set -euo pipefail

THEME="light"
OUT_PATH=""
CHECK=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --theme) THEME="$2"; shift 2 ;;
    --out)   OUT_PATH="$2"; shift 2 ;;
    --check) CHECK=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel)"

if [[ -f "$REPO_ROOT/.sheen/manifest.json" ]]; then
  TOKENS_BASE="$REPO_ROOT/sheen/tokens"
else
  TOKENS_BASE="$REPO_ROOT/tokens"
fi

OUT_PATH="${OUT_PATH:-$REPO_ROOT/AESTHETIC-DIRECTION.md}"
CONTEXT_MD="$REPO_ROOT/docs/design-context.md"

command -v python3 >/dev/null 2>&1 || { echo "build-aesthetic-direction: python3 required"; exit 1; }

THEME_FILE="$TOKENS_BASE/themes/${THEME}.tokens.json"
if [[ ! -f "$THEME_FILE" ]]; then
  echo "build-aesthetic-direction: theme '${THEME}' not found; falling back to light"
  THEME="light"
  THEME_FILE="$TOKENS_BASE/themes/light.tokens.json"
fi

python3 - "$TOKENS_BASE" "$THEME" "$OUT_PATH" "$CONTEXT_MD" "$CHECK" <<'PYEOF'
import json, sys, re
from pathlib import Path
from datetime import date

tokens_base, theme, out_path, context_md_path, check_mode = sys.argv[1:]
check_mode = (check_mode == "true")

def load_json(path):
    p = Path(path)
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))

theme_data  = load_json(f"{tokens_base}/themes/{theme}.tokens.json")
core_type   = load_json(f"{tokens_base}/core/type.tokens.json")
core_color  = load_json(f"{tokens_base}/core/color.tokens.json")
core_motion = load_json(f"{tokens_base}/core/motion.tokens.json")

core_roots = [core_color, core_type]

def get_by_path(obj, path):
    parts = path.split(".")
    node = obj
    for p in parts:
        if isinstance(node, dict):
            node = node.get(p)
        else:
            return None
        if node is None:
            return None
    if isinstance(node, dict):
        return node.get("$value")
    return None

def resolve_alias(val):
    if isinstance(val, list):
        return ", ".join(str(v) for v in val)
    if not isinstance(val, str):
        return str(val) if val is not None else ""
    m = re.fullmatch(r"\{(.+)\}", val.strip())
    if not m:
        return val
    path = m.group(1)
    for root in core_roots:
        v = get_by_path(root, path)
        if v is not None:
            return resolve_alias(v)
    return val

def get_theme_color(key):
    c = theme_data.get("color", {})
    entry = c.get(key, {})
    if not isinstance(entry, dict):
        return ""
    return resolve_alias(entry.get("$value", ""))

def get_core(path):
    for root in core_roots:
        v = get_by_path(root, path)
        if v is not None:
            return resolve_alias(v)
    return ""

primary    = get_theme_color("primary")
accent     = get_theme_color("accent")
background = get_theme_color("background")
foreground = get_theme_color("foreground")
sans = get_core("type.font-family.sans")
mono = get_core("type.font-family.mono")

def duration(key):
    node = core_motion.get("motion", {}).get("duration", {}).get(key, {})
    return node.get("$value", "") if isinstance(node, dict) else ""

normal_duration = duration("normal")
slow_duration   = duration("slow")

def parse_md_table_rows(lines, section_heading):
    rows = []
    in_section = False
    saw_header_sep = False
    heading_re = re.compile(r"^##\s+" + re.escape(section_heading) + r"\s*$")
    for line in lines:
        if heading_re.match(line):
            in_section = True
            saw_header_sep = False
            continue
        if in_section and line.startswith("## "):
            break
        if not in_section:
            continue
        if re.match(r"^\|\s*-", line):
            saw_header_sep = True
            continue
        m = re.match(r"^\|(.+)\|\s*$", line)
        if m:
            cells = [c.strip() for c in m.group(1).split("|")]
            if not saw_header_sep:
                continue
            rows.append(cells)
    return rows

context_lines = Path(context_md_path).read_text(encoding="utf-8").splitlines() if Path(context_md_path).exists() else []
value_rows     = parse_md_table_rows(context_lines, "Design values")
influence_rows = parse_md_table_rows(context_lines, "Influence sources")

def strip_md_bold(s):
    return re.sub(r"\*\*", "", s).strip()

def strip_md_emphasis(s):
    return re.sub(r"\*[^*]*\*", "", s).strip()

mood_rows = "\n".join(
    f"- **{strip_md_bold(r[0])}** — {r[1].strip()}" for r in value_rows if len(r) >= 2
)
influence_lines = "\n".join(
    f"- **{strip_md_emphasis(r[0])}**: {r[1].strip()}" for r in influence_rows if len(r) >= 2
)

today = date.today().isoformat()

def q(v):
    if re.search(r'[\s:#\[\]{}|>&*!,]', v):
        return f'"{v}"'
    return v

fm = "\n".join([
    "name: aesthetic-direction",
    f"theme: {theme}",
    f"generated: {today}",
    f'primary: "{primary}"',
    f'accent: "{accent}"',
    f'background: "{background}"',
    f'foreground: "{foreground}"',
])

doc = f"""---
{fm}
---

## Overview

The creative direction basecoat-sheen suggests for an application, doc site,
or mobile app built on these tokens — mood, color story, type pairing,
spacing rhythm, and motion character. Additive to
`docs/design-context.md` (the review rubric this direction is derived
from); regenerate with `bash scripts/build-aesthetic-direction.sh` or
`pwsh scripts/build-aesthetic-direction.ps1` after any token or
design-values change. This is a creative-direction doc, not a
reporting/analytics doc — it does not cover dashboards, funnels, or metrics
visualizations.

## Mood & personality

{mood_rows}

## Color story

Lead with **`{primary}`** (primary) against **`{background}`**/**`{foreground}`**
for the base surface and text pairing; reserve **`{accent}`** for highlights,
premium moments, and tertiary actions — not for default UI chrome. Keep color
usage restrained: color should signal state or hierarchy, not decorate.

## Type pairing

Pair **{sans}** for all UI text (headings through captions) with **{mono}** for
code and tabular/technical values only. Do not introduce a third typeface —
consistency across the type scale is part of the `Familiar` value below.

## Spacing rhythm

A 4px base grid drives a calm, predictable rhythm: dense enough for
information-heavy screens, generous enough that touch targets and reading
lines don't feel cramped. Favor the semantic spacing roles over raw scale
values so rhythm stays consistent as components compose.

## Motion character

Motion is quiet by default (normal transitions ~`{normal_duration}`, slower
orchestration ~`{slow_duration}`) — it confirms cause and effect, it never
performs. Prefer ease-out entrances and avoid gratuitous overshoot outside of
explicitly playful, low-stakes moments.

## Influences

{influence_lines}

## Anti-goals

- Do not add reporting/analytics visual language (charts, dashboards,
  funnels) to this direction — that is a reporting concern, not a creative
  direction, and is handled elsewhere.
- Do not introduce a visual language that contradicts
  `docs/design-context.md`'s named values or influence sources without
  updating that file first — this document is derived from it, not a
  parallel source of truth.
"""

if check_mode:
    if not Path(out_path).exists():
        print("::error::AESTHETIC-DIRECTION.md missing — run: bash scripts/build-aesthetic-direction.sh")
        sys.exit(1)
    existing = Path(out_path).read_text(encoding="utf-8")
    existing_fm = existing.split("## Overview")[0]
    generated_fm = doc.split("## Overview")[0]
    if existing_fm.strip() != generated_fm.strip():
        print("::error::AESTHETIC-DIRECTION.md front matter is out of date. Run: bash scripts/build-aesthetic-direction.sh")
        sys.exit(1)
    print("build-aesthetic-direction: AESTHETIC-DIRECTION.md front matter OK")
    sys.exit(0)

Path(out_path).write_text(doc.lstrip("\n"), encoding="utf-8")
print(f"build-aesthetic-direction: wrote AESTHETIC-DIRECTION.md ({theme} theme) -> {out_path}")
PYEOF
