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

Правила анти-повторов, Phase 3.95, диск перед build и ETA в статусе — **универсальный закон для всех проектов** с `/MA-deploy`, не локальная настройка одного продукта.

## Режимы починки (важно)

Сначала разбери `$ARGUMENTS` и зафиксируй режим:

| Режим | Как вызвать | Починка блокеров |
|-------|-------------|------------------|
| **safe** (по умолчанию) | `/MA-deploy`, `/MA-deploy check-only`, `/MA-deploy skip-merge` | **Не чинить самому.** Найти проблемы → таблица блокеров → **остановить и ждать** решения пользователя (чинить / не чинить / отложить) |
| **auto** | `/MA-deploy auto` (можно комбинировать: `auto check-only`, `auto skip-merge`) | Чинить **всё**, что блокирует деплой (**толстый CI → thin template**, ревью Critical, typecheck, lint, i18n, tests, react-doctor, build, bundle-budget, supabase, CI fails) **без вопросов и без паузы** — для ночных/уверенных прогонов. **Исключение:** ponytail/упрощения — только отчёт, не чинить |

**Правила safe (default):**
- Любой Critical из code review / security, **толстый CI**, любой fail typecheck/lint/i18n/tests/doctor/build/bundle/supabase/CI → **стоп**, заполнить Таблицу 6, одна строка «жду решения», **не** править код, **не** commit, **не** push
- Грязное дерево в начале — **не** блокер и **не** повод коммитить. Идём в Phase 1 по рабочему дереву
- Ponytail: `net ≤ -80` → **стоп** (Таблица 6); меньший объём — только отчёт. **Никогда** не применять упрощения без явного «чини»
- Important/Minor — только в отчёт, не чинить
- Продолжай pipeline только если блокеров нет **или** пользователь явно сказал «чини» / «продолжай» / выбрал пункты

**Правила auto:**
- Не спрашивай подтверждений на починку
- Перед фиксом сначала найди root cause (`systematic-debugging`), потом loop: fix **в рабочем дереве (без commit)** → re-check, максимум 5 итераций на фазу
- Если не сходится за 5 итераций — стоп с отчётом (даже в auto)
- **Исключение — ponytail/упрощения:** **никогда** не применять автоматически (даже при `net ≤ -80`). Только отчёт; при `net ≤ -80` пометить в сводке и **продолжить** релиз
- Атомарные commits — **только** в Phase 3.9 (после зелёных локальных шагов), без спроса

## Pipeline (без Vercel Preview)

```
/MA-deploy
├── Phase 0    ← План проекта + тонкий CI + аудит тяжёлых git-хуков
├── Phase 1    ← Волны: ревью ‖ проверки → потом фиксы по очереди (копим в дереве)
├── Phase 2    ← react-doctor (только локально; фиксы без commit)
├── Phase 3    ← диск / .next → build (≈ Vercel) + bundle-budget
├── Phase 3.5  ← Supabase gate (миграции / edge) если есть в diff
├── Phase 3.9  ← Атомарная упаковка (без полного test на каждый commit)
├── Phase 3.95 ← merge origin/main → dev, конфликты ДО push/PR
├── Phase 4    ← один push dev
├── Phase 5    ← CI: только job'ы из workflow (цель: typecheck + test) — один круг
├── Phase 6    ← PR dev → main → merge (уже без конфликтов с main)
└── Phase 7    ← Vercel production READY + smoke (HTTP + browser)
```

**Локальный порядок перед push:** проверки/правки (1–3.5) → **атомарная упаковка (3.9)** → **синхронизация с main (3.95)** → push (4). Успешный `pnpm build` (Phase 3) эмулирует сборку Vercel; отдельный Vercel Preview на `dev` не ждём.

### Анти-повторы (чтобы релиз не растягивался)

**Закон для всех проектов** с `/MA-deploy` (не опция и не «только Fast Lease»).

Цель: **один** полный локальный suite (Phase 1) + **один** CI после push + **один** Vercel production. Повторы из‑за хуков/конфликтов — баг процесса.

| Риск | Правило |
|------|---------|
| Полный vitest/test на каждый атомарный commit | **Запрещено.** Полный suite — Phase 1 (и тонкий CI Phase 5). В Phase 3.9 — только лёгкий pre-commit |
| Тяжёлый pre-push дважды (фича, потом снова после merge main) | Сначала **3.95** (main → dev), потом **один** push |
| Конфликт обнаружен только на PR | **Запрещено.** Конфликты снимать в 3.95 **до** открытия PR |
| Build упал на ENOSPC | Перед Phase 3 — чек места + безопасная очистка `.next` |
| Слепой `--no-verify` | **Не** дефолт. Править стратегию хуков (см. `templates/git-hooks-ma-deploy.md`) |

