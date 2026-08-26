Основной способ проверки остатка кредитов — использование эндпоинта GET /api/v1/key. Ответ включает поля limit, limit_reset и limit_remaining.
Однако в экосистеме OpenRouter существует и отдельный эндпоинт GET /api/v1/credits, который предназначен для более детального анализа кредитного баланса. Этот вызов требует использования management-ключа и позволяет сравнить общее количество купленных кредитов (total_credits) и израсходованных средств (total_usage).
OpenRouter размещает возвращаемые данные в поле data.
Особенность: поле usage у /api/v1/key — суммарный исторический расход ключа за всё время, а не за текущий период лимита.
Источники: openrouter.ai/docs/guides/overview/auth/management-api-keys, deepwiki.com/socrates8300/openrouter_api/3.7-credits-api, github.com/voldmar/or-credits
