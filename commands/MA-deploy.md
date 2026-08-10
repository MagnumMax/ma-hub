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
| **safe** (default) | `/MA-deploy`, `check-only`, `skip-merge` | Не чинить блокеры вне 1A. Блокер → Таблица 6 → ждать «чини» / «не чинить» / «отложить». **Исключение Phase 1A:** Critical/High + явный ponytail — чинить сразу |
| **auto** | `auto` (+ можно `check-only` / `skip-merge`) | Чинить блокеры без паузы (CI→эталон thin+дешёвый, хуки→шаблон, Critical, fails, сегментный review). Ponytail в 1A — с автофиксом |

**Safe:** толстый/дорогой CI / тяжёлые хуки / fail проверок → стоп, не commit, не push. Грязное дерево в начале — **не** блокер. В 1A Critical/High и явный ponytail чинятся сразу; оставшийся ponytail `net ≤ -80` после автофикса → стоп. Medium/Low → сводный backlog, пауза на решения.

**Auto:** без подтверждений на фикс; root cause (`systematic-debugging`) → fix **в дереве без commit** → re-check, макс. 5 итераций на фазу. Не сошлось → стоп с отчётом. Ponytail в 1A с автофиксом; при `net ≤ -80` после фикса — пометить и **продолжить**. Commits только в Phase 3.9.

Аргументы (порядок не важен):
- пусто — полный цикл до prod, **safe**
- `auto` — полный цикл с автопочинкой
- `check-only` — Phase 1–3.5 + 3.8 + 3.9, без push/CI/PR/prod
- `skip-merge` — до Phase 5 (push + CI), без merge и Vercel prod

## Pipeline

```
0 → 1 (1S сегменты → 1A review по кускам → 1B проверки → 1C) → 2 (react-doctor)
  → 3 (disk/build/budget) → 3.5 (supabase если нужно) → 3.8 (уборка до commits)
  → 3.9 (атомарные commits) → 3.95 (main → dev) → 4 (один push dev) → 5 (CI)
  → 6 (PR → merge) → 7 (Vercel + smoke) → 7.5 (ТГ) → 7.6 (уборка хвоста) → Отчёт
```

Локально перед push: 1–3.5 → **3.8** → **3.9** → **3.95** → 4. `pnpm build` = эмуляция Vercel; Preview на `dev` **не** ждём.

**Анти-повторы (закон):** один полный suite в Phase 1 + один CI после push + один Vercel prod. Полный test на каждый commit 3.9 — **запрещён**. Конфликты снимать в 3.95 **до** PR. Перед build — место на диске / очистка `.next`. `--no-verify` не дефолт. Эталон хуков: `$MA_HUB_ROOT/templates/git-hooks-ma-deploy.md`. Эталон CI: `$MA_HUB_ROOT/templates/ci-ma-deploy.md` (минуты = job’ы × запуски на коммит).

**Где что:** тяжёлое локально (1–3.5); CI = только `{typecheck, test}` в **одном** job с одним install; любой другой CI job / дубль `pull_request` без форков = **блокер** (не «подождать и пойти»).

| Проверка | Phase | Где |
|----------|-------|-----|
| Сегментный review (code-review + ponytail) | 1S–1A | эталон `templates/segmented-review-ma-deploy.md` |
| typecheck / lint / i18n / tests | 1B (+ typecheck/test в CI 5) | scripts из плана |
| react-doctor | 2 | skill `react-doctor` |
| build + bundle-budget | 3 | `pnpm build`, `pnpm check:bundle-budget` |
| supabase | 3.5 | MCP/CLI если diff |
| Уборка мусора (до commits) | 3.8 | эталон `templates/cleanup-ma-deploy.md` |
| Vercel prod + smoke | 7 | Vercel MCP + `agent-browser` |
| Клиентский апдейт в Telegram | 7.5 | эталон `templates/telegram-customer-update-ma-deploy.md` + `bootstrap/telegram-customer-update-send.sh` |
| Уборка мусора (хвост прогона) | 7.6 | тот же эталон `templates/cleanup-ma-deploy.md` |

## Жёсткие законы

