# AGENTS.md — эталон

Корень репо. **Для ИИ-агентов в этом репозитории** (сборка, тесты, границы). Не README и не копия `standards/`.

Pin, отклонения и обязательные пути релиза — **только здесь**.

Если в начале файла уже есть автоблок вроде `<!-- BEGIN:nextjs-agent-rules -->` — **оставить сверху**. Разделы ниже — после него. `next dev` снова допишет блок, если его срезать.

Если `/llms.txt` отдаёт роут, а не файл в `public/` — одна строка в **Layout**, чтобы агент не завёл второй файл.

Пустой раздел запрещён: либо факт репо, либо «не применимо: …».

## Обязательные разделы

| Раздел | Что должно быть |
|--------|-----------------|
| **Product** | Одно-два предложения: что делает репо (можно короче, чем README) |
| **Layout** | Где код (приложение, `app/`, `supabase/`…) — чтобы агент не искал вслепую. Если карта для ИИ генерируется — откуда (роут / модуль), не «просто public/» |
| **How to work here** | Реальные команды: install, dev, test, build, typecheck — как в `package.json` |
| **Conventions** | 3–8 правил этого репо: имена, куда класть фичи, что уже запрещено архитектурой |
| **Monster Automation** | Hub, policy, **Pin**, версия стандартов, last revise, Local deviations |
| **Обязательные пути релиза** | Таблица 5–10 путей, заголовок **ровно** этот. Эталон: `templates/release-must-work-paths.md` |
| **Do not** | Секреты, не копировать `standards/`, пароли не в этот файл, плюс запреты продукта |

```md
# AGENTS.md

## Product
<что делает этот репо>

## Layout
- Приложение: …
- Данные / auth: …
- Публичные ассеты: `public/` (если есть)
- Карта для ИИ: `public/llms.txt` *(или: роут `src/app/llms.txt/route.ts`, не класть public/llms.txt)*

## How to work here
- Install: `pnpm install`
- Dev: `pnpm dev`
- Test: `pnpm test`
- Typecheck: `pnpm typecheck`   *(или как в репо)*
- Build: `pnpm build`

## Conventions
- …
- Не трогать без явной просьбы: …

## Monster Automation
- Hub: https://github.com/MagnumMax/ma-hub
- Local hub path: ~/ma-hub (после bootstrap)
- Policy: track main
- Pin: (пусто = всегда latest; иначе например v1.0.0)
- Applied standards version: X.Y.Z
- Last revise: YYYY-MM-DD
- Local deviations:
  - …

## Обязательные пути релиза

| Путь | Когда | Область | Роль |
|------|--------|---------|------|
| … | always | auth | manager |
| … | always | home | manager |
| … | if-touched | … | … |

## Do not
- Не копировать `ma-hub/standards/` в этот репо
- Секреты только в env, не в git
- Пароли не писать в этот файл
```
