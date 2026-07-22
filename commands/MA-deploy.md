---
description: "MA · Monster Automation — Полный цикл перед продом — локальные проверки, react doctor +1, build (≈ Vercel) перед push, push dev, CI, PR, merge, Vercel production"
argument-hint: [auto | check-only | skip-merge]
---

# MA-deploy

Проведи полный deploy-pipeline для **текущего проекта**. Я не программист — технические решения принимай сам **только в режиме auto** (или после явного «чини»). В **safe** — не чини блокеры сам: отчёт + ждать решения. Объясняй простым языком только блокеры и итог.

**Этот `/MA-deploy` — единственный оркестратор релиза.** Не подменяй его чужими deploy-workflow (см. запреты в конце).

## Hub + стандарты
Найди **ma-hub**: `~/.config/ma-hub/config` → `MA_HUB_ROOT`, иначе `~/ma-hub`.  
Перед релизом сверься с `$MA_HUB_ROOT/standards/05-release-and-quality.md`  
и (если есть) `docs/MA-STANDARDS.md` в проекте.

## Режимы починки (важно)

Сначала разбери `$ARGUMENTS` и зафиксируй режим:

| Режим | Как вызвать | Починка блокеров |
|-------|-------------|------------------|
| **safe** (по умолчанию) | `/MA-deploy`, `/MA-deploy check-only`, `/MA-deploy skip-merge` | **Не чинить самому.** Найти проблемы → таблица блокеров → **остановить и ждать** решения пользователя (чинить / не чинить / отложить) |
| **auto** | `/MA-deploy auto` (можно комбинировать: `auto check-only`, `auto skip-merge`) | Чинить **всё**, что блокирует деплой (**толстый CI → thin template**, ревью Critical, typecheck, lint, i18n, tests, react-doctor, build, bundle-budget, supabase, CI fails) **без вопросов и без паузы** — для ночных/уверенных прогонов. **Исключение:** ponytail/упрощения — только отчёт, не чинить |

**Правила safe (default):**
- Любой Critical из code review / security, **толстый CI**, любой fail typecheck/lint/i18n/tests/doctor/build/bundle/supabase/CI → **стоп**, заполнить Таблицу 6, одна строка «жду решения», **не** править код, **не** commit, **не** push
- Ponytail: `net ≤ -80` → **стоп** (Таблица 6); меньший объём — только отчёт. **Никогда** не применять упрощения без явного «чини»
- Important/Minor — только в отчёт, не чинить
- Продолжай pipeline только если блокеров нет **или** пользователь явно сказал «чини» / «продолжай» / выбрал пункты

**Правила auto:**
- Не спрашивай подтверждений на починку
- Перед фиксом сначала найди root cause (`systematic-debugging`), потом loop: fix → атомарный commit → re-check, максимум 5 итераций на фазу
- Если не сходится за 5 итераций — стоп с отчётом (даже в auto)
- **Исключение — ponytail/упрощения:** **никогда** не применять автоматически (даже при `net ≤ -80`). Только отчёт; при `net ≤ -80` пометить в сводке и **продолжить** релиз

## Pipeline (без Vercel Preview)

```
/MA-deploy
├── Phase 1    ← Локально: Bugbot + security + ponytail-review, typecheck, lint, i18n, tests
├── Phase 2    ← react-doctor (только локально)
├── Phase 3    ← build (≈ Vercel) + bundle-budget — финальный gate перед push
├── Phase 3.5  ← Supabase gate (миграции / edge) если есть в diff
├── Phase 4    ← push dev
├── Phase 5    ← CI: только job'ы из workflow (цель: typecheck + test)
├── Phase 6    ← PR dev → main → merge
└── Phase 7    ← Vercel production READY + smoke (HTTP + browser)
```

**Build — последний локальный шаг прямо перед push** (после него — только Supabase gate, если нужен). Успешный `pnpm build` (Phase 3) эмулирует сборку Vercel на чистой машине, поэтому отдельный Vercel Preview на `dev` не ждём.

## Утверждённый план (шаблон для всех проектов)

Структура фаз **фиксирована**. Состав локальных шагов и список CI job'ов **определяется по проекту** в Phase 0.

