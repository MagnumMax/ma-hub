# Hub maintenance — источник правды Monster Automation

## Закон

**Репозиторий ma-hub — единственный источник правды** для:

| Артефакт | Путь в хабе | Локальный кэш (не коммитить как истину) |
|----------|-------------|------------------------------------------|
| Команды `/MA-*` | `commands/MA-*.md` | `~/.cursor/commands/` |
| MA-skills | `skills/<name>/` | `~/.cursor/skills/`, `~/.agents/skills/`, `~/.claude/skills/` |
| Стандарты продуктов | `standards/` | читаются из хаба напрямую |
| Бэкап User Rules | `docs/user-rules.md` | Cursor Settings → Rules |

Сторонние skills (Aaron, Vercel, impeccable…) **не** хранятся в ma-hub — только MA-owned.

## Если меняете команды / MA-skills / стандарты / user-rules

Ассистент **обязан** (без напоминания пользователя):

1. Править файлы **в `$MA_HUB_ROOT`**, не только в `~/.cursor/…`
2. При новой команде / skill — положить в `commands/` или `skills/`, обновить `commands/MA-help.md`
3. При изменении `standards/` — bump `standards/VERSION` (semver, см. `docs/versioning.md`)
4. Прогнать установку кэша:
   ```bash
   $MA_HUB_ROOT/bootstrap/install-commands.sh
   $MA_HUB_ROOT/bootstrap/install-skills.sh
   ```
5. Проверить: `$MA_HUB_ROOT/bootstrap/check-local-drift.sh`
6. **Закоммитить и запушить ma-hub** (если пользователь просит commit — сделать; если нет — явно сказать: «изменения только в хабе, нужен commit+push, иначе другие проекты не увидят»)

Запрещено оставлять новую `/MA-*` или MA-skill **только** в `~/.cursor/` — после `ma-hub-pull` на другом Mac её не будет.

## Проекты

Проекты подключаются тонкой ссылкой `docs/MA-STANDARDS.md` (шаблон `templates/project-ma-link.md`) и командами, установленными из хаба на машине. Они **не копируют** `commands/` и `standards/` целиком.
