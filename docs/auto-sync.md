# Автосинхронизация ma-hub

Цель: на Mac и в облаке всегда latest-правила/команды/skills — без ручного «не забыть сделать pull».

## Как понимаем, что есть обновление

После каждой успешной установки пишется stamp:

`~/.config/ma-hub/installed-state`

```
GIT_SHA=...
STANDARDS_VERSION=1.3.4
UPDATED_AT=...
```

`bootstrap/ensure-latest.sh`:

1. `git fetch origin`
2. Сравнивает SHA на `origin/<ветка>` с `GIT_SHA` в stamp
3. Сравнивает `standards/VERSION` с `STANDARDS_VERSION`
4. Если всё совпадает — выходит сразу  
   Если нет — `pull` (ff-only) + `install-commands` + `install-skills` + новый stamp

Ручной принудительный sync: `ma-hub-pull` (= `ensure-latest --force`).

## Mac (локальный агент)

| Триггер | Что |
|---------|-----|
| `bootstrap.sh` | ставит кэш, launchd, session hook |
| launchd daily ~09:15 | `ensure-latest --quiet` |
| Cursor `sessionStart` | если stamp старше 24ч — soft sync |
| weekly `update-cursor-weekly.sh` | `ma-hub-pull` (force) |

Переустановить автозапуск:

```bash
ma-hub-install-launch-agent
ma-hub-install-session-hook
```

Логи: `~/Library/Logs/ma-hub/`.

## Cloud Agent

Ноутбук **не монтируется**. Нужен `cloud-ensure.sh` в `install` среды или multi-repo + тот же скрипт.

Подробно: [`templates/cloud-ma-setup.md`](../templates/cloud-ma-setup.md).

## User Rules (Cursor Settings)

Личные правила в Settings Cursor **не** перезаписываются скриптом (они в аккаунте приложения).  
Бэкап: `docs/user-rules.md`. После смены правил — обновите Settings и этот файл в хабе.

Команды `/MA-*`, MA-skills и `standards/` — да, едут через ensure-latest / cloud-ensure.