| Фаза | Что делает | Где |
|------|------------|-----|
| 1 | Bugbot + security + ponytail-review, typecheck, lint, i18n, tests | локально |
| 2 | react-doctor | локально |
| 3 | build (≈ Vercel) + bundle-budget | локально, **перед push** |
| 3.5 | Supabase: миграции / edge (если есть в diff) | локально / Supabase MCP |
| 4 | push `dev` | git |
| 5 | только то, что реально есть в `.github/workflows/` | CI (страховка) |
| 6 | PR `dev` → `main` → merge | GitHub |
| 7 | Vercel production READY + smoke | Vercel |

**Правило разделения локально / CI:**
- Всё тяжёлое и качественное — **локально** (Phase 1–3.5): lint, i18n, react-doctor, build, bundle-budget, supabase gate
- В CI — **только тонкий шаблон**: job'ы из набора `{typecheck, test}` и больше ничего
- Vercel Preview на `dev` — **никогда не ждём**
- **CI толще шаблона = блокер** (не предупреждение): любой job вне `{typecheck, test}` (lint, build, i18n, doctor, e2e, …) → pipeline **не идёт дальше**, пока workflow не приведён к тонкому шаблону. Не «отметить и продолжить».

### Эталон «облегчённого CI» (fleet_manager_core и новые проекты)

| Проверка | Где | Как |
|----------|-----|-----|
| Code review (Bugbot) | Phase 1 | skill `review-bugbot` (Cursor-native) |
| Security review | Phase 1 | skill `review-security` (Cursor-native; + `/security` при auth/PII) |
| Ponytail (простота) | Phase 1 | skill `ponytail-review` (external, см. `registry/external-skills.md`) |
| Typecheck | Phase 1 + Phase 5 CI | `pnpm typecheck` |
| Lint | Phase 1 only | `pnpm lint` |
| i18n | Phase 1 only | `pnpm i18n:*` |
| Tests | Phase 1 + Phase 5 CI | `pnpm test` |
| React Doctor | Phase 2 only | skill `react-doctor` |
| Build (≈ Vercel) | Phase 3 only | `pnpm build` |
| Bundle budget | Phase 3 only | `pnpm check:bundle-budget` |
| Supabase | Phase 3.5 | MCP / CLI если diff затрагивает |
| Vercel production | Phase 7 | MCP + smoke |

`/MA-deploy` — **единственное место полной проверки**. CI — тонкая страховка.

Аргумент `$ARGUMENTS` (можно комбинировать через пробел, порядок не важен):
- пусто — полный цикл до merge + Vercel production READY, режим **safe** (без автопочинки)
- `auto` — тот же полный цикл, но **автопочинка всех блокеров без вопросов**
- `check-only` — только Phase 1–3.5 (все локальные проверки, включая build + supabase gate), без push/CI/PR/production; починка по режиму (safe/auto)
- `skip-merge` — до Phase 5 включительно (push + CI на dev), merge и production Vercel — нет; починка по режиму (safe/auto)
- примеры: `/MA-deploy auto`, `/MA-deploy auto check-only`, `/MA-deploy skip-merge`, `/MA-deploy auto skip-merge`

## Жёсткие правила (без исключений)

**Ветки:** всегда только `dev` → PR → `main`. Никаких push напрямую в main, feature → main, master вместо dev. Если ветки `dev` нет — создай от `main` перед Phase 4.

**React Doctor:** следуй skill `react-doctor`. Команда всегда:
```bash
npx react-doctor@latest --verbose --scope changed --blocking error
```
Baseline: `.react-doctor/baseline.json`. Если файла нет — создай после первого успешного Phase 2. Не используй `pnpm doctor:changed` и project-specific doctor scripts.

**Monorepo:** запускай react-doctor из корня React-приложения (например `web/` в appartment-finder), baseline — рядом с этим корнем.

**Запрещено подменять pipeline:**
- НЕ вызывай `gstack/ship`, `gstack/land-and-deploy`, `gstack/setup-deploy` как замену `/MA-deploy`
- НЕ меняй модель веток на feature → main
- Можно брать **идеи** smoke из `gstack/canary`, но не запускать весь gstack land-flow

## Phase 0 — Подготовка + сверка CI (обязательно перед Phase 1)

**Правило:** не начинай Phase 1, пока не построен **план проекта** по фактическому CI и `package.json`. Используй skill `verification-before-completion`.

