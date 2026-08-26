Для проверки оставшихся кредитов на API-ключе нужно сделать GET-запрос на https://openrouter.ai/api/v1/key.
Ответ содержит следующие поля: label, limit, limit_reset, limit_remaining, include_byok_in_limit, usage, usage_daily, usage_weekly, usage_monthly.
Кроме того, документированный эндпоинт GET /api/v1/credits возвращает total_credits и total_usage для аккаунтов с управляющим ключом.
Источники: openrouter.ai/docs/api_reference/limits, apis.io/apis/openrouter/openrouter-credits-api/
