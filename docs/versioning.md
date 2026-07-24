# Версионирование

## standards/VERSION

Semver для содержимого `standards/`:

- **MAJOR** — ломающие требования (старые проекты надо пересмотреть)
- **MINOR** — новые предпочтения без ломки; новые MA-команды / MA-skills, отражённые в operating model
- **PATCH** — формулировки и уточнения

После bump: `git tag vX.Y.Z` (опционально) и push. Weekly pull подхватит `main`.

## Политика для проектов

| Режим | Когда | Как |
|-------|--------|-----|
| **track main** (дефолт) | обычные продукты | daily `ma-hub-ensure-latest` (+ weekly/force `ma-hub-pull`); revise читает текущий `~/ma-hub` |
| **pin tag** | критичный прод, не хотим сюрпризов | в `docs/MA-STANDARDS.md`: `Pin: v1.0.0`; `MA_HUB_REF=v1.0.0 ma-hub-ensure-latest` |

Проекты **не хранят копию** стандартов целиком — только ссылку и режим. Иначе копии устаревают.

## Stamp автообновления

Файл `~/.config/ma-hub/installed-state` после успешного install:

- `GIT_SHA` — какой коммит хаба установлен в локальный кэш
- `STANDARDS_VERSION` — значение `standards/VERSION` на тот момент
- `UPDATED_AT` — время sync

`ensure-latest` делает `git fetch` и обновляет кэш **только если** remote SHA или VERSION новее stamp (либо передан `--force`).

## Команды и MA-skills

- `commands/` и `skills/` (MA-owned) версионируются вместе с хабом (тот же git commit).
- `install-commands.sh` / `install-skills.sh` всегда копируют актуальные файлы в локальный кэш.
- **Внешние skills:** только ссылки в `registry/external-skills.*`; тела skills не в git. Обновление: `install-external-skills.sh`.
- `check-local-drift.sh` сравнивает кэш MA-команд/MA-skills с хабом и падает, если что-то правили «только локально».

Истина MA = репозиторий. Истина внешних skills = upstream (локальная копия обновляется скриптом). Кэш на ноутбуке не коммитят и не считают источником.