1. **Ветки:** только `dev` → PR → `main`. Нет `dev` — создай от `main` до Phase 4.
2. **Merge:** только `gh pr merge --merge`. Squash/rebase **запрещены**.
3. **Commits только в конце локального цикла:** 1–3.5 по dirty tree; фиксы копятся без commit; после зелёных 1–3.5 → **3.8** (уборка) → 3.9 сам (без «ок?» по коммитам) → 3.95 → один push.
4. **Полный test** — один раз в Phase 1 (+ thin CI). Тяжёлые хуки / дорогой CI (много job’ов, дубль PR) = блокер Phase 0.
5. **3.95 обязателен** до push и до PR. Конфликт «всплыл на PR» = ошибка процесса.
6. **React Doctor:** `npx react-doctor@latest --verbose --scope changed --blocking error`; baseline `.react-doctor/baseline.json`; monorepo — из React-корня.
7. Не подменять pipeline gstack land-flow; идеи smoke из `gstack/canary` — ок.
8. **Сегментный review всегда** (Phase 1S–1A): логические куски в одном дереве — **без** веток/PR на сегмент. Не подменять одним скопом на весь diff.

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
Эталон сегментов: `$MA_HUB_ROOT/templates/segmented-review-ma-deploy.md`.

| Волна | Что | Параллель |
|-------|-----|-----------|
| **1S** | План логических сегментов (как split-to-prs, **без** веток/PR) | нет |
| **1A** | По каждому сегменту: code-review → Critical/High fix → ponytail **с автофиксом** → backlog | нет (сегменты строго по порядку) |
| **1A-end** | Сводный backlog Medium/Low / спорное → решения | нет |
| **1B** | typecheck ‖ lint ‖ i18n ‖ tests | да |
| **1C** | сводка → таблицы | нет |
| Фиксы | 1B fails: safe=стоп; auto=по одному без commit | нет |

Diff scope ревью: uncommitted + при необходимости `main..HEAD` (всё, что уедет в релиз). Не ждать 3.9.

**1S:** нарезать diff на логические куски (смысл / владельцы / фундамент→потребители). Маленький diff → **1 сегмент**, но полный цикл 1A всё равно. Показать таблицу сегментов и сразу продолжать (без «ок?» на план). **Запрещено** создавать ветки/PR на кусок.

**1A (на каждый сегмент):**
1. `/code-review` по зоне (+ scoped `review-bugbot` / `review-security` при необходимости; auth/PII → `/security`).
2. **Сразу** исправить Critical и High в дереве (**даже в safe** — исключение этой волны).
3. `ponytail-review` (читать SKILL с диска; нет файла → блокер `install-external-skills.sh`) → **сразу применить** явные findings (`delete`/`stdlib`/`native`/`yagni`/`shrink`). Спорное — в backlog, не молча.  
   Исключение MA-deploy: skill «только отчёт» — здесь после отчёта агент **вносит** правки.
4. Medium/Low и спорное → `SEGMENT_BACKLOG`.

**1A-end:** склеить backlog, убрать дубли, показать таблицу.  
- **safe:** пауза на «чини / не чинить / отложить» (пакетом ок). Пустой backlog или «всё отложить» → 1B.  
- **auto:** дешёвые однозначные Medium — починить; остальное в отчёт → 1B.

**1B:** scripts из плана; Next typegen если нужен. Build **не** здесь. Полный suite — **один раз** на всё дерево после 1A (не на каждый сегмент).

**1C / loop:** safe — стоп на блокере 1B; auto — fix в дереве, макс. 5 итераций. До 3.9 запрещено коммитить «чтобы скорее» / спрашивать план commits / один большой commit всего diff.

Ориентир порядка в 3.9: CI → hooks → feat/fix → critical fixes → ponytail/simplify из 1A → typecheck/lint/i18n/tests → doctor+baseline → build/budget → supabase.

## Phase 2 — React Doctor

Только локально. Skill `react-doctor`.  
Gate: `errorCount = 0`; при baseline — `newScore >= baseline + 1` (score 100 → достаточно 0 errors).  
Loop: auto fix в дереве / safe стоп. После успеха — обновить baseline (отдельный commit в 3.9).

## Phase 3 — Disk + build + bundle

