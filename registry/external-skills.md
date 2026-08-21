# Внешние skills — ссылки на источники

**В ma-hub не храним текст чужих skills.** Здесь только манифест: откуда тянуть, куда читать, какие `/MA-*` используют.

| Слой | Где истина | Как обновляется |
|------|------------|-----------------|
| **MA-owned** (`skills/` в хабе) | этот репозиторий | `install-skills.sh` / `ma-hub-pull` |
| **Внешние** (этот реестр) | upstream (GitHub / skills CLI) | `install-external-skills.sh` / weekly |
| **Cursor-native** | продукт Cursor (`~/.cursor/skills-cursor/`) | обновление Cursor |

## Правило для агента

1. **Не** копировать содержимое skill в команду `/MA-*`.
2. Перед использованием: **прочитать** актуальный `SKILL.md` с диска (пути ниже).
3. Если файла нет — блокер: запустить `$MA_HUB_ROOT/bootstrap/install-external-skills.sh` (или weekly).
4. Машиночитаемый список пакетов: [`external-skills.manifest`](external-skills.manifest).

## Разрешение пути к skill (первый найденный)

1. `~/.agents/skills/<name>/SKILL.md`
2. `~/.cursor/skills/<name>/SKILL.md`
3. `~/.claude/skills/<name>/SKILL.md`
4. `~/.cursor/skills-cursor/<name>/SKILL.md` (только Cursor-native)

## Пакеты (npx skills)

Источник правды для `npx skills add`: `external-skills.manifest`.  
Установка: `bootstrap/install-external-skills.sh`.

Ключевые зависимости MA-команд:

| Skill | Upstream package | Команды MA |
|-------|------------------|------------|
| `ponytail-review` | `dietrichgebert/ponytail` | `/MA-deploy` Phase 1A (сегменты; **с автофиксом** + таблица `net`/`Lean already` по куску). Прочитать skill ≠ прогнать. Не путать с simplify в `/MA-product-pass` |
| `ponytail` | `dietrichgebert/ponytail` | `/MA-idea-to-plan` (вкус простоты, не автофикс деплоя) |
| `react-doctor` | `millionco/react-doctor` | `/MA-deploy` Phase 2 |
| `agent-browser` | `vercel-labs/agent-browser` | `/MA-deploy` Phase 7: обязательные пути на проде |
| `shadcn` | `shadcn/ui` | `/MA-design-screen` |
| `vercel-react-best-practices` | `vercel-labs/agent-skills` | `/MA-design-screen` |
| `supabase-postgres-best-practices` | `supabase/agent-skills` | сверка проекта / база |
| Aaron SEO + GEO tracks | `aaron-he-zhu/aaron-marketing-skills` | `/MA-seo-geo-audit` (+ skill `seo-geo-audit`) |

Полный список skills в каждом пакете — в `.manifest`.

## Cursor-native (не в manifest)

Ставятся с Cursor, не через `npx skills add`:

| Skill | Локальный путь | Команды MA |
|-------|----------------|------------|
| `review-bugbot` | `~/.cursor/skills-cursor/review-bugbot/` | `/MA-deploy` Phase 1A: только если сегмент меняет **поведение**; scoped по куску; **не** `/review` |
| `review-security` | `~/.cursor/skills-cursor/review-security/` | `/MA-deploy` Phase 1A: если сегмент про **вход / роли / платежи / PII / секреты**; scoped по куску; **не** `/review` |

## Политика свежести

| Когда | Действие |
|-------|----------|
| Bootstrap / weekly / вручную | `install-external-skills.sh` → свежие копии с upstream |
| Смена этого registry в хабе | сразу `install-external-skills.sh` на машине + commit/push хаба; проекты **не** хранят свой список skills |
| `/MA-revise-project` | проверить кэш внешних skills; при пробелах — установка в первом пакете |
| Каждый запуск `/MA-*` | только `Read` локального `SKILL.md` (без сети в середине ритуала) |

Не вшивать текст skill в команду: после weekly обновления автора skill команда автоматически получит новую логику.  
Не копировать этот реестр в репозитории продуктов — см. `docs/hub-maintenance.md` → «Skills и проекты».
