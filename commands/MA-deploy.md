---
description: "MA · Monster Automation — Полный цикл перед продом — локальные проверки, react doctor +1, build (≈ Vercel) перед push, push dev, CI, PR, merge, Vercel production"
argument-hint: [auto | check-only | skip-merge]
---

# MA-deploy

**Цель:** довести **текущий проект** до зелёного продакшена: локальные проверки → упаковка → один push `dev` → CI → PR в `main` → Vercel production + smoke.

Я не программист. В **safe** (по умолчанию) блокеры не чини сам — отчёт и жди решения. В **auto** (или после явного «чини») чини сам. Объясняй простым языком только блокеры и итог.

**Этот `/MA-deploy` — единственный оркестратор релиза.** Не подменяй `gstack/ship`, `land-and-deploy`, `setup-deploy`.

**Вход:** $ARGUMENTS

## 0. Ворота: стандарт в проекте

Найди **ma-hub**: `~/.config/ma-hub/config` → `MA_HUB_ROOT`, иначе `~/ma-hub`.  
Проверь в **текущем проекте** файл `docs/MA-STANDARDS.md`.

### Если файла нет — стоп
Не начинай релиз. Предложи создать визитку из `$MA_HUB_ROOT/templates/project-ma-link.md` → `docs/MA-STANDARDS.md`.

Объясни коротко **зачем**:
- это связь проекта с общими правилами Monster Automation (вкус, процесс, качество);
- без неё команда не знает pin / локальные отклонения и легко уйдёт «в общий шаблон», а не в закон этого продукта;
- сами правила живут в хабе (`standards/`), в проекте — только ссылка и ваши исключения.

Спроси: «Создать `docs/MA-STANDARDS.md`? **ок** / позже».  
До «ок» (или явного «позже, всё равно продолжай») дальше не иди. После создания — учти pin и Local deviations.

### Если файл есть
Учти pin и Local deviations. Перед релизом сверься с `$MA_HUB_ROOT/standards/05-release-and-quality.md`.

## Режимы и аргументы

| Режим | Как | Починка |
|-------|-----|---------|
| **safe** (default) | `/MA-deploy`, `check-only`, `skip-merge` | Не чинить. Блокер → Таблица 6 → ждать «чини» / «не чинить» / «отложить» |
| **auto** | `auto` (+ можно `check-only` / `skip-merge`) | Чинить блокеры без паузы (CI→эталон thin+дешёвый, хуки→шаблон, Critical, fails). **Исключение:** ponytail — только отчёт, никогда автофикс |

**Safe:** Critical / толстый или дорогой CI / тяжёлые хуки / fail проверок → стоп, не commit, не push. Грязное дерево в начале — **не** блокер. Ponytail `net ≤ -80` → стоп; иначе только отчёт.

**Auto:** без подтверждений на фикс; root cause (`systematic-debugging`) → fix **в дереве без commit** → re-check, макс. 5 итераций на фазу. Не сошлось → стоп с отчётом. Ponytail даже при `net ≤ -80` — пометить и **продолжить**. Commits только в Phase 3.9.

Аргументы (порядок не важен):
- пусто — полный цикл до prod, **safe**
- `auto` — полный цикл с автопочинкой
- `check-only` — Phase 1–3.5 + 3.9, без push/CI/PR/prod
- `skip-merge` — до Phase 5 (push + CI), без merge и Vercel prod

## Pipeline

```
0 → 1 (ревью ‖ проверки) → 2 (react-doctor) → 3 (disk/build/budget)
  → 3.5 (supabase если нужно) → 3.9 (атомарные commits) → 3.95 (main → dev)
  → 4 (один push dev) → 5 (CI typecheck+test) → 6 (PR → merge) → 7 (Vercel + smoke)
```

Локально перед push: 1–3.5 → **3.9** → **3.95** → 4. `pnpm build` = эмуляция Vercel; Preview на `dev` **не** ждём.