1. Определи корень проекта (если агент не в нём — `move_agent_to_root`). Monorepo: React-корень (`web/`, `apps/…`) + путь к `.github/workflows/`.

2. **Прочитай CI, scripts, Supabase:**
   - все файлы в `.github/workflows/` (минимум `ci.yml`)
   - `package.json` → секция `scripts`
   - ветки: `git branch -a`
   - есть ли `supabase/` (migrations, functions) или Supabase в зависимостях → отметь `HAS_SUPABASE=yes/no`
   - smoke URLs: из таблицы Phase 7 или из Vercel project settings

3. **Построй таблицу «План проекта»** (покажи пользователю в начале отчёта):

   | Проверка | Phase (локально) | В CI? | CI job name | Команда / skill |
   |----------|------------------|-------|-------------|-----------------|
   | … | 1 / 2 / 3 / 3.5 / — | да/нет | `typecheck` | `pnpm typecheck` |

   Алгоритм:
   - **CI job'ы** — имена `jobs.*` из workflow (`typecheck`, `test`, `lint`, `build`…)
   - **Локальные команды** — из `package.json` scripts; если script нет — шаг `skip`
   - **Дублирование:** `typecheck` / `test` — локально в Phase 1 **и** в Phase 5 (страховка)
   - **Только локально** (никогда не в CI): lint, i18n, react-doctor, build, bundle-budget, supabase gate
   - **Phase 5** — жди **только** `CI_JOBS_TO_WAIT` = разрешённые job'ы тонкого шаблона

4. **Сверка с тонким шаблоном CI (жёсткий gate):**

   **Разрешены только** job'ы, которые по смыслу = `typecheck` и/или `test` (имена могут быть `typecheck`, `types`, `test`, `tests`, `unit` — суть важнее имени).

   | Состояние CI | Вердикт | Действие |
   |--------------|---------|----------|
   | Только `typecheck` и/или `test` (один или оба, если script есть) | ✅ тонкий шаблон | `CI_JOBS_TO_WAIT` = эти job'ы → дальше Phase 1 |
   | Есть **любой другой** job (lint, build, i18n, doctor, e2e, format, …) | ❌ **блокер** | **Стоп.** Не Phase 1, не push, не merge. Таблица 6: «CI толще шаблона» |
   | Нет `.github/workflows/` | ✅ ok | Phase 5 skip; весь gate локально (Phase 1–3.5) |

   **Закрытие блокера «CI толще шаблона»** (единственный допустимый путь вперёд):
   - Упрости `.github/workflows/*` до тонкого шаблона: оставь только `typecheck` + `test` (или один из них, если второго script нет в `package.json`)
   - Удали/не держи в CI: lint, build, i18n, react-doctor, bundle и прочее — это только локально в `/MA-deploy`
   - **safe:** стоп + Таблица 6, ждать «чини» / решения. Не править workflow без явного согласия
   - **auto:** сразу упрости workflow → атомарный commit `chore(ci): thin to typecheck+test` → пересчитай `CI_JOBS_TO_WAIT` → только потом Phase 1
   - Пока блокер открыт — **запрещено** «подождать все толстые job'ы и пойти дальше»

5. Убедись что существуют ветки `dev` и `main`. Если `dev` нет:
   ```bash
   git fetch origin
   git checkout main && git pull
   git checkout -b dev && git push -u origin dev
   ```

6. Зафиксируй стартовое состояние: текущая ветка, uncommitted changes, последний CI status на `dev`, `CI_JOBS_TO_WAIT`, `HAS_SUPABASE`, список smoke URL.

**Gate Phase 0:** таблица «План проекта» заполнена **и** CI = тонкий шаблон (или workflow отсутствует) → можно Phase 1. Иначе — стоп на блокере CI.

## Phase 1 — Локальные проверки

**Правило:** не переходи к Phase 2, пока не закрыты все Critical / fails. Команды — из **«План проекта»**. Перед каждым ✅ — skill `verification-before-completion`.

Порядок:

1. **Code review — всегда Bugbot (read-only)**
   - Прочитай и **следуй skill `review-bugbot`**: один subagent `bugbot`, `Diff: branch changes` (vs base/`main`), если есть только грязное дерево без коммитов — `uncommitted changes`
   - Critical из Bugbot = блокер деплоя; Important/Minor = только в отчёт
   - **safe:** Critical → Таблица 6 + стоп. **Не** править код
   - **auto:** Critical → `systematic-debugging` → минимальный fix → атомарный commit

