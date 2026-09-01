---
name: sheen-40-web-usability
compatibility: [github-copilot-cli]
description: "Path-scoped web usability rules grounded in the NN/g heuristics and ISO 9241 dialogue principles."
applyTo: "**/*.html,**/*.css,**/*.scss,**/*.sass,**/*.less,**/*.styl,**/*.jsx,**/*.tsx,**/*.vue,**/*.svelte,**/*.astro,**/*.md,**/*.mdx,**/components/**,**/ui/**,**/frontend/**,**/client/**,**/web/**,**/design/**,**/docs/**"
metadata:
  band: 40
  layer: web-usability
---

# Web Usability

Apply these principles to every design review, audit, and recommendation. They
implement the Nielsen Norman Group ten heuristics and the ISO 9241-110 dialogue
principles as ambient rules on matching web and design surfaces.

## The NN/g ten heuristics

Use each heuristic as a lens when evaluating a design, flow, or component:

| # | Heuristic | Design implication |
|---|---|---|
| 1 | **Visibility of system status** | Always keep users informed of what is happening via appropriate feedback within a reasonable time. Loading states, progress indicators, and confirmation messages are not optional. |
| 2 | **Match between system and the real world** | Use words, phrases, and concepts familiar to the user. Avoid jargon. Follow real-world conventions so information appears in a natural and logical order. |
| 3 | **User control and freedom** | Provide clearly marked "emergency exits" for mistaken actions. Support undo and redo. Never trap a user in a dead end. |
| 4 | **Consistency and standards** | Follow platform conventions. Users should not have to wonder whether different words, situations, or actions mean the same thing. |
| 5 | **Error prevention** | Design to prevent problems before they occur. Prefer constraints and confirmations for irreversible actions over error messages after the fact. |
| 6 | **Recognition rather than recall** | Minimize the user's memory load. Make objects, actions, and options visible. Instructions should be retrievable whenever appropriate. |
| 7 | **Flexibility and efficiency of use** | Provide accelerators for expert users (keyboard shortcuts, bulk actions, personalization) without burdening novice users. |
| 8 | **Aesthetic and minimalist design** | Every extra element competes with the relevant ones. Remove content and features that are not used or needed by most users. |
| 9 | **Help users recognize, diagnose, and recover from errors** | Error messages must be in plain language, precisely indicate the problem, and constructively suggest a solution. |
| 10 | **Help and documentation** | Provide easy-to-search help focused on the user's task. Steps should be concrete and not too numerous. |

## ISO 9241-110 dialogue principles

Apply these seven principles as a cross-check against the NN/g heuristics:

- **Suitability for the task:** the interface supports the user's task without
  unnecessary steps or information.
- **Self-descriptiveness:** the interface explains itself at each step (labels,
  tooltips, placeholder text).
- **Conformity with user expectations:** behavior matches users' prior experience
  and stated context.
- **Learnability:** novice users can discover how to complete tasks without
  external help.
- **Controllability:** users can initiate and control the pace and sequence of
  interactions.
- **Error tolerance:** despite errors, the intended result is achievable with
  minimal corrective action.
- **User engagement:** the interface motivates continued use without being
  distracting.

## HubSpot practical usability rules

- Purpose is clear above the fold. Users know within 5 seconds what the page
  offers and what to do next.
- Primary call-to-action is visually dominant and there is only one per screen.
- Navigation is predictable: logo links home, primary nav is in the header,
  secondary nav does not compete with primary.
- White space is used deliberately: related elements are grouped; unrelated
  elements are separated.
- Page weight and load time are considered as usability concerns, not only
  engineering ones.

## Heuristic violation severity

When flagging a heuristic violation in a review or audit:

- **Critical:** the violation prevents a user from completing a task or causes
  data loss. Fix before release.
- **Major:** the violation significantly slows users or causes repeated errors.
  Prioritize in the next sprint.
- **Minor:** the violation creates friction but does not block completion.
  Address in backlog.
- **Enhancement:** improvement beyond the heuristic baseline.

## Review lens

Before finalizing any recommendation, ask:

- Does the design pass all ten NN/g heuristics? Name any that fail and at what
  severity.
- Are all system states communicated to the user (heuristic 1)?
- Is the language natural and jargon-free (heuristic 2)?
- Can the user undo or escape from every action (heuristic 3)?
- Is there one clear primary action per screen (heuristic 8 + HubSpot)?
- Do error messages name the problem and offer a fix (heuristic 9)?