После зелёных 1–2. `check-only` — build всё равно обязателен.

0. Свободное место (`df`). < ~3 GiB или был ENOSPC → безопасно `rm -rf .next .turbo` (не `.env`). < 1 GiB → стоп.
1. `pnpm build` — обязателен до 3.9/push. Fail → не push; auto fix в дереве.
2. `pnpm check:bundle-budget` если есть; fail auto → `performance-optimizer` → fix без commit.

**Gate:** build + budget OK → 3.5 или сразу **3.8**.

## Phase 3.5 — Supabase

Skip если `HAS_SUPABASE=no` или в diff vs `main` нет `supabase/migrations|functions`.  
Если есть: проверить готовность прода / план выката. Safe — стоп без плана; auto — безопасный выкат по стандарту проекта (без секретов в чат). Иначе блокер.

**Gate:** OK/skip → **3.8** → **3.9** → **3.95** → 4.

## Phase 3.8 — Уборка мусора до упаковки

Обязательна перед 3.9 (в т.ч. при `check-only`). Эталон: `$MA_HUB_ROOT/templates/cleanup-ma-deploy.md`.  
Тихий skip без скана **запрещён**.

**Зачем:** старый мусор и файлы похожие на ключи **не тащить** в релиз рядом с commits/push. Агент сам инициирует — пользователь не должен писать «удали мусор».

1. Скан корня: `.impeccable/`, `tmp/`, кэши тестов/e2e, скриншоты, leftover-логи, `*api-key*` и т.п. Агент сам решает, что мусор; акцент на **секреты** и leftover прошлых сессий. Local deviations.
2. Класс: **safe junk** / **secret-looking** / **ask**. Размер примерно. Содержимое секретов **не** печатать.
3. Пусто → «мусора не нашёл» → 3.9.

### safe (и без `auto`)

4. Список + рекомендация + **A / B / C** (или «ничего»). Удалять только после ответа.

### auto

4. **Safe junk** — удалить без спроса; перечислить «уже удалил: …».  
5. **Secret-looking** / **Ask** — всегда спросить (A/B/C).

**Не трогать** без явного «да»: `.env` / `.env.local`, `node_modules/`, `.git/`, исходники в git. `.next`/`.turbo` — не здесь (Phase 3).

**Gate:** скан + (чисто | удалено по режиму | ответ на A/B/C) → **3.9**.

## Phase 3.9 — Атомарная упаковка

Когда 1–3.5 зелёные **и 3.8 закрыта**. Агент **сам**, без спроса. При `check-only` — в конце успеха (после 3.8).

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

**Gate:** READY + A OK + B OK (или явный fallback) = успех → **Phase 7.5**.

## Phase 7.5 — Клиентское уведомление в Telegram

Skip при `check-only` / `skip-merge`. Эталон: `$MA_HUB_ROOT/templates/telegram-customer-update-ma-deploy.md`.  
**Только здесь** (не на PR, не отдельным Actions). Клиенту — после успешного прода. Прод уже выкатили — **не** откатывать.

**Жёсткий закон:** вопрос «слать клиенту?» **без полного текста черновика в том же сообщении** — ошибка процесса. Пользователь не должен отдельно спрашивать «а что там будет написано?».

### 7.5-0 — Черновик + вопрос «слать?» в одном сообщении

**Даже в `auto` — пауза.** Сначала **собрать черновик**, потом спросить — в **одном** ответе пользователю.

1. Собрать изменения релиза по эталону `$MA_HUB_ROOT/templates/telegram-customer-update-ma-deploy.md`: **English**, стиль **Slack/GitHub** — секции **What's New** / **Improvements** / опционально **Fixes**; буллеты `• {short fact}` **без** `Zone → Sub-area`; HTML-жирные заголовок и секции; буллеты **подряд без пустых строк между ними**. **Источник:** не только `git log` — PR body + изменённые области/diff + коммиты как подсказки; выписать все заметные для клиента фичи, **не склеивать** независимые в один буллет ради краткости; искусственный лимит «6» запрещён.