**Thin CI и локальный build не ослаблять:** CI = только `{typecheck, test}`; `pnpm build` перед push остаётся обязательным.

## Утверждённый план (шаблон для всех проектов)

Структура фаз **фиксирована**. Состав локальных шагов и список CI job'ов **определяется по проекту** в Phase 0.

| Фаза | Что делает | Где |
|------|------------|-----|
| 1 | Волны: Bugbot ‖ security ‖ ponytail; typecheck ‖ lint ‖ i18n ‖ tests; фиксы по очереди | локально |
| 2 | react-doctor | локально |
| 3 | диск / `.next` → build (≈ Vercel) + bundle-budget | локально |
| 3.5 | Supabase: миграции / edge (если есть в diff) | локально / Supabase MCP |
| 3.9 | Атомарная упаковка (без полного test на каждый commit) | git, **только если 1–3.5 зелёные** |
| 3.95 | `origin/main` → `dev`, конфликты до push/PR | git |
| 4 | один push `dev` | git |
| 5 | только то, что реально есть в `.github/workflows/` | CI (страховка, один круг) |
| 6 | PR `dev` → `main` → merge (без сюрпризов-конфликтов) | GitHub |
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
- `check-only` — Phase 1–3.5 + **Phase 3.9** (упаковка, если зелёно), без push/CI/PR/production; починка по режиму (safe/auto)
- `skip-merge` — до Phase 5 включительно (push + CI на dev), merge и production Vercel — нет; починка по режиму (safe/auto)
- примеры: `/MA-deploy auto`, `/MA-deploy auto check-only`, `/MA-deploy skip-merge`, `/MA-deploy auto skip-merge`

## Жёсткие правила (без исключений)

**Ветки:** всегда только `dev` → PR → `main`. Никаких push напрямую в main, feature → main, master вместо dev. Если ветки `dev` нет — создай от `main` перед Phase 4.

**Merge в main:** только обычный merge commit (`gh pr merge --merge`). Squash и rebase merge **запрещены** — иначе история `dev` и `main` расходится, и каждый следующий релиз снова ловит те же конфликты.

**Атомарные commits — в конце локального цикла (удобство, без спроса):**  
1. Phase 1–3.5 работают по **рабочему дереву** (грязное OK). Ревью — по незакоммиченному (и по ветке, если уже есть commits vs `main`).  
2. Фиксы (auto / «чини») **копятся без commit** — иначе каждый блокер плодит лишнюю историю.  
3. Когда локально **нет блокеров** → Phase 3.9: агент **сам** раскладывает итоговое грязное дерево в атомарные commits (одна причина = один commit) → **3.95 sync main** → затем **один** push.  
Не спрашивай «ок?» по коммитам. Не ставь грязное дерево в Таблицу 6. Не коммить «на всякий случай» в начале.

**Хуки и полный test suite:** полный `pnpm test` / vitest — **один раз** в Phase 1 (плюс тонкий CI). На каждый атомарный commit Phase 3.9 полный suite **не** гонять. Стратегия хуков — `templates/git-hooks-ma-deploy.md`. `--no-verify` не использовать как обычный путь.

**Main до PR:** Phase 3.95 обязателен: `origin/main` влит в `dev`, конфликты сняты **до** push и **до** открытия PR. Обнаружить конфликт только на PR = ошибка pipeline.

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
   - **auto:** сразу упрости workflow **в рабочем дереве (без commit)** → пересчитай `CI_JOBS_TO_WAIT` → Phase 1; commit CI уйдёт в Phase 3.9
   - Пока блокер открыт — **запрещено** «подождать все толстые job'ы и пойти дальше»

5. Убедись что существуют ветки `dev` и `main`. Если `dev` нет:
   ```bash
   git fetch origin
   git checkout main && git pull
   git checkout -b dev && git push -u origin dev
   ```

6. Зафиксируй стартовое состояние: текущая ветка, uncommitted changes (факт, не блокер), последний CI status на `dev`, `CI_JOBS_TO_WAIT`, `HAS_SUPABASE`, список smoke URL.

7. **Аудит git-хуков (скорость):** есть ли husky / lefthook / pre-commit / pre-push?
   - Если **pre-commit** гоняет полный `pnpm test` / vitest / e2e → **риск повторов** в Phase 3.9. В отчёте Phase 0: «хуки тяжёлые».
   - **auto:** поправь хуки в дереве по `templates/git-hooks-ma-deploy.md` (лёгкий pre-commit, полный test в pre-push или только в `/MA-deploy`+CI) — commit уйдёт в 3.9.
   - **safe:** не чинить без «чини»; в Phase 3.9 всё равно не гонять полный suite на каждый commit (см. 3.9: `MA_ATOMIC_PACKING=1`).
   - **Не** ставь «тяжёлые хуки» в Таблицу 6 как Critical сами по себе — это скорость, не качество. Но отметь в плане.

