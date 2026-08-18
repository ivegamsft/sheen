---
name: secure-ux
compatibility: [github-copilot-cli]
description: "Use when hardening UX for auth flows, consent surfaces, error states, and input privacy safety. USE FOR: safe error-state design, auth/consent ux hardening, input-feedback privacy safety. DO NOT USE FOR: backend threat modeling, penetration testing."
category: security
metadata:
  category: security
  maturity: beta
  audience: [designer, developer]
  pillar: security
allowed-tools: []
---

# secure-ux

Apply security and privacy best practices to user-facing UX.

## Workflow
1. Identify trust boundaries in auth, consent, and data-exposure moments.
2. Map likely misuse cases the interface must prevent or contain.
3. Design safe interaction/copy patterns for risky or irreversible actions.
4. Validate least-privilege and privacy expectations in proposed flows.
5. Prioritize hardening recommendations by exploitability and user harm.

## Guardrails
- Do not expose sensitive internals through user-facing errors.
- Do not replace backend controls with UX-only mitigations.
- Do not weaken consent clarity for conversion goals.
- Do not omit failure-state handling for sensitive actions.

## Output
- Secure-UX hardening checklist with prioritized mitigations.
- Updated flow notes covering abuse cases and safe defaults.

## Delegates / pairs with
- ui-states-interaction
- ux-writing
