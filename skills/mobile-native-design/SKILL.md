---
name: mobile-native-design
compatibility: [github-copilot-cli]
description: "Use when designing for iOS, Android, or cross-platform mobile/native experiences. USE FOR: map a web component spec to iOS HIG conventions, adapt a design system to Android Material You dynamic theming, spec gesture interactions for a mobile screen, audit a mobile design for platform-native accessibility, generate a cross-platform parity report between iOS and Android specs. DO NOT USE FOR: web-only responsive design, backend mobile API design, mobile CI/CD pipeline setup."
category: development
metadata:
  category: development
  maturity: stable
  audience:
    - developer
    - designer
allowed-tools: []
---
# Mobile Native Design Skill

Map tokens/components to iOS HIG, Android Material You, native gestures, and cross-platform parity.

## Workflow
1. Load web wireframes/component specs, token definitions, and target platform.
2. Read and apply the [native contract](references/native-contract.md): platform mapping, adaptation/parity/gesture/accessibility scenarios, artifact roles, and schema.
3. Map colour, typography, radius, spacing, elevation, and back gestures; document web-to-native deltas and dynamic theming needs.
4. Specify gesture actions and tap targets; audit VoiceOver/TalkBack accessibility and compare iOS/Android parity.

## Guardrails
- Preserve platform-native conventions rather than blindly copying web values; record deviations, including undersized iOS targets against the 44×44pt minimum.
- Do not claim accessibility or parity without the corresponding audit evidence.
- Not web-only responsive design, backend mobile APIs, or mobile CI/CD.

## Output
- Downstream iOS/Android component specs with SwiftUI/Compose hints, cross-platform delta report, and mobile accessibility checklist.
- Reference `component-spec` schema: platform, HIG deviations, tap-target issues, gesture/action/platform specs, parity delta, accessibility pass.

## Delegates / pairs with
- Input: `ux-designer` (web wireframe), `design-system-architect` (tokens).
- Output: `frontend-dev` (SwiftUI / Jetpack Compose hints).
- Pairs: `accessibility-auditor` (VoiceOver/TalkBack), `design-drift-detection` (native/spec parity).