8. **Не** раскладывай commits в Phase 0. Грязное дерево — нормальный вход. Упаковка = Phase 3.9 после зелёных 1–3.5.

**Gate Phase 0:** таблица «План проекта» заполнена **и** CI = тонкий шаблон (или workflow отсутствует; или в auto уже поправлен в дереве) → Phase 1. Стоп только на реальных блокерах (толстый CI в safe и т.п.) — **не** на «нужны commits».

## Phase 1 — Локальные проверки (волны)

**Правило:** не переходи к Phase 2, пока не закрыты все Critical / fails. Команды — из **«План проекта»**. Перед каждым ✅ — skill `verification-before-completion`.

**Политика параллели:** **смотрим вместе, чиним по очереди.**  
Волны 1A / 1B — read-only по **текущему рабочему состоянию** (см. Diff scope ниже).  
Фиксы *из* Phase 1 (auto / «чини») — последовательно **в дереве без commit**. Не чинить параллельными агентами.

| Волна | Что | Параллель? |
|-------|-----|------------|
| **1A — Ревью** | Bugbot ‖ Security ‖ Ponytail | Да — **одним** ходом родителя (три независимых агента / skill) |
| **1B — Проверки** | typecheck ‖ lint ‖ i18n ‖ tests | Да — параллельные shell/команды из «План проекта» (пропуск = нет script) |
| **1C — Сводка** | смержить Critical / fails / ponytail `net` в таблицы | Нет |
| **Фиксы** | только после 1C; safe = стоп; auto = loop по одному **без commit** | Нет — никогда параллельно |

**Fallback:** если нельзя запустить несколько агентов сразу — тот же состав 1A→1B по очереди (Bugbot → Security → Ponytail → проверки).

Можно стартовать **1A и 1B в одном ходу** (ревью не зависят от зелёных тестов). Если harness ограничивает — сначала 1A, затем 1B.

### Diff scope для ревью (Phase 1A)

Цель: увидеть **всё, что уедет в релиз vs `main`**, ещё до финальных commits.

| Состояние | Diff |
|-----------|------|
| Есть незакоммиченные изменения | основной: `uncommitted changes` |
| Плюс на ветке уже есть commits (`main..HEAD` не пуст) | дополнительно `branch changes` (второй проход или natural language «all vs main including uncommitted») |
| Дерево чистое, только commits на ветке | `branch changes` |

Не жди атомарной упаковки, чтобы начать ревью.

### Волна 1A — Ревью (read-only, параллельно)

Запусти **в одном сообщении / одном батче**:

1. **Bugbot** — skill `review-bugbot`: один subagent `bugbot`, Diff по таблице выше
   - Critical = блокер; Important/Minor = только отчёт
2. **Security** — skill `review-security`: один subagent `security-review`, тот же Diff scope
   - Если в проекте/diff есть **auth / PII / платежи / роли** — дополнительно логика `/security` (API/IDOR); Critical смержить в Таблицу 6
3. **Ponytail** — внешний skill `ponytail-review` (не копировать текст skill). Источник: `registry/external-skills.md` → пакет `dietrichgebert/ponytail`
   - Путь (первый найденный): `~/.agents/skills/ponytail-review/SKILL.md` → `~/.cursor/skills/…` → `~/.claude/skills/…`
   - **Прочитай** `SKILL.md` с диска; scope = тот же Diff, что у Bugbot
   - Нет файла → блокер: `install-external-skills.sh` (Таблица 6). Не подставлять копию из памяти
   - В отчёт: findings + `net: -N` (или `Lean already. Ship.`)
   - **Никогда** не автофиксить (safe и auto). `net ≤ -80`: **safe** → стоп; **auto** → пометить, **продолжить**. Чинить только после явного «чини»

Дождись **всех трёх** до волны 1C (или до фиксов).

### Волна 1B — Проверки (read-only / команды, параллельно)

Из «План проекта», что есть — **параллельно**:

4. **Typecheck** — обязательно, если есть script или CI job `typecheck`
   - Next.js с typegen: `npx next typegen && pnpm typecheck`
   - иначе команда из плана
5. **Lint** — обычно только локально
6. **i18n** — только локально; типично `i18n:check`, `i18n:cyrillic`, `i18n:parity`, `i18n:ui`; нет scripts → skip
7. **Tests** — обязательно локально; дубль в Phase 5, если есть CI job `test`

Fail любого шага → **safe:** стоп; **auto:** после 1C — sequential fix (не чинить, пока ревью/остальные проверки ещё бегут).

**Build здесь не запускаем** — он в Phase 3.

### Волна 1C — Сводка Phase 1

