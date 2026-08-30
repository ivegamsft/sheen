#!/usr/bin/env bash
# build-design-md.sh — Generate DESIGN.md (Stitch/Google format) from sheen DTCG tokens
#
# Usage:
#   bash scripts/build-design-md.sh                      # auto-detect paths
#   bash scripts/build-design-md.sh --theme dark         # use dark theme
#   bash scripts/build-design-md.sh --out path/DESIGN.md # custom output path
#   bash scripts/build-design-md.sh --check              # validate existing file

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

OUT_PATH="${OUT_PATH:-$REPO_ROOT/DESIGN.md}"

command -v python3 >/dev/null 2>&1 || { echo "build-design-md: python3 required"; exit 1; }

THEME_FILE="$TOKENS_BASE/themes/${THEME}.tokens.json"
if [[ ! -f "$THEME_FILE" ]]; then
  echo "build-design-md: theme '${THEME}' not found; falling back to light"
  THEME="light"
  THEME_FILE="$TOKENS_BASE/themes/light.tokens.json"
fi

CORE_TYPE_FILE="$TOKENS_BASE/core/type.tokens.json"
CORE_RADIUS_FILE="$TOKENS_BASE/core/radius.tokens.json"
CORE_SPACE_FILE="$TOKENS_BASE/core/space.tokens.json"

PRODUCT_MD="$REPO_ROOT/PRODUCT.md"
VERSION_FILE="$REPO_ROOT/version.json"

python3 - "$TOKENS_BASE" "$THEME" "$OUT_PATH" "$PRODUCT_MD" "$VERSION_FILE" "$CHECK" <<'PYEOF'
import json, sys, os, re
from pathlib import Path
from datetime import date

tokens_base, theme, out_path, product_md_path, version_file, check_mode = sys.argv[1:]
check_mode = (check_mode == "true")

def load_json(path):
    p = Path(path)
    if not p.exists():
        return {}
    return json.loads(p.read_text(encoding="utf-8"))

theme_data    = load_json(f"{tokens_base}/themes/{theme}.tokens.json")
core_type     = load_json(f"{tokens_base}/core/type.tokens.json")
core_radius   = load_json(f"{tokens_base}/core/radius.tokens.json")
core_space    = load_json(f"{tokens_base}/core/space.tokens.json")
core_color    = load_json(f"{tokens_base}/core/color.tokens.json")
core_motion   = load_json(f"{tokens_base}/core/motion.tokens.json")
core_elevation = load_json(f"{tokens_base}/core/elevation.tokens.json")

core_roots = [core_color, core_type, core_radius, core_space]

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
    if not isinstance(val, str):
        return str(val) if val is not None else ""
    m = re.fullmatch(r"\{(.+)\}", val.strip())
    if not m:
        return val
    path = m.group(1)
    for root in core_roots:
        v = get_by_path(root, path)
        if v is not None:
            return resolve_alias(str(v))
    return val  # unresolved

def get_theme_color(key):
    c = theme_data.get("color", {})
    entry = c.get(key, {})
    if not isinstance(entry, dict):
        return ""
    raw = entry.get("$value", "")
    return resolve_alias(raw)

def get_core(path):
    for root in core_roots:
        v = get_by_path(root, path)
        if v is not None:
            return resolve_alias(str(v))
    return ""

sans = get_core("type.font-family.sans")
mono = get_core("type.font-family.mono")

def size(k): return get_core(f"type.font-size.{k}")

colors_map = {
    "primary":    get_theme_color("primary"),
    "secondary":  get_theme_color("secondary"),
    "background": get_theme_color("background"),
    "foreground": get_theme_color("foreground"),
    "muted":      get_theme_color("muted"),
    "border":     get_theme_color("border"),
    "error":      get_theme_color("error"),
    "success":    get_theme_color("success"),
    "warning":    get_theme_color("warning"),
    "accent":     get_theme_color("accent"),
}

typography = {
    "h1":      {"fontFamily": sans, "fontSize": size("4xl"), "fontWeight": "600"},
    "h2":      {"fontFamily": sans, "fontSize": size("3xl"), "fontWeight": "600"},
    "h3":      {"fontFamily": sans, "fontSize": size("2xl"), "fontWeight": "600"},
    "body":    {"fontFamily": sans, "fontSize": size("lg"),  "fontWeight": "400"},
    "body-sm": {"fontFamily": sans, "fontSize": size("md"),  "fontWeight": "400"},
    "label":   {"fontFamily": sans, "fontSize": size("md"),  "fontWeight": "500"},
    "caption": {"fontFamily": sans, "fontSize": size("sm"),  "fontWeight": "400"},
    "code":    {"fontFamily": mono, "fontSize": size("md"),  "fontWeight": "400"},
}

