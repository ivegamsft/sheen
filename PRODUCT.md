---
$id: https://github.com/IBuySpy-Shared/basecoat-sheen/blob/main/PRODUCT.md
$type: Product
$context: https://schema.org
register: product
---

# basecoat-sheen

A design governance overlay for GitHub Copilot — wrapping every design request
in context, taste, and standards so teams ship consistent, accessible, on-brand
products without design-system expertise as a prerequisite.

---

## Register

product

---

## Users

Design system engineers, product designers, and cross-functional product teams
who use GitHub Copilot and need design decisions grounded in tokens, brand rules,
WCAG constraints, and component-level craft guidance — without switching tools
or hunting through stale design docs.

Also adopted by DevOps and platform teams who want design governance automation
in CI and want Copilot to understand their token pipeline, not just their code.

---

## Problem

Without sheen, GitHub Copilot produces design output that is generically correct
but contextually wrong: it doesn't know your token schema, your brand constraints,
your WCAG floor, or how your team resolves tradeoffs. Every design-adjacent
Copilot session starts from zero.

The concrete failure modes:

- Tokens are invented ad hoc; no DTCG schema, no alias chain, no theme parity.
- Brand voice, color, and logo guidance is ignored in generated copy and UI specs.
- Accessibility is optional — WCAG checks don't happen unless someone asks.
- Design debates produce opinions with no structured tradeoff record.
- New team members lack the context seniors carry in their heads.

---

## Product Purpose

basecoat-sheen overlays the GitHub Copilot surface with six design pillars —
Tokens & System, Brand, Usability, Accessibility, Information Architecture, and
Governance — each backed by a purpose-built agent, a catalog of skills, and
DTCG-compliant token tooling.

Success is measured by:

- **Routing accuracy**: ≥ 92% of design intents routed to the correct agent
  without user disambiguation (measured by `eval.yaml` pass rate).
- **Token conformance**: 0 DTCG schema errors, 0 dangling alias refs, all WCAG
  AA contrast pairs pass on every merge to `main`.
- **Consumer adoption**: teams complete the five-phase onboarding (Integrate →
  Onboard → Inventory → Audit → Use) in ≤ 2 working days.
- **Skill completeness**: every design intent the team encounters has a matching
  skill with at least one positive and one negative eval scenario.

---

## Brand Personality / Tone

**Craft-forward.** sheen treats design decisions as first-class engineering
artifacts — not suggestions, not vibes. Every output is structured, traceable,
and reviewable.

**Calm.** No alarm bells unless there is a real problem. Output is quiet when
correct; explicit and actionable when something needs attention.

**Personal.** Responses adapt to the team's context — their brand, their tokens,
their constraints — not a generic design-system playbook.

**Precise.** Terminology follows the PRODUCT.md lexicon and the sheen vocab. No
synonyms for normative terms. No hedging on decisions that have a right answer.

**Never**: tutorial-tone condescension, filler paragraphs, "feel free to",
unsolicited warnings, or responses that restate the question before answering.

---

## Anti-references

- **Generic AI design assistants** (Midjourney, Canva AI, etc.): sheen is not a
  generative visual tool. It produces structured design specifications, token
  schemas, and governance artifacts — not images or mock-ups.
- **Prescriptive design systems** (Material Design, Fluent, Carbon) used as
  drop-in templates: sheen works *with* any token system; it does not replace it.
- **Linting-only tools** (Stylelint, design-lint) that flag violations without
  reasoning or tradeoff analysis: sheen's governance pillar debates options and
  produces ADR-style decision records, not just error lists.
- **Documentation generators** (Storybook, Zeroheight): sheen is not a doc site
  — it is an agentic workflow layer that feeds into whatever documentation
  approach the team uses.

---

## Design Principles

1. **Effortless over configurable.** The most common design request should
   require the fewest steps. Defaults are correct for most teams; configuration
   is available for teams that need to diverge.

2. **Calm information density.** Output surfaces exactly what the designer or
   engineer needs to act — not everything the system knows. Verbosity is a
   design defect.

3. **Personal to context.** Every response is grounded in the team's actual
   tokens, brand, and constraints read from the repo — not a template or a
   population average.

4. **Familiar conventions.** sheen speaks DTCG for tokens, WCAG for
   accessibility, and Keep-a-Changelog for releases. It follows conventions
   the audience already knows rather than inventing new vocabulary.

5. **Complete and coherent.** Every design surface is covered. Every decision
   is explainable. No skill routes to a dead end; no pillar covers a topic
   without the adjacent pillar context.

---

## Accessibility & Inclusion

- **WCAG 2.2 AA** is the minimum for all color token pairs and all UI-adjacent
  output. The sheen token pipeline enforces this on every sync via
  `scripts/validate-tokens.ps1`.
- **WCAG 2.2 AAA** (7:1 contrast) is required for the `high-contrast` theme
  and for any output targeting assistive technology users.
- **EN 301 549** and **Section 508** conformance are tracked in
  `docs/guides/accessibility-conformance.md` (VPAT-style statement).
- Keyboard navigation and screen-reader compatibility are first-class eval
  criteria in `accessibility-audit` and `color-contrast-check` skills.
- Locale and RTL layout concerns are handled by the `multilingual` skill under
  the Information Architecture pillar.

---

## Offer

Open source, MIT licensed. Self-hosted by consuming teams — no SaaS dependency,
no telemetry, no vendor lock-in.

```json product.md#pricing
{
  "model": "open-source",
  "license": "MIT",
  "price": 0,
  "currency": "USD",
  "selfHosted": true,
  "supportTiers": [
    { "name": "community", "price": 0, "channel": "GitHub Issues" },
    { "name": "enterprise", "price": null, "channel": "contact maintainers" }
  ]
}
```

---

## Boundaries

- **Not a UI component library.** sheen produces token schemas, design specs,
  and governance artifacts. It does not ship React/Vue/Web Components.
- **Not a visual design tool.** sheen does not generate images, mock-ups, or
  Figma files. It generates the *decisions and specifications* that feed into
  those tools.
- **Not an engineering framework.** Cross-domain engineering concerns (CI/CD,
  infrastructure, security, code review) are handled by
  [basecoat](https://github.com/IBuySpy-Shared/basecoat), the parent framework
  that sheen integrates with.
- **Not a documentation host.** sheen's docs (published at
  `ivegamsft.github.io/sheen`) describe the framework itself. Consumer teams
  host their own design documentation using whatever tool they choose.
- **Not opinionated about component frameworks.** sheen's CSS token output works
  with any CSS-in-JS, Tailwind, vanilla CSS, or design-token pipeline. It
  produces DTCG JSON and CSS custom properties; the team decides how to consume them.

---

## Stack

```yaml product.md#stack
agents: .github/agents/
skills: .github/skills/sheen/
tokens: sheen/tokens/
docs: https://ivegamsft.github.io/sheen/
vocab: sheen.vocab.yaml
changelog: CHANGELOG.md
version: version.json
sync: sync.ps1 | sync.sh
upgrade: scripts/upgrade-sheen.ps1 | scripts/upgrade-sheen.sh
```

See also:
- `agents/` — source agent definitions (synced to `.github/agents/` in consumer repos)
- `skills/` — consumer-facing skill catalog (synced to `.github/skills/` in consumer repos)
- `docs/guides/consumer-lifecycle.md` — Integrate → Onboard → Inventory → Audit → Use → Upgrade
- `sheen.vocab.yaml` — machine-readable intent vocabulary (46 intents, generated)