Собери Таблицы 1–2 / 6: Critical Bugbot+Security, fails 1B, ponytail `net`.  
**Safe:** любой блокер → стоп, ждать решения.  
**Auto:** переходи к loop фиксов ниже (по одному).

**Loop (только auto):** Critical/fail → root cause (`systematic-debugging`) → минимальный diff **в рабочем дереве, без commit** → повтори **упавшие** шаги (можно снова параллельно перепроверить 1B после пакета фиксов). Максимум 5 итераций.

**Safe:** loop запрещён. Любой блокер → стоп до ответа пользователя. После явного «чини» — те же правки **без commit** до Phase 3.9.

### Фиксы во время deploy (копить, не коммитить)

Только когда есть право чинить (auto или явное «чини»): правь по одной причине за раз, **оставляй в dirty tree**. Не создавай commits в Phase 1–3.5.

В **safe** без «чини» — **не** правь код и **не** создавай commits.

**Запрещено до Phase 3.9:**
- Коммитить «чтобы ревью видело историю» / «чтобы скорее деплоить»
- Спрашивать план commits / ждать «ок» по истории
- Ставить грязное дерево в Таблицу 6 как Critical
- Один большой commit всего diff в середине pipeline
- Коммитить каждый фикс сразу (это как раз плодит историю до зелёного состояния)

**Обязательно помнить для Phase 3.9** (когда всё зелёно): одна причина = один commit; сообщения `<type>(<scope>): …`; CI/workflow отдельно от code; baseline react-doctor отдельно; supabase migrations/functions отдельно.

Ориентир порядка упаковки в 3.9 (если эти изменения есть в дереве):
0. `chore(ci): thin to typecheck+test` — только workflow
1. feat/fix предыдущей работы пользователя — по причинам
2. fix critical Bugbot / security — по причинам
3. (только после явного «чини») `refactor(simplify): …`
4. fix typecheck / lint / i18n / tests — по причинам
5. fix react-doctor (по rule) + отдельно baseline
6. fix build / bundle-budget
7. supabase migrations/functions

### Phase 3.9 — Атомарная упаковка (после зелёных 1–3.5)

**Когда:** локальные фазы 1–3.5 закрыты без открытых блокеров (или блокеры явно сняты решением пользователя).  
**Где:** перед Phase 3.95; при `check-only` — в конце прогона (чтобы не оставлять «сырое» дерево после успеха).  
**Кто:** агент **сам**, без спроса (safe и auto одинаково).

**Полный test suite на каждый commit — запрещён** (это главный источник «очень долгого» релиза):

1. Полный `pnpm test` уже зелёный в Phase 1. Упаковка только раскладывает **уже проверенное** дерево.
2. Перед серией commits выставь env и держи на всю серию:
   ```bash
   export MA_ATOMIC_PACKING=1
   ```
   Хуки проекта должны уважать этот флаг (см. `templates/git-hooks-ma-deploy.md`): при `MA_ATOMIC_PACKING=1` pre-commit = только быстрое (lint-staged / format), **без** полного vitest.
3. **Не** используй `git commit --no-verify` / `--no-gpg-sign` как обычный путь. Исключение: хук сломан и блокирует упаковку *после* явного «чини» / в auto — тогда один раз обойти **и** сразу починить хук в дереве (отдельный commit в этой же 3.9).
4. Если после серии commits нужно успокоить pre-push: полный suite уже был в Phase 1; повторный полный локальный test **перед push** — только если правили код *после* Phase 1 или хук pre-push требует (один раз на весь push, не на каждый commit).

Шаги упаковки:

1. `git status` + полный diff vs `HEAD` / vs `main` — что ещё не закоммичено
2. Если дерево чистое → Таблица 4 из `main..HEAD`, сразу Phase 3.95 (или конец check-only без 3.95, если push не будет)
3. Если грязное → разложи на атомарные commits (одна причина = один). **Запрещено** один commit «все изменения перед деплоем»
4. Не используй `git rebase -i` / `git add -i`. Soft reset только на **своих непушеных** commits, если нужно переразложить локальную историю до упаковки
5. Огромные commits **уже на remote** — не переписывать; упаковывай только текущий dirty tree
6. Заполни Таблицу 4 → **Phase 3.95** (не Phase 4 напрямую). При `check-only` без push: 3.95 можно skip, если не будете пушить сейчас

**Не** запускай 3.9, если есть открытые блокеры (safe ждёт / auto не сошёлся) — иначе закоммитишь недоделанное.

### Phase 3.95 — Подтянуть main в dev (до push и до PR)

**Обязательно** перед Phase 4 (и перед любым PR). Цель: **один** push и **один** CI без второго круга из‑за конфликтов на PR.

Пропусти только при `check-only` (нет push/PR).

