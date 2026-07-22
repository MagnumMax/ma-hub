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
| `ponytail-review` | `dietrichgebert/ponytail` | `/MA-deploy` (Phase 1) |
| `ponytail` | `dietrichgebert/ponytail` | `/MA-idea-to-plan` (bias простоты) |
| `react-doctor` | `millionco/react-doctor` | `/MA-deploy` Phase 2 |
| `agent-browser` | `vercel-labs/agent-browser` | `/MA-deploy` Phase 7 smoke B |
| `verification-before-completion` | `obra/superpowers` | все `/MA-*` |
| `systematic-debugging` | `obra/superpowers` | `/MA-deploy` auto-fix |
| `impeccable` | `pbakaus/impeccable` | `/MA-design-screen` |
| Aaron SEO + GEO tracks | `aaron-he-zhu/aaron-marketing-skills` | `/MA-seo-geo-audit` (+ skill `seo-geo-audit`) |

Полный список skills в каждом пакете — в `.manifest`.

## Cursor-native (не в manifest)

Ставятся с Cursor, не через `npx skills add`:

| Skill | Локальный путь | Команды MA |
|-------|----------------|------------|
| `review-bugbot` | `~/.cursor/skills-cursor/review-bugbot/` | `/MA-deploy` Phase 1 |
| `review-security` | `~/.cursor/skills-cursor/review-security/` | `/MA-deploy` Phase 1 |

## Политика свежести

| Когда | Действие |
|-------|----------|
| Bootstrap / weekly / вручную | `install-external-skills.sh` → свежие копии с upstream |
| Каждый запуск `/MA-*` | только `Read` локального `SKILL.md` (без сети в середине ритуала) |

Не вшивать текст skill в команду: после weekly обновления автора skill команда автоматически получит новую логику.
