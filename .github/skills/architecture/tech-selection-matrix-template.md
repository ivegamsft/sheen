# Technology Selection Matrix Template

Use this template to evaluate competing technology options against weighted criteria. Complete this matrix before committing to a technology choice, then record the outcome as an ADR.

---

## Evaluation: {Decision Title}

**Date:** {YYYY-MM-DD}

**Decision Owner:** {Name or team}

**Context:** {Brief description of why this evaluation is needed and what problem the technology must solve.}

---

### Criteria and Weights

Define the evaluation criteria and assign weights that reflect project priorities. Weights must sum to 100.

| # | Criterion | Weight | Description |
|---|---|---|---|
| 1 | {Performance} | {25} | {Throughput, latency, resource efficiency under expected load} |
| 2 | {Team Expertise} | {20} | {Current team skill level; ramp-up time and training cost} |
| 3 | {Community & Ecosystem} | {15} | {Library ecosystem, community size, documentation quality, long-term viability} |
| 4 | {Total Cost of Ownership} | {15} | {Licensing, hosting, operational overhead, and maintenance cost} |
| 5 | {Scalability} | {10} | {Ability to scale horizontally/vertically to meet future demand} |
| 6 | {Security} | {10} | {Built-in security features, vulnerability track record, compliance support} |
| 7 | {Integration} | {5} | {Ease of integration with existing systems, APIs, and data stores} |
| | **Total** | **100** | |

---

### Scoring Guide

| Score | Meaning |
|---|---|
| 5 | Excellent — fully meets the criterion with clear advantages |
| 4 | Good — meets the criterion with minor gaps |
| 3 | Adequate — meets minimum requirements |
| 2 | Weak — partially meets the criterion; significant gaps |
| 1 | Poor — fails to meet the criterion |

---

### Evaluation Matrix

Score each option 1–5 per criterion. Weighted score = score × weight ÷ 100.

| Criterion (Weight) | {Option A} | {Option B} | {Option C} |
|---|---|---|---|
| {Performance} (25) | {score} | {score} | {score} |
| {Team Expertise} (20) | {score} | {score} | {score} |
| {Community & Ecosystem} (15) | {score} | {score} | {score} |
| {Total Cost of Ownership} (15) | {score} | {score} | {score} |
| {Scalability} (10) | {score} | {score} | {score} |
| {Security} (10) | {score} | {score} | {score} |
| {Integration} (5) | {score} | {score} | {score} |
| **Weighted Total** | **{total}** | **{total}** | **{total}** |

---

### Notes per Option

#### {Option A}

- **Strengths:** {Key advantages}
- **Weaknesses:** {Key disadvantages}
- **Risks:** {Adoption or operational risks}

#### {Option B}

- **Strengths:** {Key advantages}
- **Weaknesses:** {Key disadvantages}
- **Risks:** {Adoption or operational risks}

#### {Option C}

- **Strengths:** {Key advantages}
- **Weaknesses:** {Key disadvantages}
- **Risks:** {Adoption or operational risks}

---

### Recommendation

**Selected option:** {Option X}

**Rationale:** {Why this option was chosen. Reference the weighted scores and any qualitative factors that influenced the decision beyond the numbers.}

**Next step:** Record this decision as an ADR using `skills/architecture/adr-template.md`.
