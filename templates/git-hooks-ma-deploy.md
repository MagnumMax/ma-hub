# Git hooks для всех проектов с `/MA-deploy`

**Универсальное правило (все продукты на Monster Automation):** не гонять полный test suite на git (ни хуки, ни GitHub Actions). Тесты — **только** локально в `/MA-deploy` Phase 1.

Это **жёсткий gate** внутри `/MA-deploy` Phase 0 — **как thin CI**:
- **auto** → агент сам приводит хуки к этому шаблону в рабочем дереве
- **safe** → стоп + «чини», без скрытого `--no-verify`

Thin CI (`typecheck` + `lint`) и локальный `pnpm test` + `pnpm build` в `/MA-deploy` **не** отменяем. Форма CI (один job, без дубля PR, без test) — см. `templates/ci-ma-deploy.md`. Исключений «для одного проекта» нет.

## Целевая схема

| Хук | Что запускать | Что не запускать |
|-----|---------------|------------------|
| **pre-commit** | lint-staged / format / быстрый eslint на staged | полный `pnpm test`, vitest, e2e, build |
| **pre-push** | по желанию: `pnpm typecheck` **один раз** на push | `pnpm test`, тот же suite повторно на каждый commit |
| **CI** | только thin+cheap: один job typecheck+lint; эталон `templates/ci-ma-deploy.md` | test, build, doctor, i18n, e2e; два job’а; дубль pull_request без форков |
| **`/MA-deploy` Phase 1** | полный локальный suite **включая tests** + ревью + i18n | — |
| **`/MA-deploy` Phase 3** | `pnpm build` (+ bundle budget) | — |

## Флаг упаковки релиза

`/MA-deploy` Phase 3.9 выставляет:

```bash
export MA_ATOMIC_PACKING=1
```

Хуки **должны** уважать флаг: при `MA_ATOMIC_PACKING=1` pre-commit пропускает полный test (если исторически остался) и оставляет только быстрые проверки.

### Пример (husky `pre-commit`)

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Быстрое на staged всегда
pnpm exec lint-staged

# Полный suite — НЕ здесь. Если исторически был test в pre-commit:
if [ "$MA_ATOMIC_PACKING" = "1" ]; then
  echo "MA_ATOMIC_PACKING=1 → skip full test on commit (already green in /MA-deploy Phase 1)"
  exit 0
fi

# Не запускать pnpm test в хуках — только в /MA-deploy Phase 1
```

### Пример (husky `pre-push`)

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Один раз на push — typecheck ок. Тесты — не здесь.
pnpm typecheck
```

## Чего избегать

- Полный vitest в **pre-commit** при 4+ атомарных commits Phase 3.9 → N полных прогонов подряд
- `pnpm test` в pre-push / pre-commit — тесты только в `/MA-deploy` Phase 1
- Слепой `git commit --no-verify` как постоянная практика агента
- Merge `main` в `dev` **после** первого push/PR → второй pre-push + второй CI

## Как внедрить в любом проекте

1. При `/MA-revise-project` или вручную сверить husky/lefthook с этой схемой — **обязательный** пункт аудита для каждого продукта
2. Убрать полный test из pre-commit и pre-push (оставить только `/MA-deploy` Phase 1)
3. Добавить ветку `MA_ATOMIC_PACKING=1` в pre-commit, если хук ещё может вызвать test
4. Не добавлять test в GitHub CI; не убирать локальный test (Phase 1) и build (Phase 3) из `/MA-deploy`
5. Форму CI (один job typecheck+lint, один триггер) сверять с `templates/ci-ma-deploy.md`