2. В том же сообщении **обязательно** показать:
   - строку покрытия: `N commits / areas → M bullets` + что отсеяли как технику (кратко);
   - **полный текст** сообщения как уйдёт в Telegram — в **копируемом** блоке кода (HTML как в эталоне, без сокращений «см. выше»).

3. Спросить простым языком (под черновиком):

> Уведомить клиента в Telegram об этом релизе?  
> **да** / **нет (только техника)** / правки: …

**Если нечего сказать клиенту** (после отсева техники пусто): **не** писать пустой/формальный черновик «технические улучшения». Явно: «клиенту нечего сказать» + список отсеянного → предложить **нет (только техника)**.

- **нет (только техника)** → ⚠️ в отчёте «Telegram: пропуск, технический релиз», дальше Отчёт. **Не** требовать ключи.
- **да** (или «да» после правок текста) → 7.5a → 7.5b.
- правки → обновить черновик, **снова показать полный текст**, снова спросить.

Тихий skip без вопроса **запрещён**. Вопрос без видимого полного черновика **запрещён**.

### 7.5a — Проверка ключей (только если «да»)

1. Загрузить env: `.env.local` / `.env` продукта **и** `~/.config/ma-hub/telegram.env`.
2. Проверить наличие:
   - **`MA_TELEGRAM_BOT_TOKEN`** (общий, из `telegram.env` на машине; не ops-`TELEGRAM_BOT_TOKEN` продукта);
   - **`COMPANY_TELEGRAM_CHAT_ID`** в продукте;
   - **`COMPANY_TELEGRAM_THREAD_ID_UPDATES`** — если у клиента форум с топиком Updates (если топика нет — можно пусто, но chat id обязателен).
3. **Если чего-то нет — не продолжать молча.** Простым языком сказать, **какие ключи добавить и куда** (чат/топик → `.env.local` продукта; бот → `~/.config/ma-hub/telegram.env`).  
   Ждать: **«готово»** (пользователь добавил) / **«пропустить уведомление»** (передумали для этого релиза) / значения ключей в чат (агент допишет в `.env.local`, токен машины — только если пользователь явно дал).
4. После «готово» — **перечитать env и проверить снова**. Ещё пусто → снова сказать, что не хватает, не идти дальше по 7.5.  
   «Пропустить уведомление» → ⚠️ в отчёте, дальше Отчёт.

### 7.5b — Подтверждение отправки (ключи ок)

5. Ещё раз показать **тот же полный текст** (копируемый блок) — чтобы не было сомнений, что уйдёт.  
6. **Пауза:** «Send to client? **send** / edits: … / **don't send**» (в чате: **отправить** / правки / **не слать**).  
   При правках — обновить текст, **снова показать полный черновик**, снова пауза.  
7. После «отправить»/«send»: `"$MA_HUB_ROOT/bootstrap/telegram-customer-update-send.sh"` (stdin или `--file`). Не печатать токен. Ошибка API → сообщить, не откатывать прод.

**Gate:** ответ на 7.5-0 (с видимым черновиком или явным «нечего сказать») + (пропуск | отправлено | «не слать») → **Phase 7.6**.

## Phase 7.6 — Уборка мусора после релиза (хвост прогона)

Skip при `check-only` / `skip-merge`. Эталон: `$MA_HUB_ROOT/templates/cleanup-ma-deploy.md`.  
После закрытия 7.5. Прод **не** откатывать. Тихий skip без скана **запрещён**.

**Зачем:** мусор, появившийся **в этом** прогоне после 3.8 (smoke PDF, скрины, новые логи). Не дублировать длинно то, что уже закрыли в 3.8, если нового нет.

1. Скан с акцентом на артефакты **после** 3.8. Класс: safe junk / secret-looking / ask.
2. Пусто / «нового мусора нет» → Отчёт.
3. Правила удаления — как в 3.8: **safe** всегда A/B/C; **auto** — safe junk сразу, секреты/ask — спрос.

**Не трогать** без явного «да»: `.env` / `.env.local`, `node_modules/`, `.git/`, исходники в git. `.next`/`.turbo` по умолчанию не чистить.

**Gate:** скан + (нечего | удалено по режиму | ответ на A/B/C) → Отчёт.

## Отчёт