**Анти-повторы (закон):** один полный suite в Phase 1 + один CI после push + один Vercel prod. Полный test на каждый commit 3.9 — **запрещён**. Конфликты снимать в 3.95 **до** PR. Перед build — место на диске / очистка `.next`. `--no-verify` не дефолт. Эталон хуков: `$MA_HUB_ROOT/templates/git-hooks-ma-deploy.md`. Эталон CI: `$MA_HUB_ROOT/templates/ci-ma-deploy.md` (минуты = job’ы × запуски на коммит).

**Где что:** тяжёлое локально (1–3.5); CI = только `{typecheck, test}` в **одном** job с одним install; любой другой CI job / дубль `pull_request` без форков = **блокер** (не «подождать и пойти»).

| Проверка | Phase | Где |
|----------|-------|-----|
| Bugbot / security / ponytail | 1 | skills `review-bugbot`, `review-security`, `ponytail-review` |
| typecheck / lint / i18n / tests | 1 (+ typecheck/test в CI 5) | scripts из плана |
| react-doctor | 2 | skill `react-doctor` |
| build + bundle-budget | 3 | `pnpm build`, `pnpm check:bundle-budget` |
| supabase | 3.5 | MCP/CLI если diff |
| Vercel prod + smoke | 7 | Vercel MCP + `agent-browser` |

## Жёсткие законы

1. **Ветки:** только `dev` → PR → `main`. Нет `dev` — создай от `main` до Phase 4.
2. **Merge:** только `gh pr merge --merge`. Squash/rebase **запрещены**.
3. **Commits только в конце локального цикла:** 1–3.5 по dirty tree; фиксы копятся без commit; после зелёных 1–3.5 → 3.9 сам (без «ок?» по коммитам) → 3.95 → один push.
4. **Полный test** — один раз в Phase 1 (+ thin CI). Тяжёлые хуки / дорогой CI (много job’ов, дубль PR) = блокер Phase 0.
5. **3.95 обязателен** до push и до PR. Конфликт «всплыл на PR» = ошибка процесса.
6. **React Doctor:** `npx react-doctor@latest --verbose --scope changed --blocking error`; baseline `.react-doctor/baseline.json`; monorepo — из React-корня.
7. Не подменять pipeline gstack land-flow; идеи smoke из `gstack/canary` — ок.

## Phase 0 — План + CI gate + hooks gate

Не начинай Phase 1 без плана. Skill: `verification-before-completion`.

1. Корень проекта / React-корень monorepo; `move_agent_to_root` если нужно.
2. Прочитай `.github/workflows/` (сверка с `templates/ci-ma-deploy.md`), `package.json` scripts, ветки, `supabase/` → `HAS_SUPABASE`, smoke URLs из Vercel.
3. Таблица «План проекта»: проверка → phase → в CI? → job → команда/skill.  
   Только локально: lint, i18n, doctor, build, budget, supabase.  
   `CI_JOBS_TO_WAIT` = тонкий job (эталон: один `typecheck-and-test`).
4. **Thin + cheap CI gate** (эталон `$MA_HUB_ROOT/templates/ci-ma-deploy.md` / `ci-ma-deploy.yml`):
   - **Состав:** только typecheck и/или test → ок. Любой другой job (lint, build, e2e, doctor…) → блокер «CI толще шаблона».
   - **Форма:** typecheck+test в **одном** job с одним install. Два+ параллельных job’а с повторным install → блокер «CI дороже эталона».
   - **События:** только `push` на `main`/`dev`. Одновременно `pull_request` на те же ветки **без** Local deviation «есть форки» → блокер «дубль событий на коммит».
   - **Concurrency:** желательно `cancel-in-progress`; нет — в auto добавить; в safe — замечание (не блокер, если остальное ок).
   - Нет workflow → Phase 5 skip.  
   Закрытие: привести workflow к эталону. **safe** — стоп; **auto** — правь в дереве без commit (в 3.9). После смены имени job — напомнить обновить required checks в GitHub. Не «подождать толстые/дорогие job’ы».
5. Ветки `dev`/`main`; нет `dev` — создай и запушь.
6. **Hooks gate** (как CI gate): эталон `templates/git-hooks-ma-deploy.md`. Тяжёлый pre-commit (полный test без `MA_ATOMIC_PACKING=1`) → блокер.  
   **safe** — стоп; **auto** — привести к шаблону в дереве. Не обходить `--no-verify`. Pre-push с полным suite один раз — ок.
