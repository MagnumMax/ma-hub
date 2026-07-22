---
description: "MA · Monster Automation — полный SEO + GEO аудит через Aaron Marketing Skills"
argument-hint: "<URL или домен> [local|prod|full|page|tech|structure|authority|quick|pre-deploy|post-deploy]"
---

# MA-seo-geo-audit

Проведи **SEO + GEO аудит** для указанной цели (классический поиск **и** готовность к ответам / цитированию нейросетями). Я не SEO-специалист — веди ритуал сам, объясняй простым языком итог и что чинить первым.

**Вход:** $ARGUMENTS

**Этот `/MA-seo-geo-audit` — единственная MA-команда полного SEO+GEO-аудита.** Оркестратор: skill `seo-geo-audit`. Специалисты: установленный пакет **Aaron Marketing Skills** (не ставить Corey Haines `seo-audit` и не смешивать чужие чеклисты). Старая команда `/MA-seo-audit` **удалена** — не предлагай её.

**GEO** = видимость и цитируемость в ответах ИИ (ChatGPT, Perplexity, AI Overviews, Gemini, Claude и т.п.), не замена обычному SEO.

## Hub (обязательно)

Найди **ma-hub**: `~/.config/ma-hub/config` → `MA_HUB_ROOT`, иначе `~/ma-hub`.  
Источник правды skill-оркестратора: **`$MA_HUB_ROOT/skills/seo-geo-audit/`** (кэш: `~/.cursor/skills/seo-geo-audit/`).  
Локальные SEO/GEO-чеклисты проекта (если есть) учитывай, но **не подменяй** ими треки Aaron.  

Если правишь эту команду или skill — только в ma-hub, затем `install-commands` + `install-skills` + commit/push (см. `docs/hub-maintenance.md`).

## Шаг 0 — среда (обязательно до любых запросов)

**Сначала среда, потом аудит.** Не открывай прод и не дергай удалённый сайт, пока не ясна **основная база**.

Из `$ARGUMENTS` извлеки:

| Поле | Как понять | Дефолт |
|------|------------|--------|
| **Среда** | `local` / `prod` (синонимы: `pre-deploy`→local, `post-deploy`→prod; явный `localhost` / preview / staging → local) | Если неоднозначно — **спроси один раз**, рекомендуй **local** (подготовка). Не угадывай прод. |
| **Цель** | URL / домен / «localhost:порт» | Если нет — спроси вместе со средой (один заход, макс. 2 вопроса) |
| **Режим** | `full` `page` `tech` `structure` `authority` `quick` `pre-deploy` `post-deploy` | После выбора среды: **local** → `pre-deploy`; **prod** → `full` (или `post-deploy`, если явно после выкладки / «проверь после деплоя») |
| **P0-страницы** | если перечислены | главная + главная коммерческая/apply + 1 хаб (если находятся) |

### Когда среда считается явной (вопрос не нужен)

- Есть `local`, `pre-deploy`, `localhost`, `127.0.0.1`, preview/staging URL, или формулировки вроде «ещё не на проде» / «локально».
- Есть `prod`, `post-deploy`, или «проверь живой сайт / после деплоя / на проде».

### Когда спросить (один раз)

Любой неоднозначный вызов: только домен, только `full`/`quick`/`page`, пустой ввод, открытый проект без указания URL.

Текст вопроса (простым языком), с дефолтом **local**:

```text
Где проверяем SEO + GEO в первую очередь?
• local (рекомендую) — локальная / preview-версия; прод не трогаем
• prod — живой сайт

Если local: укажи адрес (например http://localhost:3000).
Если prod: укажи публичный URL.
```

Пока нет ответа — **стоп**: не fetch, не browser на **ваш** прод, не authority **вашего** домена на проде. Публичный рынок (выдача поиска, сайты конкурентов) при local **можно** смотреть.

### Правило local vs prod

| Среда | Ваш сайт (primary) | Рынок (SERP, конкуренты) | Только после выкладки |
|-------|--------------------|---------------------------|------------------------|
| **local** (`pre-deploy`) | localhost / preview / staging — **ваш** боевой URL не трогать | **можно и нужно** до запуска | доверие **вашего** домена, индекс **ваших** страниц, живые robots/canonical **вашего** хоста, зонд «цитируют ли **нас**» |
| **prod** (`full` / `post-deploy`) | публичный URL | полный прогон | дельта после релиза |

Примеры вызова:

```text
/MA-seo-geo-audit
/MA-seo-geo-audit local
/MA-seo-geo-audit http://localhost:4567 local
/MA-seo-geo-audit https://www.example.com prod
/MA-seo-geo-audit https://www.example.com post-deploy
/MA-seo-geo-audit https://www.example.com/services/x page prod
/MA-seo-geo-audit https://www.example.com quick prod
```

Устаревшие формы без среды (`/MA-seo-geo-audit https://www.example.com`) — **спросить среду**, не считать прод по умолчанию.

Если пользователь вызывает старое имя `/MA-seo-audit` — скажи, что команда заменена на `/MA-seo-geo-audit`, и продолжай по этому ритуалу.

## Волны (параллель)