rounded = {
    "none": resolve_alias("{radius.none}"),
    "sm":   resolve_alias("{radius.small}"),
    "md":   resolve_alias("{radius.medium}"),
    "lg":   resolve_alias("{radius.large}"),
    "pill": resolve_alias("{radius.full}"),
}

spacing = {
    "xs": resolve_alias("{space.1}"),
    "sm": resolve_alias("{space.2}"),
    "md": resolve_alias("{space.4}"),
    "lg": resolve_alias("{space.6}"),
    "xl": resolve_alias("{space.8}"),
}

def duration(key):
    node = core_motion.get("motion", {}).get("duration", {}).get(key, {})
    return node.get("$value", "") if isinstance(node, dict) else ""

def easing(key):
    node = core_motion.get("motion", {}).get("easing", {}).get(key, {})
    val = node.get("$value") if isinstance(node, dict) else None
    if isinstance(val, list) and len(val) == 4:
        return "cubic-bezier({}, {}, {}, {})".format(*val)
    return ""

motion_duration = {k: duration(k) for k in ["instant", "fast", "normal", "moderate", "slow", "deliberate"]}
motion_easing = {k: easing(k) for k in ["linear", "ease-in", "ease-out", "ease-in-out", "spring"]}

def elevation_shadow(level):
    node = core_elevation.get("elevation", {}).get(level, {})
    val = node.get("$value") if isinstance(node, dict) else None
    if not isinstance(val, dict):
        return "", ""
    desc = node.get("$description", "")
    if val.get("blur") == "0px" and val.get("color", "").startswith("rgba(0,0,0,0)"):
        return "none", desc
    css = f'{val.get("offsetX","0px")} {val.get("offsetY","0px")} {val.get("blur","0px")} {val.get("spread","0px")} {val.get("color","")}'
    return css, desc

elevation_levels = {lvl: elevation_shadow(lvl) for lvl in ["0", "1", "2", "3", "4", "5"]}

product_name = "basecoat-sheen"
if Path(version_file).exists():
    vj = json.loads(Path(version_file).read_text(encoding="utf-8"))
    if vj.get("name"):
        product_name = vj["name"]

overview = f"Design token system for {product_name}. Generated from DTCG tokens by basecoat-sheen."
if Path(product_md_path).exists():
    lines = Path(product_md_path).read_text(encoding="utf-8").splitlines()
    in_section = False
    for line in lines:
        if re.match(r'^## Product Purpose', line):
            in_section = True
            continue
        if in_section and re.match(r'^## ', line):
            break
        if in_section and line.strip() and not line.startswith('#'):
            overview = line.strip()
            break

def q(v):
    if re.search(r'[\s:#\[\]{}|>&*!,]', v):
        return f'"{v}"'
    return v

lines_fm = [
    f"name: {q(product_name)}",
    f"theme: {theme}",
    "colors:",
]
for k, v in colors_map.items():
    if v:
        lines_fm.append(f'  {k}: "{v}"')
lines_fm.append("typography:")
for k, t in typography.items():
    lines_fm.append(f"  {k}:")
    for p, v in t.items():
        lines_fm.append(f"    {p}: {q(v)}")
lines_fm.append("rounded:")
for k, v in rounded.items():
    if v:
        lines_fm.append(f"  {k}: {q(v)}")
lines_fm.append("spacing:")
for k, v in spacing.items():
    if v:
        lines_fm.append(f"  {k}: {q(v)}")
lines_fm.append("motion:")
lines_fm.append("  duration:")
for k, v in motion_duration.items():
    if v:
        lines_fm.append(f"    {k}: {q(v)}")
lines_fm.append("  easing:")
for k, v in motion_easing.items():
    if v:
        lines_fm.append(f"    {k}: {q(v)}")
lines_fm.append("elevation:")
for lvl, (css, _desc) in elevation_levels.items():
    if css:
        lines_fm.append(f'  "{lvl}": {q(css)}')

fm = "\n".join(lines_fm)

today = date.today().isoformat()

def row(role, value, use):
    return f"| {role} | `{value}` | {use} |"

color_rows = "\n".join([
    row("primary",    colors_map["primary"],    "Primary actions, links, focus rings"),
    row("secondary",  colors_map["secondary"],  "Secondary surfaces, cards"),
    row("background", colors_map["background"], "Page / canvas background"),
    row("foreground", colors_map["foreground"], "Primary text, icons"),
    row("muted",      colors_map["muted"],      "Secondary text, captions, placeholders"),
    row("border",     colors_map["border"],     "Dividers, input borders"),
    row("error",      colors_map["error"],      "Error states, destructive actions"),
    row("success",    colors_map["success"],    "Confirmation, success states"),
    row("warning",    colors_map["warning"],    "Caution, degraded states"),
    row("accent",     colors_map["accent"],     "Highlight, premium, tertiary actions"),
])

