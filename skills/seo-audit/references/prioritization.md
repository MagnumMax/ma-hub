# Prioritization rules

## Order of severity (highest first)

1. **Cannot be crawled or indexed** — robots disallow, noindex, soft-404, bad canonical to wrong host, redirect loops
2. **Money-path broken** — primary conversion URL errors, blocked, or no internal links
3. **Gate vetoes** — CORE-EEAT veto items (content-quality-auditor) or CITE veto items (domain-authority-auditor)
4. **Duplicate / cannibalization signals** — conflicting titles, near-duplicate hubs, parameter traps
5. **SERP presentation** — missing/weak title/meta, missing eligible schema for clear page type
6. **Structure friction** — orphans, depth >3 for money pages, weak hub→spoke
7. **Performance** — CWV failures with Measured evidence
8. **Authority / offsite** — thin trust, risky links (only with evidence)

## Priority labels

| Label | Ship guidance |
|-------|----------------|
| **P0** | Fix before other SEO work; blocks index or revenue path |
| **P1** | This sprint; clear impact |
| **P2** | Backlog; do after P0/P1 |
| **Later** | Opportunistic or needs more data |

## Deduping

- Same root cause on many URLs → one backlog item, list URLs or pattern (`/blog/*` missing Article schema).
- Prefer one fix that closes multiple findings (e.g. template title fix > per-URL copy edits).

## What is not P0

- Missing optional schema types with no clear rich-result fit
- Speculative keyword gaps without page inventory
- “Low DA” without CITE evidence or competitor context
- Lab CWV warnings without field data *and* without obvious weight issues — keep as P1/P2 with evidence label
