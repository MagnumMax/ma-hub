# Шаблон: ссылка на ma-hub в проекте

Скопируйте в проект как `docs/MA-STANDARDS.md` (при `/MA-revise-project` или вручную).

**Не копируйте папку standards целиком** — только эту ссылку. Иначе версии устареют.

В продукте должна быть **одна** такая визитка. Другие файлы с копиями правил MA — при revise: перенести нужное сюда, затем удалить дубль или оставить короткую ссылку на этот файл (см. `/MA-revise-project`).

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

## Обязательные пути релиза

Формат — эталон `$MA_HUB_ROOT/templates/release-must-work-paths.md`. 5–10 путей этого продукта. Не копировать чужой список.

| Путь | Когда | Область | Роль |
|------|--------|---------|------|
| … | always | auth | manager |
| … | always | home | manager |
| … | if-touched | … | … |
```

## Политика

- **track main** — рекомендуется: daily `ma-hub-ensure-latest` (и weekly/`ma-hub-pull`) держит свежие стандарты и команды. Для Cloud Agent см. `templates/cloud-ma-setup.md`.
- **pin** — только для критичных продуктов; перед revise осознанно обновить pin.
- **без дублей** — не держать вторые копии стандартов MA в `docs/`, Cursor rules и т.п.; уникальное локальное — только здесь (раздел Local deviations).
- **git-хуки** — универсальное правило для всех продуктов с `/MA-deploy`: см. `templates/git-hooks-ma-deploy.md` (лёгкий pre-commit, полный test не на каждый атомарный commit).
- **CI (минуты Actions)** — эталон `templates/ci-ma-deploy.md`: один job typecheck+test, только push на main/dev; дубль pull_request — только если в Local deviations «есть форки».
- **Клиентский Telegram после прода** — эталон `templates/telegram-customer-update-ma-deploy.md` (Phase 7.5 `/MA-deploy`, всегда согласование текста).
- **Обязательные пути релиза** — блок в этой визитке (эталон `templates/release-must-work-paths.md`). Пишет `/MA-revise-project`; `/MA-deploy` без списка не стартует (можно дописать в том же выкате). Полную сверку из выката не запускать.
