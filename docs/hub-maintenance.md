# Hub maintenance — источник правды Monster Automation

## Закон

**Репозиторий ma-hub — единственный источник правды** для:

| Артефакт | Путь в хабе | Локальный кэш (не коммитить как истину) |
|----------|-------------|------------------------------------------|
| Команды `/MA-*` | `commands/MA-*.md` | `~/.cursor/commands/` |
| MA-skills | `skills/<name>/` | `~/.cursor/skills/`, `~/.agents/skills/`, `~/.claude/skills/` |
| Реестр внешних skills | `registry/external-skills.*` | локальные копии skills после `install-external-skills.sh` |
| Стандарты продуктов | `standards/` | читаются из хаба напрямую |
| Бэкап User Rules | `docs/user-rules.md` | Cursor Settings → Rules |

Сторонние skills (Aaron, Vercel, ponytail, impeccable…) **не** хранятся текстом в ma-hub — только **ссылки на upstream** в `registry/`. Команды **читают** актуальный `SKILL.md` с диска.

## Если меняете команды / MA-skills / стандарты / user-rules

Ассистент **обязан** (без напоминания пользователя):

1. Править файлы **в `$MA_HUB_ROOT`**, не только в `~/.cursor/…`
2. При новой команде / MA-skill — положить в `commands/` или `skills/`, обновить `commands/MA-help.md`
3. При новой **внешней** зависимости skill — добавить в `registry/external-skills.manifest` + строку в `registry/external-skills.md` (не копировать тело skill)
4. При изменении `standards/` — bump `standards/VERSION` (semver, см. `docs/versioning.md`)
5. Прогнать установку кэша:
   ```bash
   $MA_HUB_ROOT/bootstrap/install-commands.sh
   $MA_HUB_ROOT/bootstrap/install-skills.sh
   # при изменении registry или на новом Mac:
   $MA_HUB_ROOT/bootstrap/install-external-skills.sh
   # или: ma-hub-ensure-latest
   ```
6. Проверить: `$MA_HUB_ROOT/bootstrap/check-local-drift.sh`
7. **Закоммитить и запушить ma-hub** (если пользователь просит commit — сделать; если нет — явно сказать: «изменения только в хабе, нужен commit+push, иначе другие проекты/облако не увидят»)
8. На других Mac / в облаке обновление подхватится само: daily `ensure-latest`, session hook, или `cloud-ensure` при старте Cloud Agent (`templates/cloud-ma-setup.md`)

Запрещено оставлять новую `/MA-*` или MA-skill **только** в `~/.cursor/` — после `ma-hub-pull` на другом Mac её не будет.
Запрещено вендорить чужой `SKILL.md` в ma-hub «на всякий случай» — только манифест + `Read` с диска.

## Skills и проекты (общее правило)

**Список skills живёт в хабе, не в каждом продукте.**

| Слой | Где список | Как проекты его получают |
|------|------------|---------------------------|
| MA-owned | `skills/` | `install-skills.sh` / `ma-hub-ensure-latest` на машине |
| Внешние | `registry/external-skills.*` | `install-external-skills.sh` (после смены registry — обязательно; иначе weekly) |
| Cursor-native | продукт Cursor | обновление Cursor |

Правила:

1. **Не** хранить в проекте отдельный «наш список skills» (копия манифеста, дубль таблицы из `external-skills.md` и т.п.). Проект работает по latest хаба (или pin в визитке).
2. После изменения `registry/external-skills.*` или `skills/` в хабе ассистент **обязан**:
   - прогнать установку кэша (см. чеклист выше; для registry — ещё `install-external-skills.sh`);
   - явно напомнить: без commit+push другие Mac / Cloud Agent / проекты не увидят новый набор;
   - на текущей машине убедиться, что кэш обновлён (иначе команды `/MA-*` в любом открытом проекте читают старые или отсутствующие skills).
3. При `/MA-revise-project` — проверить, что машина подтянула актуальный набор skills хаба (MA + внешние из registry); при пробелах — предложить `ma-hub-ensure-latest` и/или `install-external-skills.sh` **до** или **в первом пакете** плана. Не плодить списки skills внутри продукта.

Итог: обновили хаб → обновили кэш skills на машине → все подключенные проекты сразу работают с тем же набором. Отдельный «список skills проекта» не нужен.

## Проекты

Проекты подключаются тонкой ссылкой `docs/MA-STANDARDS.md` (шаблон `templates/project-ma-link.md`) и командами, установленными из хаба на машине. Они **не копируют** `commands/` и `standards/` целиком.

При `/MA-revise-project`: если в проекте уже есть файлы с копиями стандартов / описаний MA — **не плодить ещё один набор**. Нужное и уникальное перенести в `docs/MA-STANDARDS.md`; дубли удалить или заменить короткой ссылкой на визитку (удаление — только после «ок» пользователя). Чисто продуктовые правила (бренд, домен) не сносить.
