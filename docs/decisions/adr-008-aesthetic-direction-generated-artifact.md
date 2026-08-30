# ADR-008 — AESTHETIC-DIRECTION.md as a Second Generated Consumer Artifact

| Field | Value |
|---|---|
| **Date** | 2026-08-30 |
| **Status** | Accepted |
| **Deciders** | sheen maintainers |
| **Supersedes** | — |
| **Superseded by** | — |

## Context

Issue #142 asked whether sheen should "suggest a design aesthetic that will
drive the direction for the overall application, doc site, mobile app" for
downstream consumers. Sheen already generates one artifact for consumers —
`DESIGN.md` (via `scripts/build-design-md.*` and the
`generate-design-md-callable.yml` reusable workflow) — which renders
mechanical token facts (exact color hex values, font sizes, easing curves)
for AI design agents to consume literally.

That existing artifact deliberately does not answer a different, adjacent
question: *what should this product look and feel like*, in prose a human
or an AI agent can use to make judgment calls DESIGN.md's token table
cannot resolve on its own (mood, color story, type pairing, spacing rhythm,
motion character). `docs/design-context.md` already contains the review
rubric for judging aesthetic coherence, but nothing renders a
per-consumer, per-theme narrative artifact from it.

## Options Considered

### Option 1 — Fold aesthetic guidance into `DESIGN.md`
Add a "creative direction" section to the existing `build-design-md`
script/output.

- ✅ One artifact, one generation path to maintain
- ❌ Conflates two different consumers: AI agents needing exact token
  values (deterministic, machine-checkable) vs. a narrative aesthetic
  direction (interpretive, meant to be read and debated by humans and
  agents alike) — mixing them makes `DESIGN.md` harder to consume
  mechanically
- ❌ `DESIGN.md` has no per-theme (light/dark) narrative concept today;
  bolting one on would be a breaking change to its existing consumers

**Score: 3/10**

### Option 2 — Generate a second artifact, `AESTHETIC-DIRECTION.md`, mirroring the `DESIGN.md` pattern *(chosen)*
Add `scripts/build-aesthetic-direction.{ps1,sh}` and a
`generate-aesthetic-direction-callable.yml` reusable workflow, wired into
`sync.ps1`/`sync.sh` the same way `build-design-md` already is. The new
script parses `docs/design-context.md`'s review rubric plus DTCG tokens
(`tokens/` or `sheen/tokens/` for consumer repos) and renders a
theme-aware narrative artifact, explicitly excluding any
reporting/analytics chart guidance (out of scope — that lives in the
diagram-design epic, ADR-006).

- ✅ Reuses an already-proven pattern (callable workflow + sync wiring +
  consumer/producer path auto-detection) instead of inventing a new
  integration mechanism
- ✅ Keeps `DESIGN.md` machine-oriented and `AESTHETIC-DIRECTION.md`
  narrative-oriented — each artifact has one clear consumer and contract
- ✅ Theme parameter (`-Theme dark`/`light`) lets a consumer generate
  direction for either mode without duplicating the whole pipeline
- ❌ A second generated file for consumers to discover and wire into their
  own repos (mitigated by mirroring the existing `sync.*` wiring so
  onboarding cost is close to zero for repos already consuming `DESIGN.md`)

**Score: 9/10**

### Option 3 — Do not generate anything; document the aesthetic question only in `docs/design-context.md`
Leave the rubric as review guidance; require every consumer to write their
own narrative by hand.

- ✅ Zero new tooling
- ❌ Directly reproduces the drift problem sheen exists to solve — every
  consumer answers "what should this look like" independently, with no
  shared starting point derived from the same tokens
- ❌ Ignores the issue's explicit ask for something sheen *suggests*, not
  just a rubric consumers self-apply

**Score: 2/10**

## Decision

**Adopt Option 2.** Ship `AESTHETIC-DIRECTION.md` as a second
per-consumer generated artifact, produced by
`scripts/build-aesthetic-direction.{ps1,sh}` and the
`generate-aesthetic-direction-callable.yml` reusable workflow, wired
through `sync.ps1`/`sync.sh` alongside `build-design-md`. It reads
`docs/design-context.md` and DTCG tokens and renders theme-aware creative
direction narrative; it intentionally excludes reporting/analytics chart
guidance, which is out of scope per ADR-006.

## Consequences

- **Positive:** Consumers get a suggested aesthetic direction instead of
  starting from a blank page, directly answering issue #142's ask.
- **Positive:** The mechanical/narrative split keeps `DESIGN.md` a stable,
  machine-checkable contract while `AESTHETIC-DIRECTION.md` can evolve more
  freely as a human/agent-readable document.
- **Risk:** Two generated artifacts now need to be kept in sync with token
  changes instead of one; any future token schema change must update both
  `build-design-md` and `build-aesthetic-direction` scripts, or the two
  artifacts can drift apart from each other as well as from source tokens.

## Related

- `scripts/build-aesthetic-direction.ps1`,
  `scripts/build-aesthetic-direction.sh`
- `.github/workflows/generate-aesthetic-direction-callable.yml`
- `docs/design-context.md`, `sync.ps1`, `sync.sh`, `.sheen.yml.example`
- Issue #142
- ADR-006 (diagram scope exclusion of reporting/analytics charts, same
  exclusion principle applied here)
