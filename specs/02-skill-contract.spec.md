# Spec 02 — Skill Contract

> Normative spec for `skills/<name>/`. Implements root SPEC §4, §8. Mirrors the
> basecoat skill primitive so tooling transfers.

## 1. Folder shape

```
skills/<skill-name>/
├── SKILL.md          # required
├── eval.yaml         # required — routing test
└── templates/        # optional — starter assets
```

- `<skill-name>` is kebab-case and MUST equal the `name` in frontmatter.
- The folder is flat under `skills/`; logical grouping lives in `skills/_catalog.md`.

## 2. `SKILL.md` frontmatter (YAML)

```yaml
---
name: <skill-name>                       # MUST equal folder name
compatibility: [github-copilot-cli]      # target runtimes
description: "Use when …. USE FOR: <trigger>, <trigger>, <trigger>. DO NOT USE FOR: <anti-trigger>, <anti-trigger>."
category: design                         # design | foundation | brand | ia | usability | a11y | security | content | mapping | lifecycle | governance
metadata:
  category: design
  maturity: draft                        # draft | beta | stable
  audience: [designer, developer]
  pillar: <foundations|brand|ia|components|usability|content|a11y|security|mapping|lifecycle|governance>
allowed-tools: []                        # least-privilege; empty unless the skill needs tools
---
```

Rules:
- `description` MUST contain both `USE FOR:` (≥3 trigger phrases) and
  `DO NOT USE FOR:` (≥2 anti-triggers). Discovery keywords live here, not only in
  the body.
- `pillar` MUST be one of the catalog groups in root SPEC §8.
- `allowed-tools` is least-privilege; a mapping/audit skill that reads a repo may
  list read/search tools, authoring skills usually keep it empty.

## 3. `SKILL.md` body

Target **≤ ~500 tokens**. Required sections, in order:

1. **Title + one-line purpose.**
2. **Workflow** — numbered, actionable steps.
3. **Guardrails** — what to never do; scope boundaries.
4. **Output** — the concrete artifact(s) produced (and where they land).
5. **Delegates / pairs with** — skills and agents this one hands off to.

Move long examples, checklists, and starter files into `templates/` or `docs/`,
not the skill body.

## 4. `eval.yaml` (routing test)

```yaml
name: "<skill-name>-routing"
description: "Routing evaluation — validates trigger activation for <skill-name>."
skill: "skills/<skill-name>/SKILL.md"
scenarios:
  - { id: "pos-1", input: "<realistic user request>", expect_activation: true }
  - { id: "pos-2", input: "…", expect_activation: true }
  - { id: "pos-3", input: "…", expect_activation: true }
  - { id: "neg-1", input: "<adjacent-but-wrong request>", expect_activation: false }
  - { id: "neg-2", input: "…", expect_activation: false }
```

- MUST have ≥3 positive and ≥2 negative scenarios.
- Negatives SHOULD include a request that belongs to a *neighboring* sheen skill
  (to prove disambiguation), plus one clearly out-of-domain request.

## 5. Templates

- Add `templates/` only when starter assets reduce repeated work.
- Templates are Markdown or DTCG/JSON, self-describing, with placeholder markers.
- Shared cross-skill templates live in the top-level `templates/`; skill-specific
  ones live in the skill's own `templates/`.

## 6. Quality bar

- One skill = one clear workflow. Overlapping descriptions fail review.
- Do not create a skill where a file instruction (spec 04) suffices.
- Every skill must appear in `skills/_catalog.md` and `sheen-metadata.json`
  (drift fails CI — spec 05).
- New skills are authored via the `create-design-skill` skill.

## 7. Eval authoring standard and routing CI gate

Routing evals are production assets. Each `skills/<name>/eval.yaml` and
`agents/*.agent.eval.yaml` MUST keep the schema shown above: top-level `name`,
`description`, `skill`, and `scenarios`; each scenario MUST include `id`,
`input`, and boolean `expect_activation`.

Minimum requirements:
- At least **3 positive** and **2 negative** scenarios per eval file.
- Positives use realistic user phrasing with concrete work, context, and desired
  outcome; avoid scaffold phrases such as "Need help with ..." or "Use <agent> ...".
- Positives overlap the referenced skill/agent trigger vocabulary, but are not
  just keyword lists.
- Negatives include at least one adjacent-but-wrong design request and one clear
  out-of-domain request so routing boundaries are tested.
- Every eval must score **>= 7/10** in `scripts/audit-evals.ps1` and pass
  `scripts/test-eval-routing.ps1`; CI enforces this gate on push and PR.

Specificity rubric used by the scripts:
- Positive coverage: 0-2 points.
- Negative coverage: 0-2 points.
- Realistic input detail and average prompt length: 0-2 points.
- Diversity of non-generic positive vocabulary: 0-1.5 points.
- Overlap with referenced trigger terms: 0-1.5 points.
- Hard adjacent negatives: 0-1 point.
- Boilerplate or duplicate-like scenarios can subtract confidence.

Good scenarios:

```yaml
- id: "pos-safe-error-states"
  input: "Design safe error states for password reset that avoid account enumeration and sensitive internal details."
  expect_activation: true
- id: "neg-threat-model"
  input: "Perform backend threat modeling for API authorization, secrets handling, and service-to-service trust boundaries."
  expect_activation: false
```

Weak scenarios:

```yaml
- id: "pos-1"
  input: "Need help with this skill for our product experience."
  expect_activation: true
- id: "neg-1"
  input: "Please focus exclusively on something else."
  expect_activation: false
```

The good examples provide task context, disambiguating vocabulary, and a clear
routing boundary. The weak examples are generic enough to activate many skills
and do not prove the router can distinguish neighboring capabilities.
