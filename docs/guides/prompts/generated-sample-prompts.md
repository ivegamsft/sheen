# Generated Sample Prompts — Agents, Skills, and Factory Patterns

> Generated from eval/test fixtures (skills/*/eval.yaml) and sheen.vocab.yaml by scripts/generate-sample-prompts.ps1.
> Generated at: 2026-08-18 19:10:31 UTC

## Agent samples (derived from mapped skill eval prompts)

### @design-system-architect

1. Add semantic focus-ring tokens and wire them to core values.
2. Create an accessible brand color ramp and map it to semantic primary roles.
3. Need help with type ramp definition for our product experience.

### @brand-steward

1. Define brand principles for a B2B analytics product so teams can judge future UI and content decisions.
2. Need help with logo variant guidance for our product experience.
3. Need help with imagery style direction for our product experience.

### @ux-designer

1. Need help with screen wireframe drafting for our product experience.
2. Need help with breakpoint behavior definition for our product experience.
3. Define a spacing scale for cards, forms, and page sections that maps cleanly to design tokens.

### @accessibility-auditor

1. Run a WCAG 2.2 AA audit for our checkout flow and prioritize issues.
2. Need help with contrast ratio checks for our product experience.
3. Need help with flow-to-heuristic coverage mapping for our product experience.

### @information-architect

1. Need help with controlled vocabulary design for our product experience.
2. Need help with entity relationship modeling for our product experience.
3. Need help with site map structuring for our product experience.

### @design-reviewer

1. Compare wizard checkout vs one-page checkout and give a weighted tradeoff matrix.
2. Need help with craft checklist passes for our product experience.
3. Audit our repo design quality and produce a prioritized UX backlog.

## Skill samples (one positive fixture per skill)

| Skill | Prompt sample (from eval fixture) |
|---|---|
| accessibility-audit | Run a WCAG 2.2 AA audit for our checkout flow and prioritize issues. |
| ai-output-governance | Review this AI-generated onboarding copy for representational bias and brand tone compliance |
| brand-identity | Define brand principles for a B2B analytics product so teams can judge future UI and content decisions. |
| brand-voice-tone | Need help with voice and tone rules for our product experience. |
| color-contrast-check | Need help with contrast ratio checks for our product experience. |
| color-system | Create an accessible brand color ramp and map it to semantic primary roles. |
| component-spec | Write a complete component spec for a segmented control with states and keyboard behavior. |
| content-hierarchy | Improve content prioritization on an analytics dashboard so admins see urgent exceptions before secondary metrics. |
| craft-quality | Need help with craft checklist passes for our product experience. |
| create-design-skill | Scaffold a new sheen skill for design decision logs with proper eval scenarios. |
| css-mapping | Need help with css inventory mapping for our product experience. |
| data-visualisation | Recommend the best chart type for showing monthly revenue across 5 product categories over a year |
| design-adoption-telemetry | Generate a token coverage report for src/ showing which semantic tokens are used versus hardcoded |
| design-audit | Audit our repo design quality and produce a prioritized UX backlog. |
| design-bootstrap | Bootstrap a brand-new design system for our new product. |
| design-debate | Compare wizard checkout vs one-page checkout and give a weighted tradeoff matrix. |
| design-drift-detection | Compare the live Button component CSS against the button spec and list drifts |
| design-exploration | Generate three divergent design concepts for a first-run dashboard experience before we choose a direction. |
| design-handoff | Need help with engineering handoff packaging for our product experience. |
| design-review | Review this checkout mock against our design principles and identify craft issues before handoff. |
| design-sprint | Facilitate a 5-day GV design sprint targeting the 68 percent checkout abandonment rate |
| design-suggest | Need help with targeted improvement suggestions for our product experience. |
| design-system-audit | Need help with token/component coherence checks for our product experience. |
| design-system-versioning | Classify renaming --color-brand-blue to --color-action-primary — major, minor, or patch? |
| design-to-code | Generate a React functional component from the card component spec with token-bound CSS |
| design-tokens | Add semantic focus-ring tokens and wire them to core values. |
| design-update | Need help with design system modernization for our product experience. |
| ethical-design | Audit the checkout wireframe for dark patterns including hidden costs and misdirection |
| font-mapping | Need help with font usage inventory for our product experience. |
| i18n-framework-mapping | Need help with i18n framework detection for our product experience. |
| iconography | Need help with icon grid definition for our product experience. |
| imagery-illustration | Need help with imagery style direction for our product experience. |
| information-architecture | Need help with site map structuring for our product experience. |
| landing-page-design | Need help with landing page structure for our product experience. |
| layout-grid-spacing | Define a spacing scale for cards, forms, and page sections that maps cleanly to design tokens. |
| logo-usage | Need help with logo variant guidance for our product experience. |
| mobile-native-design | Map the card component web spec to iOS HIG conventions including tap target and corner radius |
| motion-elevation | Need help with duration and easing tokens for our product experience. |
| multilingual | Need help with i18n/l10n strategy for our product experience. |
| navigation-design | Need help with global/local nav patterns for our product experience. |
| ontology | Need help with entity relationship modeling for our product experience. |
| pattern-library | Need help with pattern documentation for our product experience. |
| performance-aware-design | Assess whether a 1920px hero image with a custom display font will degrade LCP |
| responsive-design | Need help with breakpoint behavior definition for our product experience. |
| secure-ux | Harden the auth and consent UX so permission prompts are clear, reversible, and least-privilege. |
| sheen-onboard | Run the full sheen consumer lifecycle from integration through first agent use for this repo |
| style-guide-authoring | Need help with style-guide compilation for our product experience. |
| taxonomy | Need help with controlled vocabulary design for our product experience. |
| theming | Create a new partner theme with light, dark, and high-contrast values mapped to existing semantic tokens. |
| typography | Need help with type ramp definition for our product experience. |
| ui-states-interaction | Need help with interaction state modeling for our product experience. |
| usability-mapping | Need help with flow-to-heuristic coverage mapping for our product experience. |
| user-research | Need help with research planning for our product experience. |
| ux-writing | Need help with microcopy authoring for our product experience. |
| visual-regression | Need help with snapshot baseline setup for our product experience. |
| web-usability-review | Review our onboarding flow using NN/g heuristics and prioritize usability issues. |
| wireframing | Need help with screen wireframe drafting for our product experience. |

## Factory pattern samples

| Pattern | Prompt sample |
|---|---|
| **Parallel Audit** | bug: /sheen review run Parallel Audit for checkout flow regressions across accessibility, usability, and governance. Return a unified severity matrix with release recommendation. |
| **Serial Decision-Chain** | feature: /sheen debate run Serial Decision-Chain to choose dashboard navigation, then produce handoff spec and accessibility validation. |
| **Token Cascade** | pr: /sheen token run Token Cascade on PR #311 token updates; validate brand alignment, state coverage, and final CSS token mapping. |

## Intent helper examples

- `bug:` immediate remediation
- `pr:` PR-lifecycle context
- `audit:` read-only review
- `feature:` new capability design
- `later:` deferred planning
- `docs:` documentation-first output
- `chore:` maintenance and cleanup