1. Обнови ссылки:
   ```bash
   git fetch origin main dev
   git checkout dev
   git pull --ff-only origin dev || git pull origin dev
   ```
2. Влей свежий main:
   ```bash
   git merge origin/main
   ```
   - Конфликты → разреши **сейчас** (auto: чинить; safe: стоп + Таблица 6 «конфликт с main до PR»).
   - После разрешения: если менялся код/lockfile — быстро перепроверь упавшие по смыслу шаги (минимум typecheck; tests — если трогали логику). Не открывай PR с конфликтами.
3. Убедись, что `dev` содержит `origin/main` (нет расхождения, которое GitHub пометит как conflict):
   ```bash
   git merge-base --is-ancestor origin/main HEAD && echo "main reachable from dev"
   ```
4. В отчёт: «main влит в dev до push» + были ли конфликты.

**Gate:** `origin/main` — предок текущего `dev` (или merge уже сделан без конфликтов) → Phase 4.

**Запрещено:** открыть PR, увидеть conflict, потом merge main → ещё push → ещё CI. Это запрещённый анти-паттерн для **всех** проектов.

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
   - **auto:** fix **в дереве без commit** → re-run. При сложных ошибках — playbook из skill `react-doctor`
   - **safe:** стоп + Таблица 6

4. После успеха:
   ```bash
   node scripts/update-react-doctor-baseline.mjs
   ```
   Monorepo: скрипт в React-корне (`web/scripts/…`). Baseline остаётся в dirty tree → отдельный commit в Phase 3.9.

## Phase 3 — Build (≈ Vercel) + bundle budget (финальный gate перед push)

Команды — из «План проекта». После зелёных Phase 1–2. При `check-only` build всё равно обязателен.

0. **Диск и кэш перед build (обязательно):**
   ```bash
   df -Pk . | awk 'NR==2 {print $4}'   # свободные KiB
   ```
   - Если свободно **< 3 GiB** (≈ 3145728 KiB) **или** недавно был ENOSPC:
     - безопасная очистка только артефактов сборки (не трогай исходники и `.env`):
       ```bash
       rm -rf .next .turbo
       # monorepo: то же в React-корне (web/, apps/…)
       ```
     - при необходимости: `pnpm store prune` только если места всё ещё мало и пользователь/auto разрешает чистку кэша пакетов
   - В отчёт: свободное место до/после. Build при < 1 GiB свободных → стоп (Таблица 6 «мало места на диске»), не тратить время на заведомый ENOSPC.

1. **Build** — `pnpm build`. **Обязательно локально** (до упаковки и push).
   - Эмулирует production-сборку Vercel
   - fail → **не** Phase 3.9 / **не** push; safe стоп / auto fix в дереве (`systematic-debugging`)
   - ENOSPC → очистка `.next` (п.0) → один повтор; второй fail = блокер

2. **Bundle budget** — `pnpm check:bundle-budget` сразу после build.
   - Только локально; пропусти если script нет
   - При fail в **auto**: сначала skill **`performance-optimizer`** (Vercel), затем минимальный fix **без commit** → повтори build+budget
   - **safe:** стоп + Таблица 6

**Gate:** build READY + bundle-budget OK → Phase 3.5 (или Phase 3.9, если supabase skip).

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
   - **auto:** выполни безопасный выкат по принятому в проекте способу (миграции / edge); правки кода репозитория **без commit** до 3.9; схемы на remote — только если это стандарт проекта и не требует секретов в чат. Если нельзя безопасно — стоп с отчётом даже в auto
5. Если supabase-изменений в diff нет → строка в отчёте: «база/функции — не нужно»

**Gate:** supabase OK или skip → **Phase 3.9** (атомарная упаковка) → **Phase 3.95** → Phase 4.

## Phase 4 — Push на dev

Пропусти если `check-only` (но Phase 3.9 при успехе check-only всё равно выполняется; 3.95 skip).

1. **Предусловия:**
   - Phase 3.9 закрыта — грязного дерева нет (или осознанно нечего коммитить). Uncommitted diff после 3.9 = ошибка pipeline.
   - Phase 3.95 закрыта — `origin/main` уже в `dev`, конфликтов нет.
2. **Не** создавай здесь новые commits (кроме экстренного дожима, если 3.9/3.95 что-то пропустили — лучше вернуться туда).
3. **Один** push на `dev` (после sync — не два круга):
   - feature → merge в `dev` (если ещё не на `dev`)
   - `git checkout dev && git push origin dev`
4. В статусе процесса: «Ждём: push принят / CI стартует», обычно **< 1 мин** до появления run.
5. Tip SHA + `git log --oneline main..dev` → отчёт.

## Phase 5 — CI на dev зелёный

Пропусти если `check-only` или нет workflow.