2. **Security review — всегда (read-only)**
   - Прочитай и **следуй skill `review-security`**: один subagent `security-review`, тот же Diff scope
   - Если в проекте/diff есть **auth / PII / платежи / роли** — дополнительно прогони логику команды `/security` (глубокий API/IDOR pass) и смержи Critical в одну Таблицу 6
   - Critical = блокер; **safe** стоп / **auto** fix+commit

3. **Ponytail review — всегда (read-only, внешний skill)**
   - **Не копировать** текст skill в отчёт/команду. Источник: `registry/external-skills.md` → пакет `dietrichgebert/ponytail`
   - Разреши путь (первый найденный):
     1. `~/.agents/skills/ponytail-review/SKILL.md`
     2. `~/.cursor/skills/ponytail-review/SKILL.md`
     3. `~/.claude/skills/ponytail-review/SKILL.md`
   - **Прочитай** актуальный `SKILL.md` и следуй ему целиком (формат находок, теги, `net: -N`)
   - Scope как у Bugbot: `branch changes` vs `main`; если только грязное дерево без коммитов — uncommitted changes
   - Если `SKILL.md` не найден → блокер: «внешний skill `ponytail-review` не установлен» → Таблица 6: запустить `$MA_HUB_ROOT/bootstrap/install-external-skills.sh` (или weekly). **Не** подставлять замороженную копию из памяти
   - Запиши в отчёт: список находок (одна строка на finding по формату skill) + итоговый `net: -N` (или `Lean already. Ship.`)
   - **Политика (не автофикс):**
     - Находки **никогда** не применяются автоматически (ни safe, ни auto) — только отчёт
     - Если `Lean already. Ship.` или `net` отсутствует / `net: 0` / `net` > -80 (например `-20`) → ✅ только отчёт, не блокер
     - Если `net ≤ -80` (например `-80`, `-120`):
       - **safe:** блокер → Таблица 6 + стоп; ждать «чини» / «не чинить» / «продолжай» / «отложить»
       - **auto:** **не чинить**, пометить в Таблице 1 (`Ponytail net`) и Таблице 2, **продолжить** pipeline
   - Чинить ponytail только после явного «чини» / выбора пунктов (атомарный commit `refactor(simplify): …` на пункт или группу)

4. **Typecheck** — обязательно локально (если есть script или CI job `typecheck`)
   - Next.js с typegen: `npx next typegen && pnpm typecheck`
   - иначе: команда из «План проекта»
   - fail → **safe:** стоп; **auto:** `systematic-debugging` → fix + commit

5. **Lint** — из «План проекта». Обычно **только локально** (Phase 1).
   - fail → safe стоп / auto fix+commit

6. **i18n** — из «План проекта», если scripts есть. **Только локально**:
   - типично: `i18n:check`, `i18n:cyrillic`, `i18n:parity`, `i18n:ui`
   - Пропусти если scripts нет
   - fail → safe стоп / auto fix+commit

7. **Tests** — из «План проекта». Обязательно локально; если есть CI job `test` — дублируется в Phase 5
   - fail → safe стоп / auto fix+commit

**Build здесь не запускаем** — он в Phase 3.

**Loop (только auto):** Critical/fail → root cause (`systematic-debugging`) → минимальный diff → **атомарный commit** → повтори упавшие шаги. Максимум 5 итераций.

**Safe:** loop запрещён. Любой блокер → стоп до ответа пользователя.

### Атомарные коммиты (только когда есть право чинить)

В **safe** без явного «чини» — **не создавай** commits с фиксами.

В **auto** (или после «чини»): после **каждого** логически завершённого исправления — отдельный commit. Никогда не копи всё в один «deploy fix».

**Правила:**
- Один commit = одна причина
- Commit только когда шаг локально зелёный
- Сообщение: `<type>(<scope>): <что и зачем>` — `fix`, `refactor`, `test`, `chore`, `perf`, `a11y`
- Не смешивай unrelated files
- `.react-doctor/baseline.json` — отдельный commit после Phase 2
- config / CI / deploy command — отдельно от code fixes

