# Клиентское уведомление после прода (`/MA-deploy`)

**Цель:** после успешного выката на прод клиент получает в Telegram понятный список изменений — без ручной переписки и без забывчивости.

**Только из `/MA-deploy`** (Phase 7.5). Не GitHub Action, не PR-событие.

## Когда

1. Phase 7 прошла: production READY + smoke OK (или явный smoke-fallback). Прод **не** откатывать из‑за Telegram.
2. **Сначала спросить:** «Уведомить клиента в Telegram об этом релизе? **да** / **нет (только техника)**».  
   Чисто технический выкат (CI, зависимости, внутренний рефакторинг без пользы для клиента) → **нет** → пропуск, без ключей и без черновика. Тихий skip без вопроса **запрещён** (в т.ч. в `auto`).
3. Если **да** → проверка ключей (`MA_TELEGRAM_BOT_TOKEN`, `COMPANY_TELEGRAM_CHAT_ID`, при форуме — `COMPANY_TELEGRAM_THREAD_ID_UPDATES`).
4. **Ключей нет → пауза:** сказать, что добавить и куда; ждать **«готово»** / **«пропустить уведомление»** / значения от пользователя. После «готово» — **перепроверить** env; пока пусто — не идти к черновику.
5. Ключи ок → агент готовит **черновик** сообщения (формат ниже).
6. **Пауза — согласование текста:** «отправить» / правки / «не слать».
7. Только после «отправить» — скрипт ниже.

Даже в режиме **`auto`**: вопрос «слать / только техника» и согласование текста — всегда; нет ключей при «да» = ждать добавления.

## Переменные: что где лежит

| Переменная | Где | Одинаково везде? | Смысл |
|------------|-----|------------------|--------|
| `MA_TELEGRAM_BOT_TOKEN` | **`~/.config/ma-hub/telegram.env`** (машина, не в git) | **Да** — один бот MA на все продукты | Токен бота Monster Automation |
| `COMPANY_TELEGRAM_CHAT_ID` | **`.env.local` каждого продукта** | Нет — свой чат клиента | Чат / супергруппа клиента |
| `COMPANY_TELEGRAM_THREAD_ID_UPDATES` | **`.env.local` каждого продукта** | Нет — свой топик | Топик форума **Updates** (не ops-алерты) |

В `.env.example` продукта — только ключи `COMPANY_*` **без** секретов (+ комментарий, что бот живёт в `~/.config/ma-hub/telegram.env`).

**Не** подставлять продуктовый ops-бот (`TELEGRAM_BOT_TOKEN` приложения) для клиентских апдейтов — это другой канал.

**Никогда** не класть токены в ma-hub git, в commits, в отчёт чата целиком.

### Файл машины (создать один раз)

`~/.config/ma-hub/telegram.env`:

```bash
MA_TELEGRAM_BOT_TOKEN=…
```

### Файл продукта (в каждом клиентском репо)

`.env.local`:

```bash
COMPANY_TELEGRAM_CHAT_ID=-100…
COMPANY_TELEGRAM_THREAD_ID_UPDATES=…
```

`.env.example` — те же ключи пустыми + комментарий.

## Формат сообщения (черновик)

**Язык по умолчанию: English** (если в Local deviations продукта не указано иное).

Эталон:

```text
#{N} Update, {D Month YYYY}

{Zone} → {Sub-area}: {what changed}.
{Zone} → {Sub-area}: {what changed}.
```

Правила:
- Заголовок одной строкой: **`#{номер} Update, {дата}`** — номер выката (= номер merged PR `dev→main`, **без** слова PR); дата словами на английском. Пример: `#54 Update, 29 July 2026`. Имя продукта в заголовке не обязательно, если чат/топик уже привязан к одному продукту; иначе можно префикс продукта в Local deviations.
- Каждый пункт — **одна строка**: `{Zone} → {Sub-area}: {fact}`. Без нумерации `1. 2. 3.`
- **Zone** = поверхность продукта (`QR menu`, `Admin`, `Pulse`, …). **Sub-area** = конкретный блок (`Recommendations list`, `My selection`, `Product card`, …).
- Формулировка короткая: «added a check…», «items stay saved…», «shows a warning…», «spacing tightened» — не длинный рассказ.
- До **10** строк. Без file paths, API, commit SHA, слов вроде PR/CI в тексте для клиента.
- Не включать внутренние рефакторинги, CI, зависимости — только то, что клиент заметит или о чём полезно знать.
- В конце черновика для пользователя (в чат Cursor): «Send to client? **send** / edits: … / **don't send**» (можно по-русски: **отправить** / правки / **не слать**).

Пример (хороший):

```text
#54 Update, 29 July 2026

QR menu → Recommendations list: added a check that a guest category exists.
QR menu → My selection: selected items stay saved even if the guest leaves the menu and comes back.
Admin → Product card: shows a warning when a recommendation exists but the guest category is missing.
Pulse → Dashboard: spacing tightened.
```

Антипример: нумерация, «What changed:», только зона без подзоны, длинные объяснения, слово **PR** в заголовке, русский по умолчанию без Local deviation.

## Откуда брать содержание

1. Коммиты / описание merged PR `dev→main` с прошлого уведомления или с предыдущего merge на `main`…`HEAD`.
2. Переписать агентом в клиентский язык (Zone → Sub-area, не файлы); текст апдейта — **English** по умолчанию.
3. Если нечего сказать клиенту (только внутренняя чистка) → предложить «нет (только техника)» или «don't send».

## Отправка

Из корня продукта (после «ок» на текст):

```bash
# токен подтянется из ~/.config/ma-hub/telegram.env
# COMPANY_* — из .env.local проекта

"$MA_HUB_ROOT/bootstrap/telegram-customer-update-send.sh" <<'EOF'
Обновление: …
EOF
```

Или файл:

```bash
"$MA_HUB_ROOT/bootstrap/telegram-customer-update-send.sh" --file /tmp/ma-customer-update.txt
```

Скрипт печатает `ok` / ошибку API **без** токена в логе.

## Подключение на продукт

1. Создать/выбрать Telegram-чат и топик **Updates** для этого клиента (не смешивать с ops-алертами).
2. Добавить **MA-бота** в чат; для форума — право писать в топик.
3. В `.env.local`: `COMPANY_TELEGRAM_CHAT_ID`, `COMPANY_TELEGRAM_THREAD_ID_UPDATES`.
4. В `.env.example` — те же ключи без значений.
5. На машине один раз: `~/.config/ma-hub/telegram.env` с `MA_TELEGRAM_BOT_TOKEN`.
6. Local deviations в `docs/MA-STANDARDS.md` при особом языке/чате — по желанию.

## Связь с `/MA-deploy`

См. Phase **7.5** в `commands/MA-deploy.md`.
