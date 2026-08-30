# ADR-003 — Documentation Diagrams Are Static by Default

| Field | Value |
|---|---|
| **Date** | 2026-08-30 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

Epic #110 (Diagram Design Integration) adds a documentation-diagram capability
(scoped in #113) that emits self-contained HTML+SVG for code/docs diagrams
(architecture, sequence, flowchart, Gantt, etc.). Several reference
implementations we compared against (`cathrynlavery/diagram-design` among
them) default to autoplaying reveal/step animations for sequence and flow
diagrams, on the theory that motion helps a reader follow ordered steps.

This creates two conflicts with sheen's existing motion posture:

1. **Accessibility.** `docs/foundations/motion-elevation-materials.md` and the
   `motion-elevation` skill already require every animation to respect
   `prefers-reduced-motion`. An autoplaying diagram that starts moving the
   instant a doc page loads is a vestibular-disorder and cognitive-load risk
   if it ignores that media query — and many third-party diagram embeds do.
2. **Documentation is read, re-read, and skimmed out of order.** Autoplay
   animation timing assumes a single linear first read. Real usage of
   documentation diagrams is non-linear: a reader jumps to the diagram from a
   search result, references it mid-task, or re-opens it days later. An
   animation that has already finished (or is mid-cycle) when they arrive adds
   noise, not clarity.

## Options Considered

### Option 1 — Autoplay reveal by default, opt-out per diagram
Diagrams animate on load (e.g., sequence steps reveal in order); authors can
set `static: true` in front matter to disable it.

- ✅ Matches some reference tools' default; "looks alive"
- ❌ Violates `prefers-reduced-motion` unless every diagram author remembers
  to wire it up individually — an opt-out default virtually guarantees drift
- ❌ Penalises the common non-linear reading pattern described above

**Score: 4/10**

### Option 2 — Static by default; reveal-only sanctioned autoplay *(chosen)*
Every diagram renders as a single static frame by default — no animation, no
timers, nothing to interrupt or race a reader. A narrow, explicitly-opted-in
"reveal" mode is sanctioned **only** for step-by-step walkthroughs (e.g., a
sequence diagram teaching a protocol), and even then:
- it must be **user-triggered** (a "Play" control, click-to-advance, or
  scroll-linked), never autoplaying on page load;
- it must honour `prefers-reduced-motion` by skipping straight to the final
  state; and
- the static, fully-drawn diagram must always be reachable (e.g., a
  "Show all steps" control), so the diagram is never *only* consumable
  through the animated path.

- ✅ Zero accessibility risk by default; the reduced-motion rule from
  `motion-elevation` is satisfied trivially because there is no motion to gate
- ✅ Works identically for the non-linear reading pattern above
- ✅ Still allows a deliberate teaching aid where it earns its keep
- ❌ Slightly less "polished" first impression than an autoplay demo

**Score: 9/10**

### Option 3 — No animation capability at all
Never support reveal/step animation, even opt-in.

- ✅ Simplest to build and audit
- ❌ Forecloses a genuinely useful pattern for teaching sequential protocols
  with no accessibility cost, since Option 2 already makes it safe

**Score: 6/10**

## Decision

**Adopt Option 2 — static by default; reveal-only sanctioned autoplay**, gated
by user interaction and `prefers-reduced-motion`, with the static full diagram
always available as a fallback.

## Consequences

- **Positive:** The documentation-diagram renderer (#113) never needs a
  reduced-motion code path for the default case — there's nothing to reduce.
- **Positive:** Diagrams remain drop-in embeddable in any doc page without a
  motion audit per page.
- **Risk:** If a future contributor adds a "reveal" diagram type, this ADR is
  the checklist they must satisfy (user-triggered, reduced-motion fallback,
  static-diagram escape hatch) — reviewers should cite ADR-003 in PR review
  for any animated diagram addition.

## Related

- `docs/foundations/motion-elevation-materials.md`
- `skills/motion-elevation/SKILL.md`
- Epic #110, issue #113 (documentation-diagram renderer)
