# SEO + GEO Audit report template

Write the user-facing report in the user's language (default: Russian). Keep skill names in backticks when useful.

```markdown
# SEO + GEO Audit — <domain or URL>
**Дата:** YYYY-MM-DD
**Среда:** local | prod
**Режим:** full | page | tech | pre-deploy | post-deploy | …
**База:** <primary base> · **Прод-домен:** <if known and different; not fetched when local>

## Краткий вывод
- Состояние: <1 фраза — и поиск, и ответы ИИ>
- Главные риски: <до 3>
- Что уже хорошо: <до 3>
- Первый шаг: <одна конкретная правка>

## Статус для решения (CEO)
Шаблон: [ceo-env-checklist.md](ceo-env-checklist.md). Заполнить по факту аудита.

**Итоговый статус:** Ещё готовим (local) | Можно выкладывать | Живой сайт проверен

```text
Этап 1 (local):  [ ] не готов   [ ] можно выкладывать
Этап 2 (prod):   [ ] не начинали   [ ] в работе   [ ] проверен
```

### Этап 1 — до выкладки (кратко)
- [ ] … (только обязательные пункты из чеклиста, ✅/❌)

### Этап 2 — после выкладки (кратко)
- [ ] … (на local — все «после выкладки»; на prod — по факту)

## Объём проверки
| Что | Значение |
|-----|----------|
| Среда | local / prod |
| Режим | |
| URL (P0) | |
| Пропущенные треки | e.g. authority / SERP / competitor (local) |
| Ограничения среды | localhost / прод не трогали / нет GSC / … |

## Карточки по трекам
| Трек | Навык Aaron | Итог | Доказательства |
|------|-------------|------|----------------|
| Техника | `technical-seo-checker` | score / статус | Measured / Estimated / N/A |
| Разметка | `serp-markup-builder` | gaps | |
| On-page | `on-page-seo-checker` | | |
| Качество контента | `content-quality-auditor` | SHIP/FIX/BLOCK/… | |
| GEO / ответы ИИ | `geo-content-optimizer` | GEO score / gaps | |
| Структура | `site-structure-optimizer` | | |
| Доверие домена | `domain-authority-auditor` | TRUSTED/… или skipped (нужен ваш live) | |
| SERP (ИИ-линза) | `serp-analysis` | рынок (до и после выкладки) | |
| Конкуренты (ИИ/GEO) | `competitor-analysis` | рынок (до и после выкладки) | |

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

## После деплоя / только то, что требует **ваш** живой адрес
(обязательно заполнить при **local**; на **prod** — только то, что ещё не измеряли)
- [ ] Доверие **вашего** домена (`domain-authority-auditor`)
- [ ] Индексация **ваших** страниц / Search Console
- [ ] Живые robots.txt (в т.ч. боты ИИ), sitemap, canonical **на вашем хосте**
- [ ] Field CWV **на вашем хосте** (если нужно)
- [ ] Живой зонд: цитируют ли **ваш** URL (если есть инструменты)
- [ ] …

SERP и конкуренты — **не** откладывать на после деплоя: они в основном прогоне (рынок) и дают правки контента **до** запуска.

Чеклист для редакторов: [geo-content-checklist.md](geo-content-checklist.md).

## Что делать дальше
1. …
2. …
3. После P0 на local: выкладка, затем `/MA-seo-geo-audit <prod-url> quick prod` (или `post-deploy`)
```

## Tone

- Business-clear: no unexplained jargon
- Specific URLs and actions
- Separate **Observed** vs **Estimated**
- State environment up front so readers know whether prod was touched
- Mention both classic search and AI-answer readiness in the summary
- Short executive summary; detail only where it changes decisions
