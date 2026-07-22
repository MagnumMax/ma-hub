# Prioritization rules

## Order of severity (highest first)

1. **Cannot be crawled or indexed** — robots disallow, noindex, soft-404, bad canonical to wrong host, redirect loops; AI bots fully blocked when AI visibility is a business goal
2. **Money-path broken** — primary conversion URL errors, blocked, or no internal links
3. **Gate vetoes** — CORE-EEAT veto items (content-quality-auditor), CITE veto items (domain-authority-auditor), or **GEO-critical Fail** (no extractable answer, no quotable claims, invisible authority on money pages)
4. **Duplicate / cannibalization signals** — conflicting titles, near-duplicate hubs, parameter traps
5. **SERP / AI presentation** — missing/weak title/meta; missing eligible schema; weak answer-shaped blocks where AI Overviews dominate the query
6. **Structure friction** — orphans, depth >3 for money pages, weak hub→spoke
7. **Performance** — CWV failures with Measured evidence
8. **Authority / offsite / competitor gap** — thin trust, risky links, or competitors clearly more citable (only with evidence)

## Priority labels

| Label | Ship guidance |
|-------|----------------|
| **P0** | Fix before other SEO/GEO work; blocks index, revenue path, or AI-answer eligibility on money pages |
| **P1** | This sprint; clear impact on rankings, CTR, trust, or AI citations |
| **P2** | Backlog; do after P0/P1 |
| **Later** | Opportunistic or needs more data |

## Deduping

- Same root cause on many URLs → one backlog item, list URLs or pattern (`/blog/*` missing Article schema).
- Prefer one fix that closes multiple findings (e.g. template title + definition block helps SEO snippet and GEO citability).
- Prefer fixes that help **both** classic SEO and GEO when equally cheap.

## What is not P0

- Missing optional schema types with no clear rich-result or FAQ fit
- Speculative keyword gaps without page inventory
- “Low DA” without CITE evidence or competitor context
- Lab CWV warnings without field data *and* without obvious weight issues — keep as P1/P2 with evidence label
- Unprompted AI-engine citation promises (week-scale, confounded) — treat live citation probes as proxies, not P0 guarantees
