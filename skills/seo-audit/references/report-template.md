# SEO Audit report template

Write the user-facing report in the user's language (default: Russian). Keep skill names in backticks when useful.

```markdown
# SEO Audit — <domain or URL>
**Дата:** YYYY-MM-DD
**Режим:** full | page | tech | …
**База:** <primary base> · **Прод-домен:** <if different>

## Краткий вывод
- Состояние: <1 фраза>
- Главные риски: <до 3>
- Что уже хорошо: <до 3>
- Первый шаг: <одна конкретная правка>

## Объём проверки
| Что | Значение |
|-----|----------|
| Режим | |
| URL (P0) | |
| Пропущенные треки | |
| Ограничения среды | localhost / нет GSC / … |

## Карточки по трекам
| Трек | Навык Aaron | Итог | Доказательства |
|------|-------------|------|----------------|
| Техника | `technical-seo-checker` | score / статус | Measured / Estimated / N/A |
| Разметка | `serp-markup-builder` | gaps | |
| On-page | `on-page-seo-checker` | | |
| Качество контента | `content-quality-auditor` | SHIP/FIX/BLOCK/… | |
| Структура | `site-structure-optimizer` | | |
| Доверие домена | `domain-authority-auditor` | TRUSTED/… | |

Не сводить треки в один «общий балл /100».

## Бэклог (по приоритету)

### P0
- [ ] <проблема> — <где> — <что сделать> — <evidence>

### P1
- [ ] …

### P2
- [ ] …

### Later
- [ ] …

## Пробелы в данных
| Нужно | Зачем | Как получить |
|-------|-------|--------------|
| | | |

## После деплоя / только на проде
- [ ] …

## Что делать дальше
1. …
2. …
3. Повторный прогон: `seo-audit --mode quick <url>` после P0
```

## Tone

- Business-clear: no unexplained jargon
- Specific URLs and actions
- Separate **Observed** vs **Estimated**
- Short executive summary; detail only where it changes decisions
