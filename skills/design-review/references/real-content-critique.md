# Real-Content Calibration & Visual Self-Critique Loop (#185)

A bounded, evidence-led loop that runs before an artifact is considered
review-complete:

1. **Representative content.** Use domain-representative content and
   realistic data shapes wherever available (real or realistic sample copy,
   actual field lengths, plausible record counts) instead of generic
   placeholder/lorem-ipsum content alone.
2. **Mark invented content.** Explicitly label any invented copy, data, or
   assumption so reviewers know what is illustrative versus sourced.
3. **Exercise state extremes.** As applicable, exercise short, long, empty,
   error, loading, partial, permission-restricted, and localized content
   conditions.
4. **Capture rendered evidence when available.** Render the artifact and
   capture a screenshot/visual snapshot when the environment supports it
   (for example via the `visual-regression` skill's Playwright pipeline, or
   any other available rendering path) — no specific tool, framework, or
   screenshot service is mandated.
5. **Critique the evidence.** Assess hierarchy, readability, density,
   alignment, focal competition, overflow, responsive behavior, and
   unnecessary decoration.
6. **One focused revision pass.** Make one bounded round of revisions
   targeting the highest-impact findings, and record what changed and why.
7. **Tool-neutral fallback.** When rendering or screenshots are unavailable,
   perform the same critique (step 5) against the structural/markup/spec
   representation instead, and state explicitly that the fallback path was
   used.

**Stopping rule.** The loop is complete once (a) representative content and
applicable state extremes have been exercised or explicitly marked
not-applicable, (b) one critique pass has been recorded against rendered
evidence or its documented fallback, and (c) exactly one revision pass has
been made and recorded — do not iterate further rounds inside this
workflow; escalate remaining concerns to a follow-up review.
