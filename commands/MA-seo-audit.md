---
description: "MA · Monster Automation — полный SEO-аудит через Aaron Marketing Skills"
argument-hint: "<URL или домен> [full|page|tech|structure|authority|quick|pre-deploy|post-deploy]"
---

# MA-seo-audit

Проведи **SEO-аудит** для указанной цели. Я не SEO-специалист — веди ритуал сам, объясняй простым языком итог и что чинить первым.

**Вход:** $ARGUMENTS

**Этот `/MA-seo-audit` — единственная MA-команда полного SEO-аудита.** Оркестратор: skill `seo-audit`. Специалисты: установленный пакет **Aaron Marketing Skills** (не ставить Corey Haines `seo-audit` и не смешивать чужие чеклисты).

## Hub (обязательно)

Найди **ma-hub**: `~/.config/ma-hub/config` → `MA_HUB_ROOT`, иначе `~/ma-hub`.  
Источник правды skill-оркестратора: **`$MA_HUB_ROOT/skills/seo-audit/`** (кэш: `~/.cursor/skills/seo-audit/`).  
Локальные SEO-чеклисты проекта (если есть) учитывай, но **не подменяй** ими треки Aaron.  

Если правишь эту команду или skill — только в ma-hub, затем `install-commands` + `install-skills` + commit/push (см. `docs/hub-maintenance.md`).

## Разбор входа

Из `$ARGUMENTS` извлеки:

| Поле | Как понять | Дефолт |
|------|------------|--------|
| **Цель** | URL / домен / «localhost:порт» | Если нет — спроси один раз |
| **Режим** | `full` `page` `tech` `structure` `authority` `quick` `pre-deploy` `post-deploy` | `full`; если явно localhost / «ещё не на проде» → `pre-deploy` |
| **P0-страницы** | если перечислены | главная + главная коммерческая/apply + 1 хаб (если находятся) |

Примеры вызова:

```text
/MA-seo-audit https://www.example.com
/MA-seo-audit http://localhost:4567 pre-deploy
/MA-seo-audit https://www.example.com/services/x page
/MA-seo-audit https://www.example.com quick
/MA-seo-audit https://www.example.com post-deploy
```

## Обязательно: skill `seo-audit`

1. Прочитай и следуй skill **`seo-audit`**: сначала `$MA_HUB_ROOT/skills/seo-audit/SKILL.md`, иначе кэш `~/.cursor/skills/seo-audit/SKILL.md`.
2. Для каждого трека режима **открой** соответствующий Aaron skill и выполни его контракт:
   - техника → `technical-seo-checker`
   - разметка (только gaps) → `serp-markup-builder`
   - страница → `on-page-seo-checker`
   - качество контента → `content-quality-auditor`
   - структура → `site-structure-optimizer`
   - доверие домена → `domain-authority-auditor`
3. Опционально (только если просили или всплыл блокер): `geo-content-optimizer`, `offsite-signal-analyzer`, `rank-tracker`, `performance-monitor`, `competitor-analysis`, `serp-analysis`, `content-gap-analysis`.

Шаблоны режимов, приоритетов и отчёта:  
`seo-audit/references/modes.md`, `prioritization.md`, `report-template.md`.

## Жёсткие правила

- Метрики только с меткой **Measured** / **User-provided** / **Estimated**; не выдумывать CWV, позиции, DA.
- **Не** склеивать CORE-EEAT и CITE в один «общий балл /100» — карточки по трекам отдельно.
- Localhost ≠ индекс Google; в `pre-deploy` trust домена смотри на **прод**, если домен уже есть.
- JS/SPA: смотри отрендеренный DOM, не только пустой shell.
- Пиши отчёт **на русском**, без лишнего жаргона.
- Файлы на диск — только если я явно попросил сохранить.

## Выход (всегда)

Формат из `seo-audit/references/report-template.md`:

1. Краткий вывод (состояние, топ-риски, топ-сильные стороны, первый шаг)
2. Объём проверки (режим, база, URL)
3. Карточки по трекам Aaron
4. Бэклог P0 → P1 → P2 → Later
5. Пробелы в данных
6. Что проверить только после деплоя (если актуально)
7. Что делать дальше (включая повтор: `/MA-seo-audit <url> quick` после P0)

**Стоп после отчёта.** Не начинай правки кода, пока я не скажу «чини» / не выберу пункты бэклога.
