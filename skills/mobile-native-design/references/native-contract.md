# Native Platform Mapping and Parity Contract (#67)

Read before native adaptation. Use the mapping table, scenarios, accessibility
artifact role, and schema for iOS, Android, and parity work. Example component/
wireframe paths are supplied by the downstream project.

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

## Native spec artifact roles

These suggested downstream artifact names are not bundled template files.
Author them from the mappings, scenarios, and schema below.

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
