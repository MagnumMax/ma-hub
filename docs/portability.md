# Портативность окружения

## Цель
На любом ноутбуке за минуты поднять ту же механику Monster Automation. Потеря диска не должна уничтожить стандарты, команды и MA-skills.

## Что где хранится

| Артефакт | Где истина | Как восстанавливается |
|----------|------------|------------------------|
| Стандарты продуктов | GitHub `ma-hub` / `standards/` | `git clone` + `bootstrap` |
| Команды `/MA-*` | GitHub `ma-hub` / `commands/` | `bootstrap` → `~/.cursor/commands/` |
| MA-owned skills | GitHub `ma-hub` / `skills/` | `bootstrap` → `~/.cursor/skills/` (+ agents/claude) |
| Путь к хабу | `~/.config/ma-hub/config` | пишет `bootstrap` |
| User Rules | Cursor Settings + бэкап `docs/user-rules.md` | вручную из файла после bootstrap |
| Сторонние skills / extensions | weekly script | `~/bin/update-cursor-weekly.sh` |
| Секреты проектов | не в ma-hub | password manager / per-project env |

## Новый ноутбук (чеклист)

1. Установить Cursor, git, Node (для skills)
2. `git clone https://github.com/MagnumMax/ma-hub.git ~/ma-hub`
3. `~/ma-hub/bootstrap/bootstrap.sh`
4. Восстановить **4** User Rules из `docs/user-rules.md` (включая правило про ma-hub)
5. Запустить `~/bin/update-cursor-weekly.sh` (сторонние skills + CLI)
6. `ma-hub-check-drift` — должно быть OK
7. Открыть проект → `/MA-help`

## Политика версий

- По умолчанию: **всегда latest с `main`**
- Weekly (и вручную `ma-hub-pull`) делает `git pull` и переустанавливает команды + MA-skills
- Критичный продукт: в `docs/MA-STANDARDS.md` проекта укажите pin tag; перед revise можно `MA_HUB_REF=vX.Y.Z ma-hub-pull`

## Правки только в хабе

Локальные `~/.cursor/commands` и `~/.cursor/skills` — **кэш**. Любое изменение MA-команд, MA-skills, стандартов или user-rules — сначала в репозитории ma-hub, потом install + commit/push. См. [`hub-maintenance.md`](hub-maintenance.md).

## Чего не коммитить в публичный ma-hub

- `.env`, ключи API, токены
- Личные заметки с секретами клиентов