Сначала «Статус процесса» (`standards/00-operating-model.md`): Сейчас / Что происходит / Ждём / Обычно занимает / Что от вас. При ожидании CI/Vercel — обновляй блок каждый раз.

Потом **короткие таблицы** (без простыней; строки по факту):

| # | Содержание |
|---|------------|
| 0 | План проекта + `CI_JOBS_TO_WAIT` / thin+cheap|thick|expensive / hooks light|heavy / `HAS_SUPABASE` / disk |
| 1 | Сводка простым языком: этап, safe/auto, блокеры?, сегменты, commits, PR, merge, Vercel, smoke, ponytail, Telegram клиенту, уборка мусора |
| 2 | Шаги 1–3.5 / 3.8 / 3.9 / 3.95 — результат |
| 2a | Сегменты 1S: N кусков + порядок; по каждому — Critical/High закрыты? |
| 2b | Ponytail по сегментам + суммарный `net` |
| 2c | Сводный backlog (Medium/Low / спорное) + решения |
| 3 | React Doctor baseline → score/errors |
| 4 | Атомарные commits (SHA + сообщение) |
| 5 | Phase 4–7 статусы + ссылки |
| 5b | Phase 7.5: черновик показан? / слать клиенту? / ключи? / текст согласован? / отправлено / пропуск |
| 5c | Phase 3.8 + 7.6: скан / найдено / удалено / ждём A/B/C / мусора не было |
| 6 | Блокеры (только если есть) |

**Этап работы** (одна фраза): план сегментов / review сегмента N/M / жду решения по backlog / проверки без упаковки / жду решения / уборка мусора до commits / жду что удалить / упаковываю / main→dev / выкладываю / жду CI / жду Vercel / жду решение по Telegram / жду ключи Telegram / согласование текста клиенту / уборка хвоста / готово на проде / только проверки.

В **safe** при стопе — Таблица 6 + строка: нужны решения по блокерам («чини» / «не чинить» / «отложить»); ночной прогон — `/MA-deploy auto`.

Итог одной строкой простым языком.

## Стоп (не успех / не merge)

- Dirty tree в 0–3.5 — **не** стоп; commits только в 3.9
- Успех без 3.9 при грязном дереве; push/PR без 3.95
- Critical/High сегмента не закрыты; ponytail `net ≤ -80` после автофикса в safe; нет `ponytail-review` на диске; сегменты заменены одним скопом на весь diff / открыты PR на куски
- Fail typecheck/lint/i18n/test; doctor errors/score; disk < 1 GiB / повторный ENOSPC
- Fail build/budget — **push запрещён**
- Supabase в diff без плана; красный CI; CI толще thin или дороже эталона (много job’ов / дубль PR); тяжёлые хуки
- PR conflict / fail checks; push не в `dev`; Vercel не READY
- Секреты / `.env` / tokens в diff — **всегда стоп**, даже в auto

## Skills / MCP (маршрутизация)

| Когда | Что |
|-------|-----|
| Любой ✅ | `verification-before-completion` |
| 1S | нарезка как `split-to-prs` (только план; без веток/PR) → `templates/segmented-review-ma-deploy.md` |
| 1A | `/code-review` (+ scoped `review-bugbot` / `review-security`) → Critical/High fix → `ponytail-review` **с автофиксом** |
| 1A-end | сводный backlog → решения (safe) / дешёвые Medium (auto) |
| 1B | typecheck ‖ lint ‖ i18n ‖ tests |
| Фиксы auto (вне 1A) | `systematic-debugging` |
| 2 | `react-doctor` |
| 3 budget fail | `performance-optimizer` |
| 3.5 | Supabase MCP |
| 5 fail | `ci-investigator` |
| 6 stuck | `babysit` |
| 7 | Vercel MCP + `vercel-cli` / `deployments-cicd`; smoke B → `agent-browser` |
| 7.5 | черновик (полный текст) + «слать?» → (если да) ключи → снова полный текст + «отправить» → `bootstrap/telegram-customer-update-send.sh` |
| 3.8 / 7.6 | скан мусора (до commits + хвост) → safe: A/B/C · auto: safe junk сразу, секреты/ask спросить → `templates/cleanup-ma-deploy.md` |