7. Не упаковывай commits в Phase 0.

**Gate:** план готов + CI thin+cheap + hooks light (или auto уже поправил) → Phase 1.

## Phase 1 — Локальные проверки (волны)

Смотрим вместе, чиним по очереди. Команды — из плана. До Phase 2 — закрыть Critical/fails.

| Волна | Что | Параллель |
|-------|-----|-----------|
| **1A** | Bugbot ‖ Security ‖ Ponytail | да |
| **1B** | typecheck ‖ lint ‖ i18n ‖ tests | да |
| **1C** | сводка → таблицы | нет |
| Фиксы | после 1C; safe=стоп; auto=по одному без commit | нет |

Diff scope ревью: uncommitted + при необходимости `main..HEAD` (всё, что уедет в релиз). Не ждать 3.9.

**1A:** `review-bugbot`, `review-security` (+ `/security` при auth/PII), `ponytail-review` (читать SKILL с диска; нет файла → блокер `install-external-skills.sh`). Ponytail **никогда** не автофиксить.

**1B:** scripts из плана; Next typegen если нужен. Build **не** здесь.

**1C / loop:** safe — стоп на блокере; auto — fix в дереве, макс. 5 итераций. До 3.9 запрещено коммитить «чтобы скорее» / спрашивать план commits / один большой commit всего diff.

Ориентир порядка в 3.9: CI → hooks → feat/fix → critical fixes → (только после «чини») simplify → typecheck/lint/i18n/tests → doctor+baseline → build/budget → supabase.

## Phase 2 — React Doctor

Только локально. Skill `react-doctor`.  
Gate: `errorCount = 0`; при baseline — `newScore >= baseline + 1` (score 100 → достаточно 0 errors).  
Loop: auto fix в дереве / safe стоп. После успеха — обновить baseline (отдельный commit в 3.9).

## Phase 3 — Disk + build + bundle

После зелёных 1–2. `check-only` — build всё равно обязателен.

0. Свободное место (`df`). < ~3 GiB или был ENOSPC → безопасно `rm -rf .next .turbo` (не `.env`). < 1 GiB → стоп.
1. `pnpm build` — обязателен до 3.9/push. Fail → не push; auto fix в дереве.
2. `pnpm check:bundle-budget` если есть; fail auto → `performance-optimizer` → fix без commit.

**Gate:** build + budget OK → 3.5 или сразу 3.9.

## Phase 3.5 — Supabase

Skip если `HAS_SUPABASE=no` или в diff vs `main` нет `supabase/migrations|functions`.  
Если есть: проверить готовность прода / план выката. Safe — стоп без плана; auto — безопасный выкат по стандарту проекта (без секретов в чат). Иначе блокер.

**Gate:** OK/skip → **3.9** → **3.95** → 4.

## Phase 3.9 — Атомарная упаковка

Когда 1–3.5 зелёные. Агент **сам**, без спроса. При `check-only` — в конце успеха.

```bash
export MA_ATOMIC_PACKING=1   # на всю серию commits
```

Одна причина = один commit. Не полный test на каждый commit. Не `--no-verify` как обычный путь. Не `rebase -i` / `add -i`. Уже запушенное не переписывать. Грязное после «успеха» без 3.9 = ошибка.

## Phase 3.95 — main → dev до push/PR

Обязательно (skip только `check-only` без push).  
`fetch` → `checkout dev` → `merge origin/main` → конфликты **сейчас** → `merge-base --is-ancestor origin/main HEAD`.  
Запрещён анти-паттерн: открыть PR → увидеть conflict → ещё push/CI.

## Phase 4 — Один push `dev`

Skip при `check-only`. Предусловия: 3.9 чисто, 3.95 без конфликтов. Один `git push origin dev`. В статусе: ждать CI старт (< 1 мин).

## Phase 5 — CI на `dev`

Skip при `check-only` / нет workflow. Жди только `CI_JOBS_TO_WAIT`. Статус: обычно **~3–10 мин**.  
Fail → `ci-investigator` → debugging; auto: fix → 3.9-like → 3.95 если нужно → один push; safe: стоп. Preview не ждём. Один зелёный круг на релиз.