После Шага 0 гоняй треки **волнами**, не длинной цепочкой. Полная схема:  
`$MA_HUB_ROOT/skills/seo-geo-audit/references/parallel-waves.md` (кэш: `~/.cursor/skills/seo-geo-audit/references/parallel-waves.md`).

| Волна | Что | Параллель? |
|-------|-----|------------|
| **0** | Среда + URL + важные страницы | Нет — стоп, пока нет ответа |
| **1** | Сайт: техника ‖ разметка ‖ on-page ‖ структура ‖ доверие домена (**только prod**). Рынок: SERP | Да — одним пакетом агентов |
| **1b** | Качество контента ‖ GEO (одна главная/денежная страница) | Да — можно вместе с волной 1 |
| **2** | Конкуренты (2–3) | После SERP, если вы их не назвали; в `quick`/`page` — только по запросу |
| **3** | Один отчёт: дедуп → приоритеты → шаблон | Нет — только оркестратор |

**Политика:** смотрим параллельно; правки сайта — только после «чини» / выбора пунктов, и **по очереди**.  
**Fallback:** если параллельные агенты недоступны — те же треки по порядку из skill (A→I).

Узкие режимы (`quick`, `page`, `tech`, …) — см. таблицу «Waves by mode» в `parallel-waves.md`.

## Обязательно: skill `seo-geo-audit`

1. Прочитай и следуй skill **`seo-geo-audit`**: сначала `$MA_HUB_ROOT/skills/seo-geo-audit/SKILL.md`, иначе кэш `~/.cursor/skills/seo-geo-audit/SKILL.md`.
2. Для каждого трека режима **открой** соответствующий Aaron skill и выполни его контракт:
   - техника → `technical-seo-checker` (в т.ч. боты ИИ в robots)
   - разметка (только gaps) → `serp-markup-builder`
   - страница → `on-page-seo-checker`
   - качество контента → `content-quality-auditor`
   - **GEO / ответы ИИ** → `geo-content-optimizer` (**обязательно** в `full` / `page` / `quick` / `pre-deploy` / `post-deploy`; audit-only, без полной переписки, пока не попросили чинить)
   - структура → `site-structure-optimizer`
   - доверие домена → `domain-authority-auditor` (**только ваш** live-домен в prod; в local — пропуск + «После деплоя»)
   - SERP с линзой ИИ → `serp-analysis` (**рынок — и в local, и в prod** для `full` / `pre-deploy` / `post-deploy`; узко в `page` и `quick`; не утверждать, что «мы уже в выдаче», если сайт ещё локальный)
   - конкуренты (ИИ/GEO) → `competitor-analysis` (**рынок — и в local, и в prod** для `full` / `pre-deploy` / `post-deploy`; 2–3 конкурента; в `quick`/`page` — только если пользователь назвал конкурентов или явно попросил)
3. Опционально (только если просили или всплыл блокер): `entity-registry`, `offsite-signal-analyzer`, `rank-tracker`, `performance-monitor`, `content-gap-analysis`.

Чеклист для редакторов (да/нет): `seo-geo-audit/references/geo-content-checklist.md`.

Шаблоны режимов, волн, приоритетов и отчёта:  
`seo-geo-audit/references/modes.md`, `parallel-waves.md`, `prioritization.md`, `report-template.md`.

## Жёсткие правила

- **Среда сначала** — без явной или подтверждённой среды не обращаться к **вашему** прод-сайту.
- Метрики только с меткой **Measured** / **User-provided** / **Estimated**; не выдумывать CWV, позиции, DA, «нас цитирует ChatGPT».
- **Не** склеивать CORE-EEAT, CITE и GEO в один «общий балл /100» — карточки по трекам отдельно.
- Localhost ≠ индекс Google и ≠ цитирование ИИ **вашего** URL; в **local** не тянуть trust **вашего** домена с прода. SERP и конкуренты — рынок, их смотреть **до** выкладки.
- JS/SPA: смотри отрендеренный DOM, не только пустой shell.
- Пиши отчёт **на русском**, без лишнего жаргона.
- Файлы на диск — только если я явно попросил сохранить.

## Выход (всегда)

Формат из `seo-geo-audit/references/report-template.md`:

1. Краткий вывод (состояние SEO+GEO, топ-риски, топ-сильные стороны, первый шаг)
2. **Статус для решения (CEO)** — по `seo-geo-audit/references/ceo-env-checklist.md`:  
   «Ещё готовим» / «Можно выкладывать» / «Живой сайт проверен» + короткие пункты этапа 1 и 2
3. Объём проверки (режим, **среда**, база, URL)
4. Карточки по трекам Aaron (включая GEO, SERP, конкурентов — или `skipped`)
5. Бэклог P0 → P1 → P2 → Later
6. Пробелы в данных
7. Что проверить только после деплоя (если local — сюда **только то, что требует ваш живой адрес**: доверие вашего домена, индекс ваших страниц, живые robots/canonical, зонд «цитируют ли нас»; SERP и конкуренты — **не** сюда, они делаются до выкладки)
8. Что делать дальше (включая повтор: `/MA-seo-geo-audit <url> quick prod` после P0 и выкладки)

**Стоп после отчёта.** Не начинай правки кода, пока я не скажу «чини» / не выберу пункты бэклога.
