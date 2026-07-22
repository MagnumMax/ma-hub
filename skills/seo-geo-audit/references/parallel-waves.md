# Parallel waves (SEO + GEO audit)

Preferred schedule when the orchestrator can launch **parallel agents**. Track contracts stay in `SKILL.md` (read each Aaron `SKILL.md` before that track). This file only answers: **what runs together, what waits, how the report is merged**.

Hard rules unchanged:

- Resolve **environment** (`local` | `prod`) and **primary base URL** before any fetch of *your* site.
- **Local** never fetches *your* production for primary-base tracks; market (SERP / competitors) may still run on the public web.
- No blended “site score /100” — merge into one priority backlog only.
- Audit-only: do not rewrite pages unless the user asks to fix.

## Lane map

| Lane | Base | Tracks |
|------|------|--------|
| **Site** | Primary (your local / preview / live) | technical, markup, on-page, content quality, GEO, structure, authority (*prod only*) |
| **Market** | Public web | SERP (AI lens), competitor (AI/GEO lens) |

After Wave 0, Site and Market lanes start in the **same** wave wherever the mode includes both.

---

## Wave catalog (`full` / `pre-deploy` / `post-deploy`)

### Wave 0 — Gate (strictly sequential, blocking)

**Must finish before any network to your primary base.**

| Step | Output |
|------|--------|
| Environment | `local` or `prod` |
| Mode | default from env, or user override |
| Primary base URL | localhost / preview / live |
| P0 pages | homepage + money/apply + hub (defaults OK) |
| Optional | keywords / AI queries; competitor list |

Until Wave 0 is done: no primary-base fetch; no *your*-domain authority.

---

### Wave 1 — Broad parallel (Site + Market)

Launch **independent agents in one batch** (one track per agent, or one agent per bullet if the harness prefers fewer workers).

**Site lane**

| Agent / track | Skill | Notes |
|---------------|-------|--------|
| Technical | `technical-seo-checker` | Primary base; include AI bots in robots |
| Markup gaps | `serp-markup-builder` | Audit-only on P0 URLs |
| On-page | `on-page-seo-checker` | P0 URLs (cap per mode) |
| Structure | `site-structure-optimizer` | Linking default; architecture if IA broken |
| Authority | `domain-authority-auditor` | **Prod / post-deploy only.** On `local` / `pre-deploy`: skip → “После деплоя” |

**Market lane**

| Agent / track | Skill | Notes |
|---------------|-------|--------|
| SERP (AI lens) | `serp-analysis` | 1–2 queries (`quick`: 1); never claim “we rank” on local |

**Do not put competitors in Wave 1** unless the user already named competitors (then they may join Wave 1 beside SERP).

---

### Wave 1b — Deep page parallel (Site)

Same primary page as content default (homepage or main money page; in `page` mode — that URL).

| Agent / track | Skill | Notes |
|---------------|-------|--------|
| Content quality | `content-quality-auditor` | Usually 1 page |
| GEO / AI citation | `geo-content-optimizer` | Audit-only; required in modes that need GEO |

May start **with** Wave 1 (same turn) or right after Wave 0 if P0 primary page is already known — no need to wait for technical/SERP results.

Live AI-citation probe of **your** URL: **prod only**; on local mark as post-deploy.

---

### Wave 2 — Competitors (Market, usually after SERP)

| Agent / track | Skill | Notes |
|---------------|-------|--------|
| Competitor AI/GEO | `competitor-analysis` | 2–3 competitors |

**Wait for Wave 1 SERP** when competitors were not user-provided (prefer SERP-inferred list, label Estimated).

**Skip Wave 2** in `quick` / `page` unless the user named competitors or asked for them.

If Wave 2 is `NEEDS_INPUT`, still ship GEO and other track findings.

---

### Wave 3 — Merge (orchestrator only, sequential)

No specialist agents. Parent agent only:

1. Collect track scorecards (separate scores — never one blended number).
2. Dedupe root causes → one backlog item with all URLs/patterns.
3. Prioritize with [prioritization.md](prioritization.md).
4. Fill [report-template.md](report-template.md) + CEO gate [ceo-env-checklist.md](ceo-env-checklist.md).
5. On local: Stage 1 primary; Stage 2 / “После деплоя” only for items that need **your** live host (not SERP/competitors).

---

## Waves by mode (summary)

| Mode | Waves |
|------|--------|
| `full` | 0 → 1 (+ 1b) → 2 → 3; authority in Wave 1 on prod |
| `pre-deploy` | Same as `full`, but authority skipped in Wave 1; no live citation of your URL |
| `post-deploy` | Same as `full` on live primary; refresh market; citation probe if tools exist |
| `quick` | 0 → **one parallel batch**: technical (blockers) ‖ on-page ‖ GEO ‖ SERP → 3; competitors only if named |
| `page` | 0 → **one parallel batch**: on-page ‖ markup ‖ content ‖ GEO ‖ narrow SERP → 3; competitor only if asked |
| `tech` | 0 → technical only → 3 |
| `structure` | 0 → structure only → 3 |
| `authority` | 0 → authority only (**prod**) → 3 |

Optional tracks (`entity-registry`, `offsite-signal-analyzer`, …): only if requested or blocking; attach to the earliest wave that has their inputs, or run after Wave 2 before merge.

---

## Dependency cheat sheet

| Track | Hard wait | Soft / preferred wait | Parallel OK with |
|-------|-----------|----------------------|------------------|
| Technical | Wave 0 | — | Markup, on-page, structure, content, GEO, SERP, authority (prod) |
| Markup | Wave 0 + P0 list | — | Technical, on-page, structure, market |
| On-page | Wave 0 + P0 list | — | Technical, markup, structure, market |
| Content | Wave 0 + primary page | — | GEO, Wave 1 site/market |
| GEO | Wave 0 + primary page | — | Content, Wave 1 site/market |
| Structure | Wave 0 + P0 list | Technical findings (optional) | Wave 1 / 1b / SERP |
| Authority | Wave 0 + **prod** | — | Other Wave 1 tracks on prod |
| SERP | Wave 0 (+ query or Estimated from title/H1) | — | Entire Site lane |
| Competitor | Wave 0; **SERP or user list** | SERP when list unknown | SERP if user list exists |
| Report merge | All required tracks done or skipped with reason | — | — |

---

## Parallelism policy

- **Do parallelize:** independent **read-only** tracks / agents in Waves 1, 1b, and (when allowed) Wave 2 with SERP.
- **Do not parallelize:** Wave 0; Wave 3 merge; auto-fixes / rewrites (sequential, after user asks).
- **Harness:** launch Wave 1 (+ 1b) agents in **one** parent turn when the Task/subagent API allows multiple concurrent agents; await all before Wave 2 (if needed) and Wave 3.
- **Fallback:** if parallel agents are unavailable, run the same wave order **sequentially** (A→I in `SKILL.md`) — same tracks, same report, slower.

---

## Pilot checklist

1. Pick one project; prefer `local` / `pre-deploy`.
2. Run `/MA-seo-geo-audit` with explicit env + URL.
3. Use this wave schedule; keep Aaron track contracts and report template unchanged.
4. Success: same report shape and priority quality; wall-clock wait clearly shorter than pure A→I chain.