**Порядок коммитов в loop:**
0. (Phase 0, если CI толстый) `chore(ci): thin to typecheck+test` — **только** workflow, до любых code fixes
1. fix critical Bugbot / security → commit
2. (только после явного «чини») refactor ponytail findings → commit(s) `refactor(simplify): …`
3. fix typecheck → commit
4. fix lint → commit
5. fix i18n → commit
6. fix tests → commit
7. fix react-doctor errors → commit (по одной rule/fix)
8. update baseline → `chore(react-doctor): bump baseline score X → Y`
9. fix build / bundle-budget → commit (Phase 3)
10. supabase migrations/functions → отдельный commit (Phase 3.5)

Перед Phase 4: `git log --oneline main..HEAD` → Таблица 4.

## Phase 2 — React Doctor (loop + минимум +1 к score)

**Только локально.** Следуй skill **`react-doctor`** (команды и triage — из skill). Дополнительно — ваши gate-правила ниже.

**Gate:**
- `errorCount` MUST be 0 (`--blocking error`)
- Если baseline есть: `newScore >= baseline.score + 1` (score 100 → достаточно 0 errors без регрессии)
- Score не должен упасть vs baseline

1. Прочитай `.react-doctor/baseline.json` если есть:
   ```json
   { "score": 0, "scope": "changed", "base": "main", "minImprovement": 1, "updatedAt": "YYYY-MM-DD" }
   ```
   Нет файла → baseline = null (первый раз: 0 errors + записать score).

2. Запуск:
   ```bash
   npx react-doctor@latest --verbose --scope changed --blocking error
   npx react-doctor@latest --json --scope changed --base main
   ```

3. **Loop:** errors или score ниже цели:
   - **auto:** fix → атомарный commit → re-run (каждое doctor-fix — свой commit). При сложных ошибках — playbook из skill `react-doctor`
   - **safe:** стоп + Таблица 6

4. После успеха:
   ```bash
   node scripts/update-react-doctor-baseline.mjs
   ```
   Monorepo: скрипт в React-корне (`web/scripts/…`). Затем **отдельный** commit baseline.

## Phase 3 — Build (≈ Vercel) + bundle budget (финальный gate перед push)

Команды — из «План проекта». После зелёных Phase 1–2. При `check-only` build всё равно обязателен.

1. **Build** — `pnpm build`. **Обязательно локально, прямо перед push.**
   - Эмулирует production-сборку Vercel
   - fail → **не пушь**; safe стоп / auto fix (`systematic-debugging`)

2. **Bundle budget** — `pnpm check:bundle-budget` сразу после build.
   - Только локально; пропусти если script нет
   - При fail в **auto**: сначала skill **`performance-optimizer`** (Vercel), затем минимальный fix + commit `perf(bundle): …` → повтори build+budget
   - **safe:** стоп + Таблица 6

**Gate:** build READY + bundle-budget OK → Phase 3.5 (или Phase 4, если supabase skip).

## Phase 3.5 — Supabase gate (база / edge не должны отстать от фронта)

Пропусти, если `HAS_SUPABASE=no` **или** в diff vs `main` нет изменений в:
- `supabase/migrations/**`
- `supabase/functions/**`
- связанных SQL / edge entrypoints

Если изменения **есть**:

1. Запиши в отчёт: «база/функции — нужно выкатить»
2. **Проверка готовности (обязательный шаг, не молчаливый skip):**
   - Есть ли новые/изменённые миграции и применены ли они к **production** (или есть явный release-процесс в проекте)
   - Edge functions: нужен ли `deploy_edge_function` / CLI deploy
3. Используй **Supabase MCP** (`plugin-supabase-supabase`): `list_migrations`, при необходимости `get_advisors` / docs — **без разрушительных действий в safe без явного «чини»**
4. Политика:
   - **Блокер**, если в diff есть миграции/functions, а прод-схема/functions явно не готовы и нет подтверждённого плана выката
   - **safe:** стоп + Таблица 6 («сайт новый, база старая — риск»)
   - **auto:** выполни безопасный выкат по принятому в проекте способу (миграции / edge), атомарные commits только для кода репозитория; схемы на remote — только если это стандарт проекта и не требует секретов в чат. Если нельзя безопасно — стоп с отчётом даже в auto
5. Если supabase-изменений в diff нет → строка в отчёте: «база/функции — не нужно»

**Gate:** supabase OK или skip → можно Phase 4.

## Phase 4 — Push на dev

Пропусти если `check-only`.

