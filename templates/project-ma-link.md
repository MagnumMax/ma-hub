# Шаблон: ссылка на ma-hub в проекте

Скопируйте в проект как `docs/MA-STANDARDS.md` (при `/MA-revise-project` или вручную).

**Не копируйте папку standards целиком** — только эту ссылку. Иначе версии устареют.

```md
# MA Standards link

- Hub: https://github.com/MagnumMax/ma-hub
- Local hub path: ~/ma-hub (после bootstrap)
- Policy: track main
- Pin: (пусто = всегда latest; иначе например v1.0.0)
- Applied standards version: X.Y.Z  (из standards/VERSION на момент последнего revise)
- Last revise: YYYY-MM-DD
- Local deviations:
  - …
```

## Политика

- **track main** — рекоменуется: weekly `ma-hub-pull` держит свежие стандарты и команды.
- **pin** — только для критичных продуктов; перед revise осознанно обновить pin.
