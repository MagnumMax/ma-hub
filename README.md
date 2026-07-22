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
4. Печатает инструкцию по восстановлению User Rules

Сторонние skills и расширения — отдельным weekly-скриптом (см. ниже).

## Еженедельное обновление (latest с main)

Уже в weekly maintenance, или вручную:

```bash
~/ma-hub/bootstrap/pull.sh
# или: ma-hub-pull
```

Тянет `main`, заново ставит команды и MA-skills из хаба (чтобы локальный кэш не устарел).

Проверка, что локальный кэш = хаб:

```bash
ma-hub-check-drift
```

## Что внутри

| Папка | Назначение |
|-------|------------|
| `standards/` | Закон продукта (дашборд, канбан, auth, релиз…) |
| `commands/` | Источник команд `/MA-*` |
| `skills/` | MA-owned skills (оркестраторы Monster Automation) |
| `bootstrap/` | Установка, pull, проверка drift |
| `templates/` | Тонкая ссылка для каждого проекта |
| `docs/user-rules.md` | Бэкап личных правил Cursor |
| `docs/hub-maintenance.md` | Как не забыть обновить хаб |
| `registry/` | Список ваших продуктов и статус revise |

## Слои (коротко)

- **Rules (Cursor)** — всегда: язык, уточнения, «Следующие задачи», закон ma-hub (бэкап в `docs/user-rules.md`)
- **Commands `/MA-*`** — ритуалы по вызову (ставятся из этого репо)
- **MA-skills** — оркестраторы MA (ставятся из `skills/`)
- **Сторонние skills** — Aaron, Vercel… (weekly update, не в хабе)
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