**Предусловие:** CI уже тонкий шаблон (закрыто в Phase 0). Если после push в workflow снова появились лишние job'ы — снова блокер, назад в Phase 0 logic, **не** ждать лишние job'ы.

Жди только `CI_JOBS_TO_WAIT` = `{typecheck, test}` (что реально есть в тонком workflow).

В **Статусе процесса** сразу напиши:
- Ждём: CI на `dev` (`typecheck` + `test`)
- Обычно занимает: **~3–10 мин** (зависит от проекта; не путать с Vercel)

```bash
gh run list --branch dev --limit 3
gh run watch <run-id> --exit-status
```

- Fail:
  1. Сначала subagent **`ci-investigator`** (один упавший check → короткий root-cause)
  2. При необходимости углуби через `systematic-debugging` + `gh run view --log-failed`
  3. **auto:** fix **в дереве** → атомарные commits (как 3.9) на dev → **снова 3.95 если нужно** → **один** push → watch
  4. **safe:** стоп + Таблица 6
- CI не триггерится на `dev` → добавь `dev` в workflow triggers (это часть тонкого шаблона), commit, push

**Gate:** все `CI_JOBS_TO_WAIT` green → Phase 6. Preview не ждём. Цель — **один** зелёный CI-круг на этот релиз, не серия из‑за позднего merge main.

## Phase 6 — PR dev → main → merge

Пропусти merge если `skip-merge` или `check-only`.

**Политика merge (жёстко):** только **обычный merge commit** (`gh pr merge --merge`). **Запрещено** `--squash` и `--rebase`.

Почему: squash на `main` ломает общую историю с `dev`. Git потом видит «два разных изменения одних и тех же мест», и каждый следующий релиз снова просит разрулить те же файлы — даже если правки на `dev` уже были влиты. Обычный merge сохраняет связь веток: параллельная работа на `dev` во время релиза не «перетирается» искусственным выравниванием после squash.

**Предусловие:** Phase 3.95 уже сняла конфликты с `main`. Если GitHub всё же показывает conflict — **не** «чинить на PR как основной путь»: вернись к 3.95 локально, почини, push, обнови PR.

1. PR **dev → main** (только после 3.95):
   ```bash
   gh pr list --head dev --base main --state open
   gh pr create --base main --head dev --title "..." --body "..."
   ```
2. Дождись green PR checks = `CI_JOBS_TO_WAIT` (часто уже зелёные с Phase 5 — не гоняй лишний круг без нужды):
   ```bash
   gh pr checks <number> --watch
   ```
   Статус: «Ждём: проверки PR», обычно **~0–10 мин** если CI уже прошёл на `dev`.