## Phase 6 — PR `dev` → `main` → merge

Skip при `skip-merge` / `check-only`. Только `--merge`. Конфликт после 3.95 → чинить через 3.95, не «на PR».  
Создать/найти PR → checks = `CI_JOBS_TO_WAIT` → при залипании skill `babysit` (safe: диагноз; auto: довести) → `gh pr merge --merge --delete-branch=false` → merge SHA → Phase 7.

## Phase 7 — Vercel production + smoke

Skip при `check-only` / `skip-merge`. Skills: `vercel-cli`, `deployments-cicd`; путь — **Vercel MCP**.

1. Production deployment на `main` = merge SHA → poll **READY** (~5–10 мин, timeout 20). ERROR → logs; auto: новый круг через `dev`+3.95; safe: стоп.
2. Smoke A: HTTP 200 `/` (+ `/api/health` если есть); `get_runtime_errors` ~15m.
3. Smoke B: `agent-browser` на 1–2 ключевых prod URL (не blank/5xx). Нет browser → ⚠️ в отчёте, не фейковый полный ✅.

**Gate:** READY + A OK + B OK (или явный fallback) = успех.

## Отчёт

Сначала «Статус процесса» (`standards/00-operating-model.md`): Сейчас / Что происходит / Ждём / Обычно занимает / Что от вас. При ожидании CI/Vercel — обновляй блок каждый раз.

Потом **короткие таблицы** (без простыней; строки по факту):

| # | Содержание |
|---|------------|
| 0 | План проекта + `CI_JOBS_TO_WAIT` / thin+cheap|thick|expensive / hooks light|heavy / `HAS_SUPABASE` / disk |
| 1 | Сводка простым языком: этап, safe/auto, блокеры?, commits, PR, merge, Vercel, smoke, ponytail |
| 2 | Шаги 1–3.5 / 3.9 / 3.95 — результат |
| 2b | Ponytail findings + `net` (если были) |
| 3 | React Doctor baseline → score/errors |
| 4 | Атомарные commits (SHA + сообщение) |
| 5 | Phase 4–7 статусы + ссылки |
| 6 | Блокеры (только если есть) |

**Этап работы** (одна фраза): проверки без упаковки / жду решения / упаковываю / main→dev / выкладываю / жду CI / жду Vercel / готово на проде / только проверки.

В **safe** при стопе — Таблица 6 + строка: нужны решения по блокерам («чини» / «не чинить» / «отложить»); ночной прогон — `/MA-deploy auto`.

Итог одной строкой простым языком.

## Стоп (не успех / не merge)

- Dirty tree в 0–3.5 — **не** стоп; commits только в 3.9
- Успех без 3.9 при грязном дереве; push/PR без 3.95
- Critical Bugbot/security; ponytail `net ≤ -80` в safe; нет `ponytail-review` на диске
- Fail typecheck/lint/i18n/test; doctor errors/score; disk < 1 GiB / повторный ENOSPC
- Fail build/budget — **push запрещён**
- Supabase в diff без плана; красный CI; CI толще thin или дороже эталона (много job’ов / дубль PR); тяжёлые хуки
- PR conflict / fail checks; push не в `dev`; Vercel не READY
- Секреты / `.env` / tokens в diff — **всегда стоп**, даже в auto

## Skills / MCP (маршрутизация)

| Когда | Что |
|-------|-----|
| Любой ✅ | `verification-before-completion` |
| 1A | `review-bugbot` ‖ `review-security` ‖ `ponytail-review` (не автофикс) |
| 1B | typecheck ‖ lint ‖ i18n ‖ tests |
| Фиксы auto | `systematic-debugging` (не ponytail) |
| 2 | `react-doctor` |
| 3 budget fail | `performance-optimizer` |
| 3.5 | Supabase MCP |
| 5 fail | `ci-investigator` |
| 6 stuck | `babysit` |
| 7 | Vercel MCP + `vercel-cli` / `deployments-cicd`; smoke B → `agent-browser` |