1. **Не создавай новых commits здесь** — fixes уже атомарно в Phase 1–3.5. Uncommitted diff = ошибка pipeline.
2. Всё на `dev`:
   - feature → merge/rebase в `dev`
   - `git checkout dev && git pull && git merge <feature>`
   - `git push origin dev`
3. Tip SHA + `git log --oneline main..dev` → отчёт.

## Phase 5 — CI на dev зелёный

Пропусти если `check-only` или нет workflow.

**Предусловие:** CI уже тонкий шаблон (закрыто в Phase 0). Если после push в workflow снова появились лишние job'ы — снова блокер, назад в Phase 0 logic, **не** ждать лишние job'ы.

Жди только `CI_JOBS_TO_WAIT` = `{typecheck, test}` (что реально есть в тонком workflow).

```bash
gh run list --branch dev --limit 3
gh run watch <run-id> --exit-status
```

- Fail:
  1. Сначала subagent **`ci-investigator`** (один упавший check → короткий root-cause)
  2. При необходимости углуби через `systematic-debugging` + `gh run view --log-failed`
  3. **auto:** fix → атомарный commit на dev → push → watch
  4. **safe:** стоп + Таблица 6
- CI не триггерится на `dev` → добавь `dev` в workflow triggers (это часть тонкого шаблона), commit, push

**Gate:** все `CI_JOBS_TO_WAIT` green → Phase 6. Preview не ждём.

## Phase 6 — PR dev → main → merge

Пропусти merge если `skip-merge` или `check-only`.

1. PR **dev → main**:
   ```bash
   gh pr list --head dev --base main --state open
   gh pr create --base main --head dev --title "..." --body "..."
   ```
2. Дождись green PR checks = `CI_JOBS_TO_WAIT`:
   ```bash
   gh pr checks <number> --watch
   ```
3. Если PR **застрял** (конфликты, висящие review-комменты, красный CI после merge main): следуй skill **`babysit`** (в рамках safe/auto: в safe — только диагноз в Таблицу 6; в auto — чинить и довести до merge-ready). Не используй babysit как замену всего Phase 6.
4. Merge:
   ```bash
   gh pr merge <number> --squash --delete-branch=false
   ```
5. Запиши merge SHA на `main` → Phase 7.

## Phase 7 — Vercel Production на main (green)

Пропусти если `check-only` или `skip-merge`.

**Цель:** production **READY** + smoke.

При работе с Vercel читай skills **`vercel-cli`** и **`deployments-cicd`** (правильные флаги, inspect, logs). Основной путь — **Vercel MCP**; CLI — fallback.

### 1. Найди production deployment

- Environment: **production**
- Branch: `main`
- Commit SHA = merge из Phase 6

**MCP:** `list_deployments` → filter production + githubCommitSha → `get_deployment` (READY?)

**CLI fallback** (по `vercel-cli`):
```bash
vercel ls --environment=production --scope <team-slug>
vercel inspect <prod-deployment-url>
```

### 2. Poll до green

- Жди **READY** (timeout 20 мин)
- ERROR → MCP `get_deployment_build_logs` (errorsOnly) → блокер
  - **auto:** fix → Phase 3–6 заново (новый PR через `dev`)
  - **safe:** стоп + Таблица 6

### 3. Production smoke (два слоя)

| Проект | URL для smoke |
|--------|---------------|
| salam-dirham | `https://salamdrhm.com/` |
| roasters | prod URL / `qr.roasterscoffee.ae` |
| appartment-finder | prod URL из Vercel |
| fleet_manager_core | prod URL из Vercel |

**Слой A — быстрый (всегда):**
- HTTP 200 на `/` (и `/api/health` если есть)
- MCP `get_runtime_errors` (since: 15m) — 0 new critical clusters

**Слой B — браузер (всегда на 1–2 ключевых URL из таблицы / Vercel):**
- Следуй skill **`agent-browser`**: открой prod URL, убедись что страница реально рендерится (не blank/5xx/клиентский краш)
- Идеи мониторинга (console errors, явный broken UI) можно брать из **`gstack/canary`**, но **не** запускай весь gstack land/canary-pipeline
- Если browser tooling недоступен — зафиксируй ⚠️ в отчёте и опирайся на слой A; не считай это автоматическим ✅ «полный smoke»