3. Если PR **застрял** (висящие review-комменты, красный CI): следуй skill **`babysit`** (в рамках safe/auto: в safe — только диагноз в Таблицу 6; в auto — чинить и довести до merge-ready). Конфликт с main после 3.95 = регресс процесса, чинить через 3.95. Не используй babysit как замену всего Phase 6.
4. Merge (**только** `--merge`, ветку `dev` не удалять):
   ```bash
   gh pr merge <number> --merge --delete-branch=false
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

- В статусе: «Ждём: Vercel production READY», обычно **~5–10 мин** (типично 5–7)
- Жди **READY** (timeout 20 мин)
- ERROR → MCP `get_deployment_build_logs` (errorsOnly) → блокер
  - **auto:** fix → Phase 3–6 заново (новый PR через `dev`, снова с 3.95)
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

**Сначала** блок «Статус процесса» (закон из `$MA_HUB_ROOT/standards/00-operating-model.md`):

| Поле | Значение |
|------|----------|
| Сейчас | идёт процесс / нужно ваше решение / готово |
| Что происходит | одна фраза простым языком |
| Ждём | ничего / CI на dev / Vercel production / ваш ответ по блокерам / … |
| Обычно занимает | — / ~3–10 мин (CI) / ~5–10 мин (Vercel) / пока не ответите |
| Что от вас | ничего / … |

Пока идёт ожидание (CI, Vercel) — **обновляй** этот блок в каждом промежуточном ответе: что именно ждём и типичное время. Не оставляй пользователя без ориентира «почему тишина».

Потом таблицы ниже. Поле «Этап работы» в Таблице 1 должно **согласовываться** с «Сейчас» (не противоречить).

### Таблица 0 — План проекта (из Phase 0)

| Проверка | Phase | В CI? | CI job | Команда / skill | Соответствие шаблону |
|----------|-------|-------|--------|-----------------|----------------------|
| Bugbot | 1 | нет | — | `review-bugbot` | ✅ |
| Security | 1 | нет | — | `review-security` | ✅ |
| Ponytail | 1 | нет | — | `ponytail-review` (external) | ✅ |
| Typecheck | 1 + 5 | да | `typecheck` | `pnpm typecheck` | ✅ / ❌ блокер |
| … | … | … | … | … | … |
| Supabase | 3.5 | — | — | MCP / skip | ✅ |
| Упаковка commits | 3.9 | нет | — | атомарно + `MA_ATOMIC_PACKING=1` | ✅ |
| Sync main → dev | 3.95 | нет | — | `git merge origin/main` до PR | ✅ |
| CI шаблон | 0 | — | только typecheck+test | thin template | ✅ / ❌ блокер |

`CI_JOBS_TO_WAIT`: `typecheck`, `test` (только эти)  
`CI_TEMPLATE`: thin / **too-thick (блокер)** / none  
`HAS_SUPABASE`: yes/no  
`HOOKS`: light / heavy→fix / heavy→risk  
`DISK_BEFORE_BUILD`: OK / cleaned `.next` / blocker

### Таблица 1 — Сводка (простым языком)

Сначала заполни **этап работы** — по нему сразу видно, идут ли проверки, копятся ли правки или уже можно выкладывать.

| Поле | Значение |
|------|----------|
| Проект | … |
| Режим | полный / только проверки / без merge в main + safe / auto |
| **Этап работы** | см. словарь ниже |
| Локальные проверки (1–3.5) | зелёно / в процессе / стоп |
| Правки сейчас | нет / копятся в файлах (ещё не упакованы) / упакованы |
| Упаковка перед выкладкой | ещё рано / сделана (N шт.) / не нужна (уже чисто) |
| Нужно ваше решение | нет / да — см. таблицу блокеров |
| Починка | safe (жду решения) / auto (без вопросов) |
| Статус | ✅ Успех / ⚠️ Частично / ❌ Остановлен / ⏸ Жду решения |
| Commits после упаковки | N (или «ещё не было») |
| Tip SHA на dev | `<sha>` / ещё нет |
| PR | `#N` + URL или «не создан» |
| Merge в main | да / нет / ожидает |
| База/функции | не нужно / нужно / сделано / блокер |
| CI шаблон | тонкий / **толще нормы (блокер)** / нет CI |
| Vercel на main | READY / ERROR / skip |
| Smoke | HTTP+runtime / +browser / partial |
| Простота (ponytail) | `Lean` / `-N` (в safe блокер если ≤ -80) |
| Сейчас ждём | ничего / CI (~3–10 мин) / Vercel (~5–10 мин) / ваше решение |
| Хуки | лёгкие / тяжёлые (исправлены в 3.9) / риск (safe, не чинили) |
| main → dev до PR | сделано (3.95) / skip (check-only) / блокер |

**Словарь «Этап работы»** (выбери одну фразу):

| Этап | Когда писать |
|------|----------------|
| Проверки идут, правки ещё не упакованы | Phase 1–3.5, дерево может быть грязным — это норма |
| Жду вашего решения по блокерам | safe-стоп; коммиты **не** делаем |
| Всё зелёно, упаковываю перед выкладкой | Phase 3.9 (без полного test на каждый commit) |
| Подтягиваю main в dev | Phase 3.95 |
| Упаковано, выкладываю | Phase 4+ |
| Жду CI на dev (~3–10 мин) | Phase 5 |
| Жду Vercel production (~5–10 мин) | Phase 7 poll |
| Готово на проде | Phase 7 успех |
| Только проверки (без выкладки) | `check-only` после 3.9 |

**Не путай:** «правки копятся» ≠ авария. Авария только если «Нужно ваше решение = да» или статус ❌.

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
| Disk / `.next` | 3 | `df` + safe clean | ✅ / ❌ / skip | — | — | — |
| Build (≈ Vercel) | 3 | `pnpm build` | ✅ / ❌ / skip | — | — | — |
| Bundle budget | 3 | `…` / `performance-optimizer` | ✅ / ❌ / skip | — | — | — |
| Supabase | 3.5 | MCP / skip | ✅ / ❌ / skip | — | — | — |
| Упаковка commits | 3.9 | атомарно, без полного test/commit | ✅ / skip | — | — | — |
| Sync main → dev | 3.95 | merge до push/PR | ✅ / ❌ / skip | — | — | — |
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

### Таблица 4 — Атомарные commits (Phase 3.9 + уже бывшие на ветке)

Сюда: commits, которые уже были в `main..HEAD` **до** деплоя, **плюс** то, что агент упаковал в Phase 3.9 (и редкие дожимы после CI).

| # | SHA | Сообщение | Когда |
|---|-----|-----------|-------|
| 1 | `abc1234` | feat(…): … | уже на ветке |
| 2 | `def5678` | fix(auth): … | Phase 3.9 |

### Таблица 5 — Phase 4–7 (deploy)

