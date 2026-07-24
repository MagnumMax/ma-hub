# ma-hub

Публичный источник правды для **Monster Automation**: стандарты продуктов, команды Cursor `/MA-*`, MA-owned skills, bootstrap окружения.

Один раз настроили — на любом ноутбуке поднимается та же механика. Проекты **не копируют** стандарты целиком: держат тонкую ссылку и всегда тянут **latest с `main`** (опционально — закреплённый тег).

## Быстрый старт (новый ноутбук / после поломки диска)

```bash
git clone https://github.com/MagnumMax/ma-hub.git ~/ma-hub
cd ~/ma-hub
./bootstrap/bootstrap.sh
```

Скрипт:
1. Запоминает путь хаба (`~/.config/ma-hub/config`)
2. Ставит команды `/MA-*` в `~/.cursor/commands/`
3. Ставит MA-owned skills в `~/.cursor/skills/` (+ ссылки для agents/claude)
4. Печатает инструкцию по восстановлению User Rules и установке **внешних** skills

Внешние skills (Aaron, Vercel, ponytail…): реестр `registry/external-skills.*` → `./bootstrap/install-external-skills.sh` (или weekly).

## Автообновление (latest)

После `bootstrap` на Mac:

1. **Ежедневно** — launchd `com.ma-hub.ensure-latest` (по умолчанию 09:15)
2. **При старте чата** — мягкий `sessionStart` hook, если кэш старше 24 часов
3. **Вручную / weekly** — принудительно:

```bash
ma-hub-ensure-latest          # умный: только если на origin новый SHA/VERSION
ma-hub-pull                   # то же с --force (всегда pull + install)
ma-hub-check-drift            # кэш == хаб?
```

Логика «есть ли новое»: git SHA ветки на `origin` и `standards/VERSION` vs `~/.config/ma-hub/installed-state`.

Облачный агент: [`templates/cloud-ma-setup.md`](templates/cloud-ma-setup.md) · процесс: [`docs/auto-sync.md`](docs/auto-sync.md)

## Что внутри

| Папка | Назначение |
|-------|------------|
| `standards/` | Закон продукта (дашборд, канбан, auth, релиз…) |
| `commands/` | Источник команд `/MA-*` |
| `skills/` | MA-owned skills (оркестраторы Monster Automation) |
| `registry/` | Проекты + **ссылки** на внешние skills (`external-skills.*`) |
| `bootstrap/` | Установка, ensure-latest, cloud-ensure, drift |
| `templates/` | Тонкая ссылка для каждого проекта + cloud setup |
| `docs/user-rules.md` | Бэкап личных правил Cursor |
| `docs/hub-maintenance.md` | Как не забыть обновить хаб |
| `docs/auto-sync.md` | Daily/version sync + Cloud Agent |

## Слои (коротко)

- **Rules (Cursor)** — всегда: язык, уточнения, «Следующие задачи», закон ma-hub (бэкап в `docs/user-rules.md`)
- **Commands `/MA-*`** — ритуалы по вызову (ставятся из этого репо)
- **MA-skills** — оркестраторы MA (ставятся из `skills/`)
- **Внешние skills** — только ссылки в `registry/`; тела с upstream через `install-external-skills.sh`
- **Standards** — требования к продуктам (эта папка `standards/`)

## Если меняете команды / skills / стандарты

**Правьте только этот репозиторий**, не «только на ноутбуке». Чеклист: [`docs/hub-maintenance.md`](docs/hub-maintenance.md).

## В каждом проекте

Скопируйте шаблон `templates/project-ma-link.md` → `docs/MA-STANDARDS.md`.  
Политика по умолчанию: **track `main`** (всегда свежее). Для критичного продукта можно закрепить тег.

Затем: `/MA-revise-project`.

## Версии

- Версия стандартов: `standards/VERSION`
- Политика: всегда latest с `main` + weekly pull; для критичных продуктов — pin tag в `docs/MA-STANDARDS.md`