**Gate:** production READY + слой A OK + слой B OK (или явно отмеченный fallback) = deploy завершён.

## Финальный отчёт — только таблицы

Ответ **обязательно** таблицами + одна строка итога. Без простыней.

### Таблица 0 — План проекта (из Phase 0)

| Проверка | Phase | В CI? | CI job | Команда / skill | Соответствие шаблону |
|----------|-------|-------|--------|-----------------|----------------------|
| Bugbot | 1 | нет | — | `review-bugbot` | ✅ |
| Security | 1 | нет | — | `review-security` | ✅ |
| Ponytail | 1 | нет | — | `ponytail-review` (external) | ✅ |
| Typecheck | 1 + 5 | да | `typecheck` | `pnpm typecheck` | ✅ / ❌ блокер |
| … | … | … | … | … | … |
| Supabase | 3.5 | — | — | MCP / skip | ✅ |
| CI шаблон | 0 | — | только typecheck+test | thin template | ✅ / ❌ блокер |

`CI_JOBS_TO_WAIT`: `typecheck`, `test` (только эти)  
`CI_TEMPLATE`: thin / **too-thick (блокер)** / none  
`HAS_SUPABASE`: yes/no

### Таблица 1 — Сводка

| Поле | Значение |
|------|----------|
| Проект | … |
| Режим | full / check-only / skip-merge + safe / auto |
| Починка | safe (жду решения) / auto (без вопросов) |
| Статус | ✅ Успех / ⚠️ Частично / ❌ Остановлен / ⏸ Жду решения |
| Commits (атомарных) | N |
| Tip SHA на dev | `<sha>` |
| PR | `#N` + URL или «не создан» |
| Merge в main | да / нет / ожидает |
| База/функции | не нужно / нужно / сделано / блокер |
| CI шаблон | thin / **too-thick (блокер)** / none |
| Vercel Production (main) | READY / ERROR / skip |
| Smoke | HTTP+runtime / +browser / partial |
| Ponytail net | `Lean` / `-N` (блокер safe если ≤ -80) |

### Таблица 2 — Phase 1–3.5 (локальные проверки)

| Шаг | Phase | Команда / skill | Результат | Critical | Important | Minor |
|-----|-------|-----------------|-----------|----------|-----------|-------|
| Bugbot | 1 | `review-bugbot` | ✅ / ❌ | N | N | N |
| Security | 1 | `review-security` | ✅ / ❌ | N | N | N |
| Ponytail | 1 | `ponytail-review` | ✅ / ❌ / ⏸ | — | net≤-80 (safe) | findings |
| Typecheck | 1 | `…` | ✅ / ❌ / skip | — | — | — |
| Lint | 1 | `…` | ✅ / ❌ / skip | — | — | — |
| i18n | 1 | `…` | ✅ / ❌ / skip | — | — | — |
| Tests | 1 | `…` | ✅ / ❌ / skip | — | — | — |
| React Doctor | 2 | `react-doctor` | ✅ / ❌ / skip | — | — | — |
| Build (≈ Vercel) | 3 | `pnpm build` | ✅ / ❌ / skip | — | — | — |
| Bundle budget | 3 | `…` / `performance-optimizer` | ✅ / ❌ / skip | — | — | — |
| Supabase | 3.5 | MCP / skip | ✅ / ❌ / skip | — | — | — |
| Loop итераций | — | — | N из 5 | — | — | — |

### Таблица 2b — Ponytail (если были находки)

| # | Finding (формат skill) | net вклад |
|---|------------------------|-----------|
| 1 | `file:L12: delete: …` | … |

Итог: `net: -N` или `Lean already. Ship.`  
Порог блокера (safe): `net ≤ -80`.

### Таблица 3 — Phase 2 (React Doctor)

| Метрика | Было (baseline) | Стало | Цель | Статус |
|---------|-----------------|-------|------|--------|
| Score | X / нет baseline | Y | X+1 или 0 errors (первый раз) | ✅ / ❌ |
| Errors | — | 0 | 0 | ✅ / ❌ |
| Warnings | — | N | — | info |

### Таблица 4 — Атомарные commits

| # | SHA | Сообщение | Phase |
|---|-----|-----------|-------|
| 1 | `abc1234` | fix(auth): … | 1 |
| 2 | `def5678` | chore(react-doctor): bump baseline 97 → 98 | 2 |