| Phase | Действие | Статус | Ссылка / детали |
|-------|----------|--------|-----------------|
| 3.9 Упаковка | атомарные commits (без полного test на каждый) | ✅ / skip | N commits |
| 3.95 Sync main | `origin/main` → `dev` до PR | ✅ / ❌ / skip | конфликты: да/нет |
| 4 Push dev | **один** `git push origin dev` | ✅ / ❌ / skip | commit `<sha>` |
| 5 CI dev | `CI_JOBS_TO_WAIT` (~3–10 мин) | ✅ / ❌ / skip | run URL |
| 6 PR | dev → main (уже без конфликтов) | ✅ / ❌ / skip | PR URL |
| 6 Merge | merge commit, не squash (+ `babysit` если застрял) | ✅ / ❌ / skip | merge SHA |
| 7 Vercel Production | main → READY (~5–10 мин) | ✅ / ❌ / skip | prod URL |
| 7 Smoke A | HTTP + runtime errors | ✅ / ❌ / skip | routes |
| 7 Smoke B | `agent-browser` | ✅ / ❌ / ⚠️ fallback | URLs |

### Таблица 6 — Блокеры (если есть)

| # | Severity | Проблема | Где | Что делать |
|---|----------|----------|-----|------------|
| 1 | Critical | … | file:line | … |

Если блокеров нет — таблицу 6 не показывай.

В режиме **safe** при стопе всегда покажи Таблицу 6 и строку:
«⏸ Нужно ваше решение по строкам таблицы (это не про коммиты). Напишите „чини“ / „не чинить“ / „отложить“ или выберите пункты. Для ночного прогона без паузы: `/MA-deploy auto`.»

**Итог одной строкой** (простым языком, без git-жаргона):
- «Готово: на main и в проде всё поднялось»
- «Остановлен: нужно ваше решение (см. блокеры) — правки пока не упакованы»
- «Остановлен на проверках: … — правки копятся / не трогали»
- «Проверки пройдены, упаковано, push не делали (только проверки)»
- «Проверки идут / упаковка впереди — это нормальный ход, не авария»

## Стоп-условия (не мержить / не считать успехом)

- Грязное дерево в Phase 0–3.5 — **не** стоп; коммиты только в Phase 3.9 после зелёных локальных шагов. Уже запушенные огромные commits — без rewrite
- Push / конец check-only при успехе, но с незакрытым dirty tree (пропущен 3.9) — ошибка pipeline
- Push/PR без Phase 3.95 (main не влит в dev) — ошибка pipeline; конфликт «всплыл на PR» — регресс
- Critical из Bugbot / security не закрыт (safe = стоп; auto = чинить до лимита)
- Ponytail `net ≤ -80` в **safe** не закрыт решением пользователя (в **auto** — не стоп, только отчёт)
- Внешний skill `ponytail-review` отсутствует на диске (нужен `install-external-skills.sh`)
- typecheck / lint / i18n / test fail (Phase 1)
- React Doctor errors > 0 или score < baseline + 1 (Phase 2)
- Мало места на диске (< 1 GiB) или повторный ENOSPC после очистки `.next` (Phase 3)
- build / bundle-budget fail (Phase 3) — **push запрещён**
- Supabase: в diff есть миграции/functions, прод не готов, нет безопасного плана (Phase 3.5)
- CI на dev красный (`CI_JOBS_TO_WAIT`)
- **CI толще тонкого шаблона** (любой job кроме `typecheck` / `test`) — **стоп**, пока workflow не упрощён; нельзя «подождать и пойти дальше»
- PR conflicts или failing required checks (конфликт после 3.95 = чинить через 3.95, не «на глаз» в UI)
- Push не в `dev` или PR не dev → main
- **Vercel Production (main) не READY**
- Секреты / `.env` / tokens в diff — **всегда стоп**, даже в `auto`
- Полный test suite на каждый атомарный commit Phase 3.9 без попытки `MA_ATOMIC_PACKING` / правки хуков — анти-паттерн (в auto — исправить процесс; не считать «нормальной скоростью»)

## Skills / MCP для агента (обязательная маршрутизация)

| Когда | Что использовать |
|-------|------------------|
| Любой ✅ в отчёте | `verification-before-completion` |
| Phase 1 review | **`review-bugbot`** (всегда; Cursor-native; волна **1A** ‖ security ‖ ponytail) |
| Phase 1 security | **`review-security`** (всегда; Cursor-native; волна **1A**); плюс `/security` при auth/PII |
| Phase 1 простота | **`ponytail-review`** (всегда; external — читать с диска, см. `registry/external-skills.md`; волна **1A**); **не автофикс** |
| Phase 1 проверки | typecheck ‖ lint ‖ i18n ‖ tests (волна **1B**); фиксы только после сводки, **по очереди** |
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
