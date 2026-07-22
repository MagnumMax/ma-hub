# Портативность окружения

## Цель
На любом ноутбуке за минуты поднять ту же механику Monster Automation. Потеря диска не должна уничтожить стандарты и команды.

## Что где хранится

| Артефакт | Где истина | Как восстанавливается |
|----------|------------|------------------------|
| Стандарты продуктов | GitHub `ma-hub` / `standards/` | `git clone` + `bootstrap` |
| Команды `/MA-*` | GitHub `ma-hub` / `commands/` | `bootstrap` → `~/.cursor/commands/` |
| Путь к хабу | `~/.config/ma-hub/config` | пишет `bootstrap` |
| User Rules | Cursor Settings + бэкап `docs/user-rules.md` | вручную из файла после bootstrap |
| Skills / extensions | weekly script | `~/bin/update-cursor-weekly.sh` |
| Секреты проектов | не в ma-hub | password manager / per-project env |

## Новый ноутбук (чеклист)

1. Установить Cursor, git, Node (для skills)
2. `git clone https://github.com/MagnumMax/ma-hub.git ~/ma-hub`
3. `~/ma-hub/bootstrap/bootstrap.sh`
4. Восстановить 3 User Rules из `docs/user-rules.md`
5. Запустить `~/bin/update-cursor-weekly.sh` (skills + CLI)
6. Открыть проект → `/MA-help`

## Политика версий

- По умолчанию: **всегда latest с `main`**
- Weekly (и вручную `ma-hub-pull`) делает `git pull` и переустанавливает команды
- Критичный продукт: в `docs/MA-STANDARDS.md` проекта укажите pin tag; перед revise можно `MA_HUB_REF=vX.Y.Z ma-hub-pull`

## Чего не коммитить в публичный ma-hub

- `.env`, ключи API, токены
- Личные заметки с секретами клиентов
