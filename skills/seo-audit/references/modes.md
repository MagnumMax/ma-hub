# SEO Audit modes

## `full` (default)

End-to-end health check for a live or nearly-live site.

1. technical-seo-checker (site / primary base)
2. serp-markup-builder (audit-only on P0 URLs)
3. on-page-seo-checker (P0 URLs, max 5)
4. content-quality-auditor (1 primary page)
5. site-structure-optimizer (linking; architecture if needed)
6. domain-authority-auditor (production domain)

## `page`

Single URL focus.

1. on-page-seo-checker
2. serp-markup-builder (meta + schema inventory)
3. content-quality-auditor (same URL)

Skip site-wide technical unless the page shows noindex/canonical/redirect issues — then run a narrow technical pass on that URL only.

## `tech`

technical-seo-checker only. Use for crawl disasters, migrations, CWV, robots/sitemap fights.

## `structure`

site-structure-optimizer only. Default linking mode for live sites; architecture when redesigning IA.

## `authority`

domain-authority-auditor. Add offsite-signal-analyzer only if user asks for backlinks or CITE flags toxic/link risks that need profile evidence.

## `quick`

Time-boxed (~one focused pass):

1. technical — blockers only (robots, noindex, sitemap, HTTPS, critical redirects)
2. on-page — homepage + one money page
3. Skip content-quality, structure deep-dive, authority unless a P0 appears

Still emit the full report template; mark skipped tracks as `skipped (quick mode)`.

## `pre-deploy`

Primary evidence base = localhost / preview / staging.

| Track | Base |
|-------|------|
| technical, markup, on-page, content, structure | local/preview |
| domain-authority | production domain (if exists) |
| Indexation in Google | **do not claim** — list as post-deploy checks |

Canonical tags may already point at production — note that; do not treat local URLs as the public index URL.

## `post-deploy`

Primary base = production. Prefer re-checking prior P0 list if present in conversation or `memory/seo-geo/audit/`. Confirm live robots/sitemap, rendered meta/schema, and any CWV field data available.
