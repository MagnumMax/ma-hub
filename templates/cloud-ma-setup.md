# Cloud Agent + ma-hub

Облачный агент **не видит** команды с вашего Mac (`~/.cursor/commands`).  
Чтобы `/MA-*` и стандарты были доступны в облаке — подтягивайте `ma-hub` при старте среды.

## Вариант A (рекомендую): update-команда среды

В продуктовом репозитории добавьте в `.cursor/environment.json` шаг `install` (или допишите к существующему):

```json
{
  "install": "git clone --depth 1 https://github.com/MagnumMax/ma-hub.git \"$HOME/ma-hub\" 2>/dev/null || true; \"$HOME/ma-hub/bootstrap/cloud-ensure.sh\""
}
```

Если `install` уже есть (например `npm install`), объедините:

```json
{
  "install": "npm install && (git clone --depth 1 https://github.com/MagnumMax/ma-hub.git \"$HOME/ma-hub\" 2>/dev/null || true) && \"$HOME/ma-hub/bootstrap/cloud-ensure.sh\""
}
```

`cloud-ensure.sh` сам клонирует хаб, если его ещё нет.

Добавьте в `.gitignore` проекта содержимое `templates/gitignore-ma-commands.snippet` — чтобы копии команд не уезжали в git.

## Вариант B: multi-repo environment

В [Cloud Agents → Environments](https://cursor.com/dashboard/cloud-agents#environments) добавьте репозиторий `ma-hub` рядом с продуктом.  
В `install` всё равно вызовите `cloud-ensure.sh` (или `ensure-latest.sh`), чтобы команды попали в кэш и в `.cursor/commands` проекта.

## AGENTS.md (фрагмент)

```md
## Cursor Cloud specific instructions

- Before using Monster Automation (`/MA-*`), ensure hub is present:
  `bash "$HOME/ma-hub/bootstrap/cloud-ensure.sh"` (or rely on environment `install`).
- Source of truth: https://github.com/MagnumMax/ma-hub — not copies on a laptop.
- Standards live in `$HOME/ma-hub/standards/` (track main unless the project pins a tag in `docs/MA-STANDARDS.md`).
```

## Что считается «новой версией»

`ensure-latest` сравнивает:

1. git SHA ветки хаба на `origin` с последним установленным SHA  
2. `standards/VERSION` с установленной версией  

Если что-то новее — pull + переустановка команд и MA-skills. Если нет — ничего не делает (быстрый старт).