### Таблица 5 — Phase 4–7 (deploy)

| Phase | Действие | Статус | Ссылка / детали |
|-------|----------|--------|-----------------|
| 4 Push dev | `git push origin dev` | ✅ / ❌ / skip | commit `<sha>` |
| 5 CI dev | `CI_JOBS_TO_WAIT` (+ `ci-investigator` при fail) | ✅ / ❌ / skip | run URL |
| 6 PR | dev → main | ✅ / ❌ / skip | PR URL |
| 6 Merge | squash (+ `babysit` если застрял) | ✅ / ❌ / skip | merge SHA |
| 7 Vercel Production | main → READY | ✅ / ❌ / skip | prod URL |
| 7 Smoke A | HTTP + runtime errors | ✅ / ❌ / skip | routes |
| 7 Smoke B | `agent-browser` | ✅ / ❌ / ⚠️ fallback | URLs |

### Таблица 6 — Блокеры (если есть)

| # | Severity | Проблема | Где | Что делать |
|---|----------|----------|-----|------------|
| 1 | Critical | … | file:line | … |

Если блокеров нет — таблицу 6 не показывай.

В режиме **safe** при стопе всегда покажи Таблицу 6 и строку:
«⏸ Жду решения: напишите „чини“ / „не чинить“ / „отложить“ (или выберите пункты из таблицы). Для ночного прогона без паузы используйте `/MA-deploy auto`.»

**Итог одной строкой:** «Deploy завершён: main + Vercel production READY» / «Deploy остановлен на Phase N: …» / «⏸ Жду решения по блокерам (safe)» / «check-only пройден, push не выполнялся».

## Стоп-условия (не мержить / не считать успехом)

- Critical из Bugbot / security не закрыт (safe = стоп; auto = чинить до лимита)
- Ponytail `net ≤ -80` в **safe** не закрыт решением пользователя (в **auto** — не стоп, только отчёт)
- Внешний skill `ponytail-review` отсутствует на диске (нужен `install-external-skills.sh`)
- typecheck / lint / i18n / test fail (Phase 1)
- React Doctor errors > 0 или score < baseline + 1 (Phase 2)
- build / bundle-budget fail (Phase 3) — **push запрещён**
- Supabase: в diff есть миграции/functions, прод не готов, нет безопасного плана (Phase 3.5)
- CI на dev красный (`CI_JOBS_TO_WAIT`)
- **CI толще тонкого шаблона** (любой job кроме `typecheck` / `test`) — **стоп**, пока workflow не упрощён; нельзя «подождать и пойти дальше»
- PR conflicts или failing required checks
- Push не в `dev` или PR не dev → main
- **Vercel Production (main) не READY**
- Секреты / `.env` / tokens в diff — **всегда стоп**, даже в `auto`

## Skills / MCP для агента (обязательная маршрутизация)

| Когда | Что использовать |
|-------|------------------|
| Любой ✅ в отчёте | `verification-before-completion` |
| Phase 1 review | **`review-bugbot`** (всегда; Cursor-native) |
| Phase 1 security | **`review-security`** (всегда; Cursor-native); плюс `/security` при auth/PII |
| Phase 1 простота | **`ponytail-review`** (всегда; external — читать с диска, см. `registry/external-skills.md`); **не автофикс** |
| Phase 1–5 фиксы (auto) | `systematic-debugging` до патча (**кроме** ponytail) |
| Phase 2 | **`react-doctor`** |
| Phase 3 bundle fail | **`performance-optimizer`** (Vercel) |
| Phase 3.5 | **Supabase MCP** (`list_migrations`, advisors, edge deploy по политике) |
| Phase 5 CI fail | subagent **`ci-investigator`**, затем debugging |
| Phase 6 PR застрял | **`babysit`** |
| Phase 7 Vercel | **Vercel MCP** + skills **`vercel-cli`**, **`deployments-cicd`** |
| Phase 7 smoke B | **`agent-browser`** (идеи из `gstack/canary` — опционально) |

**Vercel MCP** (`plugin-vercel-vercel`) — Phase 7:
- `list_deployments`, `get_deployment`, `get_deployment_build_logs`
- `web_fetch_vercel_url`, `get_runtime_errors`

**Не использовать как замену `/MA-deploy`:** `gstack/ship`, `gstack/land-and-deploy`, `gstack/setup-deploy`.
