# Git hooks для всех проектов с `/MA-deploy`

**Универсальное правило (все продукты на Monster Automation):** не гонять полный test suite на каждый атомарный commit при упаковке релиза.

Thin CI (`typecheck` + `test`) и локальный `pnpm build` в `/MA-deploy` **не** отменяем — меняем только **где** полный suite запускается. Исключений «для одного проекта» нет.

## Целевая схема

| Хук | Что запускать | Что не запускать |
|-----|---------------|------------------|
| **pre-commit** | lint-staged / format / быстрый eslint на staged | полный `pnpm test`, vitest без фильтра, e2e, build |
| **pre-push** | по желанию: `pnpm typecheck` и/или `pnpm test` **один раз** на push | тот же suite повторно на каждый commit |
| **CI** | только thin: `typecheck` + `test` | lint, build, doctor, i18n |
| **`/MA-deploy` Phase 1** | полный локальный suite + ревью + lint/i18n | — |
| **`/MA-deploy` Phase 3** | `pnpm build` (+ bundle budget) | — |

## Флаг упаковки релиза

`/MA-deploy` Phase 3.9 выставляет:

```bash
export MA_ATOMIC_PACKING=1
```

Хуки **должны** уважать флаг: при `MA_ATOMIC_PACKING=1` pre-commit пропускает полный test и оставляет только быстрые проверки.

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

# Опционально: полный test только вне упаковки (лучше перенести в pre-push)
# pnpm test
```

### Пример (husky `pre-push`)

```sh
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

# Один раз на push — ок. /MA-deploy сначала делает Phase 3.95 (main→dev), потом один push.
pnpm typecheck && pnpm test
```

## Чего избегать

- Полный vitest в **pre-commit** при 4+ атомарных commits Phase 3.9 → N полных прогонов подряд
- Слепой `git commit --no-verify` как постоянная практика агента
- Merge `main` в `dev` **после** первого push/PR → второй pre-push + второй CI

## Как внедрить в любом проекте

1. При `/MA-revise-project` или вручную сверить husky/lefthook с этой схемой — **обязательный** пункт аудита для каждого продукта
2. Перенести полный test из pre-commit в pre-push (или оставить только `/MA-deploy` + CI)
3. Добавить ветку `MA_ATOMIC_PACKING=1` в pre-commit
4. Не ослаблять thin CI и не убирать локальный build из `/MA-deploy`