duration_use = {
    "instant": "No-op / immediate state changes",
    "fast": "Micro-interactions (icon swap, toggle)",
    "normal": "Default transition (hover, focus)",
    "moderate": "Component enter/exit (dropdown, tooltip)",
    "slow": "Page transitions, sheet slide-in",
    "deliberate": "Full-screen or complex orchestration",
}
duration_rows = "\n".join([
    f"| {k} | `{v}` | {duration_use[k]} |"
    for k, v in motion_duration.items() if v
])

easing_use = {
    "linear": "No easing — progress bars, loaders",
    "ease-in": "Elements leaving the screen",
    "ease-out": "Elements entering the screen (default)",
    "ease-in-out": "Elements moving across the screen",
    "spring": "Playful overshoot for expressive moments",
}
easing_rows = "\n".join([
    f"| {k} | `{v}` | {easing_use[k]} |"
    for k, v in motion_easing.items() if v
])

elevation_use = {
    "0": "Flat — no elevation",
    "1": "Subtle lift — cards at rest",
    "2": "Cards on hover, dropdowns",
    "3": "Popovers, tooltips",
    "4": "Modals, dialogs",
    "5": "Full-screen overlays, sheets",
}
elevation_rows = "\n".join([
    f"| {lvl} | `{css}` | {elevation_use[lvl]} |"
    for lvl, (css, _desc) in elevation_levels.items() if css
])

t = typography
design_md = f"""---
{fm}
---

## Overview

{overview}

Generated from DTCG tokens by basecoat-sheen on {today}. Theme: `{theme}`.
Do not hand-edit — regenerate with `bash scripts/build-design-md.sh` or `pwsh scripts/build-design-md.ps1`.


## Colors

| Role | Value | Use |
|------|-------|-----|
{color_rows}

All pairs validated at WCAG 2.2 AA (4.5:1 text / 3:1 large). Theme: `{theme}`.

## Typography

| Role | Family | Size | Weight |
|------|--------|------|--------|
| h1 | sans | {t["h1"]["fontSize"]} | {t["h1"]["fontWeight"]} |
| h2 | sans | {t["h2"]["fontSize"]} | {t["h2"]["fontWeight"]} |
| h3 | sans | {t["h3"]["fontSize"]} | {t["h3"]["fontWeight"]} |
| body | sans | {t["body"]["fontSize"]} | {t["body"]["fontWeight"]} |
| body-sm | sans | {t["body-sm"]["fontSize"]} | {t["body-sm"]["fontWeight"]} |
| label | sans | {t["label"]["fontSize"]} | {t["label"]["fontWeight"]} |
| caption | sans | {t["caption"]["fontSize"]} | {t["caption"]["fontWeight"]} |
| code | mono | {t["code"]["fontSize"]} | {t["code"]["fontWeight"]} |

Sans: `{sans}`
Mono: `{mono}`

## Spacing

4px base grid. Use semantic spacing roles in components; raw scale for layout only.

| Token | Value |
|-------|-------|
| xs | {spacing["xs"]} |
| sm | {spacing["sm"]} |
| md | {spacing["md"]} |
| lg | {spacing["lg"]} |
| xl | {spacing["xl"]} |

## Corner Radius

| Token | Value | Use |
|-------|-------|-----|
| none | {rounded["none"]} | Flush elements |
| sm | {rounded["sm"]} | Chips, tags, table cells |
| md | {rounded["md"]} | Buttons, inputs |
| lg | {rounded["lg"]} | Cards, dialogs, menus |
| pill | {rounded["pill"]} | Badges, toggles |

## Motion

Calm motion — animation serves the task, never decoration for its own sake.

### Duration

| Token | Value | Use |
|-------|-------|-----|
{duration_rows}

### Easing

| Token | Value | Use |
|-------|-------|-----|
{easing_rows}

## Elevation

Shadow levels 0-5. Use the lowest level that communicates the needed layering.

| Level | Shadow | Use |
|-------|--------|-----|
{elevation_rows}

## Components

Component-level guidance is defined per-skill in the sheen design system.
See: `.github/skills/` for component specifications.
Tokens are applied via CSS custom properties in `sheen/tokens/` or `dist/tokens/sheen.css`.
"""

if check_mode:
    if not Path(out_path).exists():
        print("::error::DESIGN.md missing — run: bash scripts/build-design-md.sh")
        sys.exit(1)
    existing = Path(out_path).read_text(encoding="utf-8")
    existing_fm = existing.split("## Overview")[0]
    generated_fm = design_md.split("## Overview")[0]
    if existing_fm.strip() != generated_fm.strip():
        print("::error::DESIGN.md front matter is out of date. Run: bash scripts/build-design-md.sh")
        sys.exit(1)
    print("build-design-md: DESIGN.md front matter OK")
    sys.exit(0)

Path(out_path).write_text(design_md.lstrip("\n"), encoding="utf-8")
print(f"build-design-md: wrote DESIGN.md ({theme} theme) → {out_path}")
PYEOF
