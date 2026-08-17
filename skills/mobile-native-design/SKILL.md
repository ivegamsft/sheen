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

Design for iOS and Android with platform-native conventions — mapping design system tokens and components to HIG, Material You, and cross-platform parity expectations.

## Closes

GitHub issue #67 — `feat(skill): mobile-native-design — iOS HIG, Android Material You, cross-platform parity`

## Platform Mapping

| Design Dimension | iOS HIG | Android Material You | Sheen Token |
|---|---|---|---|
| Primary action colour | Tint (system blue by default) | Primary container | `color.action.primary` |
| Background | System grouped background | Surface | `color.surface.default` |
| Typography — body | SF Pro Text 17pt | Roboto Body Large 16sp | `typography.body.default` |
| Typography — headline | SF Pro Display 28pt | Roboto Headline Small 24sp | `typography.heading.md` |
| Corner radius — card | 10pt (RoundedRectangle) | 12dp (Medium) | `radius.card` |
| Spacing unit | 8pt grid | 4dp grid | `space.base` (8px) |
| Elevation — card | Shadow 3 | Elevation level 2 | `elevation.card` |
| Gesture — back | Swipe right (edge) | Back gesture / predictive | n/a (platform-native) |

## Sample Prompts

### Map web spec to iOS

```
@mobile-native-design map the card component spec at docs/components/card.spec.md
to iOS HIG conventions. What changes are needed?
```

**Output:**
```
## iOS HIG Mapping: Card Component

Corner radius: 10pt (spec: radius.card = 8px → increase to 10pt for iOS)
Shadow: HIG Shadow 3 (spec: elevation.card — matches)
Typography: SF Pro Text 15pt for body (spec: 14px → 15pt iOS equivalent)
Tap target: min 44×44pt (spec: 40px → flag for mobile adaptation)
Gesture: long-press for context menu (not in web spec — add to iOS spec)

Delta: 3 platform adaptations required
```

### Generate cross-platform parity report

```
@mobile-native-design generate an iOS vs Android parity report
for the components in docs/components/
```

### Audit for mobile accessibility

```
@mobile-native-design audit the checkout flow in docs/wireframes/checkout.spec.md
for iOS VoiceOver and Android TalkBack accessibility
```

### Spec gesture interactions

```
@mobile-native-design spec the gesture interactions for the swipe-to-dismiss
pattern in the notification component
```

## Templates in This Skill

| Template | Purpose |
|---|---|
| `ios-component-spec-template.md` | iOS HIG-adapted component spec with SwiftUI hints |
| `android-component-spec-template.md` | Material You-adapted component spec with Compose hints |
| `cross-platform-parity-template.md` | iOS vs Android parity report with delta table |
| `mobile-accessibility-checklist.md` | VoiceOver + TalkBack accessibility checklist |

## Output Schema

```yaml
discriminator: component-spec
platform: ios | android | cross-platform
hig_deviations: [{dimension: string, web_value: string, native_value: string}]
tap_target_issues: [string]
gesture_specs: [{gesture: string, action: string, platform: string}]
parity_delta: number
accessibility_pass: boolean
```

## Agent Pairing

- Input from: `ux-designer` (web wireframe), `design-system-architect` (token definitions)
- Output to: `frontend-dev` (SwiftUI / Jetpack Compose implementation hints)
- Pairs with: `accessibility-auditor` (VoiceOver/TalkBack audit), `design-drift-detection` (native vs spec parity)
