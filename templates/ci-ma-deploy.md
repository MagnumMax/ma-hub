# Thin CI для всех проектов с `/MA-deploy`

**Универсальное правило:** минуты GitHub Actions = **число runner-job’ов × число запусков на один коммит**. Режьте дубли событий и лишний параллелизм с повторным `install`.

Это **жёсткий gate** внутри `/MA-deploy` Phase 0 (рядом с thin-составом и хуками):
- **auto** → агент приводит `.github/workflows/*` к этой схеме в рабочем дереве (без commit до Phase 3.9)
- **safe** → стоп + «чини», без «подождать толстые/дорогие job’ы»

**Состав CI:** `typecheck` + `lint`. Полный `test` — **только локально** в `/MA-deploy` Phase 1. Build / doctor / i18n / e2e — тоже локально.

## Целевая схема

| Рычаг | Правило | Зачем |
|-------|---------|--------|
| **Состав** | только `typecheck` и/или `lint` | быстрый safety net на GitHub; тесты — локально |
| **Job’ы** | **один** job: install → typecheck → lint подряд | два job’а = два install ≈ ×2 минут |
| **Триггеры** | только `push` на `main` и `dev` | `push` + `pull_request` = 2–3 прогона на один шип |
| **Concurrency** | `cancel-in-progress: true` | частые push не копят устаревшие прогоны |
| **Не в CI** | `pnpm test`, Playwright / e2e, полный build | тесты — Phase 1 `/MA-deploy`; build — Phase 3 |

### Когда оставлять `pull_request`

По умолчанию для MA-проектов **убирать** (`dev` → PR → `main` в **своём** репо): checks на PR берутся с того же SHA, что уже прогнали после push в `dev`.

Оставлять `pull_request`, если в `AGENTS.md` Local deviations явно: **есть форки** / внешние PR. Тогда не дублировать без нужды: либо только `pull_request`, либо осознанно оба (дорого).

### Имена checks / branch protection

После склейки/смены состава имя check меняется (эталон: `typecheck-and-lint`; старое `typecheck-and-test` — обновить). Обновить required status checks в настройках ветки `main`/`dev`, иначе PR «залипнет» на старых именах.

## Эталонный workflow

Скопировать в проект как `.github/workflows/ci.yml` (или привести существующий CI-файл к этой форме).  
Адаптировать: версия Node/pnpm, `typegen` если есть в `package.json`, composite `setup-*` если уже есть в репо. Не добавлять test/build/e2e сюда. Нет script `lint` — оставить только typecheck (один job).

```yaml
name: CI

on:
  push:
    branches: [main, dev]
  # Нет pull_request по умолчанию (свой репо, поток MA: push dev → checks на том же SHA видны в PR).
  # Форки / внешние PR → см. Local deviations и добавьте pull_request.

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

# Thin safety net for /MA-deploy: typecheck + lint only.
# Tests, i18n, react-doctor, build, bundle-budget run locally before push.
jobs:
  ci:
    name: typecheck-and-lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v4
        with:
          version: 10

      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: pnpm

      - name: Install
        run: pnpm install --frozen-lockfile

      # Раскомментировать, если в package.json есть script typegen (Next.js):
      # - name: Typegen
      #   run: pnpm typegen

      - name: Typecheck
        run: pnpm typecheck

      - name: Lint
        run: pnpm lint
```

## Gate-чеклист (Phase 0 / revise)

1. Есть CI workflow с typecheck/lint? Нет → Phase 5 skip (не блокер само по себе).
2. Есть job’ы кроме typecheck/lint (`test`, build, e2e, doctor, i18n…)? → блокер «CI толще шаблона» (в т.ч. `pnpm test` в Actions).
3. Два+ job’а, каждый со своим install, для typecheck/lint? → блокер «CI дороже эталона (склеить в один job)».
4. Одновременно `push` и `pull_request` на `main`/`dev` **и** нет Local deviation «форки»? → блокер «дубль событий на коммит».
5. Нет `concurrency` / `cancel-in-progress`? → в auto добавить; в safe — замечание (не жёсткий блокер, если остальное ок).
6. `CI_JOBS_TO_WAIT` = имя **одного** тонкого job’а (эталон: `typecheck-and-lint`).

## Чего избегать

- Отдельные job’ы `Typecheck` и `Lint` с двумя `pnpm install`
- `on: push` + `on: pull_request` на те же ветки в своём репо без форков
- `pnpm test` / vitest / Playwright в GitHub Actions — тесты только локально в `/MA-deploy` Phase 1
- Тяжёлый e2e/Playwright или полный build в том же workflow
- Убирать typecheck/lint из CI или локальный `pnpm test` + `pnpm build` из `/MA-deploy`

## Как внедрить в любом проекте

1. Сверить `.github/workflows/` с этим файлом при `/MA-revise-project` или Phase 0 `/MA-deploy`
2. Склеить typecheck+lint в один job; **убрать `pnpm test` из Actions**; убрать `pull_request` (если нет форков)
3. Добавить concurrency; обновить required checks под новое имя job (`typecheck-and-lint`)
4. Один раз проверить: push в `dev` → один зелёный check; на PR тот же check виден
5. Не возвращать test в CI; не убирать локальный `pnpm test` (Phase 1) и `pnpm build` (Phase 3) из `/MA-deploy`

Связанный эталон хуков: `templates/git-hooks-ma-deploy.md`.
