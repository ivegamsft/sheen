# Adoption Modes

Use this page to choose the lightest workable way to consume sheen.

<div class="grid cards" markdown>

-   **Lean mode**

    Solo designers or small teams that want only a few review and usability
    helpers.

    [Best for fast onboarding](#lean-mode)

-   **Token-only mode**

    Teams that want design-system consistency without syncing AI assets.

    [Best for platform or brand alignment](#token-only-mode)

-   **Full mode**

    Cross-functional teams that want the full catalog, including skills and
    agents.

    [Best for org-wide adoption](#full-mode)

</div>

## Decision tree

1. If you are testing the value of sheen, start with **Lean mode**.
2. If your priority is tokens and theming, start with **Token-only mode**.
3. If the team already relies on doc-driven workflows, go straight to **Full mode**.
4. If you need to keep risk low, pin a release tag before you widen scope.

## Lean mode

Use this when one person or a small team wants immediate value with minimal sync
surface.

```yaml
source: https://github.com/ivegamsft/sheen.git
ref: main
skills:
  - design-review
  - web-usability-review
instructions:
  - sheen-10-core-design-principles
```

Good fit when:

- you want a quick win without changing repository structure
- you need design review and usability support first
- you want to prove value before broadening scope

## Token-only mode

Use this when the main goal is design-system consistency and platform output
generation.

```yaml
source: https://github.com/ivegamsft/sheen.git
ref: main
skills: []
agents: []
instructions:
  - sheen-20-tokens-foundations
themes:
  - light
  - dark
  - high-contrast
```

Good fit when:

- you need semantic tokens but no AI assets
- you want to keep sync surface narrow while you build confidence
- you care most about theming, contrast, and downstream build outputs

## Full mode

Use this when the team is ready to consume the entire catalog.

```yaml
source: https://github.com/ivegamsft/sheen.git
ref: main
# Omit allow-lists to sync the full catalog
```

Good fit when:

- the repo already has clear ownership for skills, agents, and instructions
- you want maximum reuse across product and platform teams
- you are ready to validate the full catalog in CI

## How to switch later

You do not need to change tooling when you change modes. Update `.sheen.yml`,
re-sync, and keep the selected mode documented in the consumer repo.

When in doubt, start narrow, validate the first workflow, then widen scope one
asset family at a time.
