# Wireframe artifact contract

Read before authoring or rendering. This folder is independently syncable.

## Method

Frame a task and success condition, inventory approved page/layout/flow decisions,
then sketch content priority rather than inventing taxonomy or polished styling.
Each screen references exactly one page; distinct states may share a page.
Keep required empty/loading/error/success states explicit, or record why omitted.
Describe desktop/mobile ordering, touch/keyboard paths and unresolved assumptions.
Use realistic but non-sensitive sample content. Never solicit actual credentials.

Default: screen specification. Explicit SVG selects a static sketch board;
explicit HTML selects an offline click-through. Neither authorizes deployment.
Choose the user's destination; keep drafts outside application runtime folders.
For alternatives, use `design-debate` and record the selected structure/rationale.

## Portable model

The complete starter is [task-flow.json](../templates/task-flow.json).
Required top-level fields: `schema: sheen-wireframes/v1`, `title`, `start`,
`pages` (unique page IDs), `screens`, `flows`.
IDs match `^[A-Za-z][A-Za-z0-9_-]{0,63}$`.

Screen: `id`, `page`, `title`, `state`, `annotations`, `regions`.
State: default/empty/loading/error/success. Region: `label`, `blocks`.
Block: `kind`, `label`; kinds text/input/placeholder/action.
Only action has required `target` (screen ID).
Flow: `id`, `steps` (screen IDs). Every adjacent pair needs an explicit action.
All screens must be reachable from `start`. Unknown fields or unresolved IDs
are errors; do not silently downgrade interactions to decoration.
The helper produces ordered stacked layouts, not arbitrary geometry.

## Commands

Python 3 is optional for rendering, not required to read or manually use this skill.
No packages are needed. Run from this skill folder (PowerShell examples):

```powershell
python .\scripts\render-wireframes.py --input .\templates\task-flow.json --format spec --output F:\Review\wireframes.md
python .\scripts\render-wireframes.py --input .\templates\task-flow.json --format svg --output F:\Review\wireframes.svg
python .\scripts\render-wireframes.py --input .\templates\task-flow.json --format html --output F:\Review\prototype.html
```

Use native paths on other hosts. Output parents must already exist. Refresh
requires `--replace-owned`; the sidecar/current hash must prove ownership.
Do not edit generated files then overwrite them: preserve edits and regenerate
to a new destination or review the model. Same content preserves bytes/timestamps.
Outputs and sidecars are downstream artifacts, not source sync ownership.

## Review/handoff

Specification: validate goals, order, state omissions, IDs and flow completeness.
SVG: inspect legibility and screen bounds; target labels are annotations, not links.
HTML: open locally, verify every action, keyboard Tab/Enter, Back/Reset, focus on
screen changes, invalid-route recovery, input reset, 320px and desktop overflow.
No network/storage; inputs are pretend data. The browser history is not used;
prototype Back follows the simulated session stack. The fragment reflects the
active screen without adding browser-history entries. Reset returns to start.
Record browser/visual/task evidence and limitations; a passing renderer is not
proof of user success or WCAG conformance. Hand off accepted structure via
`experience-blueprint` and production scaffolding via `design-to-code`.
