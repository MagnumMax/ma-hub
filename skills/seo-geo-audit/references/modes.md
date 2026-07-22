# SEO + GEO Audit modes

Environment (`local` | `prod`) is resolved **before** mode. See skill Step 0.

- **local** → default mode `pre-deploy`
- **prod** → default mode `full` (or `post-deploy` when re-checking live after release)

Two bases:

- **Primary** = *your* site (local / preview / live)
- **Market** = public SERP + competitor sites (allowed before your launch)

## `full` (default for **prod**)

End-to-end health check (classic SEO + GEO / AI answer readiness). **Do not use as silent default when environment is unknown** — ask first.

1. technical-seo-checker (site / primary base; include AI bots stance in robots)
2. serp-markup-builder (audit-only on P0 URLs)
3. on-page-seo-checker (P0 URLs, max 5)
4. content-quality-auditor (1 primary page)
5. geo-content-optimizer (audit-only, 1 primary page — AI citation readiness)
6. site-structure-optimizer (linking; architecture if needed)
7. domain-authority-auditor (**your** production domain only)
8. serp-analysis (AI lens; 1–2 primary queries — market)
9. competitor-analysis (AI/GEO lens; 2–3 competitors — market)

## `page`

Single URL focus. Primary base must match chosen environment.

1. on-page-seo-checker
2. serp-markup-builder (meta + schema inventory)
3. content-quality-auditor (same URL)
4. geo-content-optimizer (same URL, audit-only)
5. narrow `serp-analysis` for primary query when known or inferable (market — local or prod)

Skip full competitor track unless user asks.

Skip site-wide technical unless the page shows noindex/canonical/redirect issues — then run a narrow technical pass on that URL only.

## `tech`

technical-seo-checker only. Use for crawl disasters, migrations, CWV, robots/sitemap fights (including AI bot rules). Against primary base only.

## `structure`

site-structure-optimizer only. Default linking mode for live sites; architecture when redesigning IA.

## `authority`

domain-authority-auditor on **your** domain. **Prod only.** If environment is local, do not fetch **your** live domain — skip and list under post-deploy, or ask to switch to `prod`.

Add offsite-signal-analyzer only if user asks for backlinks or CITE flags toxic/link risks that need profile evidence.

## `quick`

Time-boxed (~one focused pass):

1. technical — blockers only (robots incl. AI bots, noindex, sitemap, HTTPS, critical redirects) on **primary**
2. on-page — homepage + one money page
3. GEO — primary page only (citation readiness gaps)
4. SERP — **1** primary query (market; what answer engines show)
5. Skip content-quality deep-dive, structure, **your** authority, competitor unless user names competitors

Still emit the full report template; mark skipped tracks as `skipped (quick mode)`.

## `pre-deploy` (default for **local**; alias of `local`)

Primary evidence base for **your** pages = localhost / preview / staging.

| Track | Base |
|-------|------|
| technical, markup, on-page, content, **GEO**, structure | **your** local/preview only |
| **SERP, competitor** | **public market** — run before launch; frame as requirements for *your* local pages |
| **your** domain-authority, live AI-citation of **your** URL | **skip** — needs your live host |
| Indexation of **your** pages, field CWV on **your** host, live robots/sitemap on **your** host | **do not claim / do not fetch your prod** — list as post-deploy checks |

Canonical tags may already point at production — note that; do **not** follow them to audit **your** prod in the same run. Do not treat local URLs as the public index URL.

Report must include a filled **После деплоя** section with only what needs **your** live URL: domain trust of **your** domain, indexation, live meta/canonical, field CWV, live citation probe of **your** URL. SERP and competitors are **Stage 1 (do before launch)** — not post-deploy leftovers.

## `post-deploy` (prod after release)

Primary base = **your** production. Prefer re-checking prior P0 list if present in conversation or `memory/seo-geo/audit/`. Confirm live robots/sitemap (incl. AI bots), rendered meta/schema, GEO readiness on P0, **your** domain-authority, refresh SERP/competitor market view, and live citation probe of **your** URL when tools exist.
