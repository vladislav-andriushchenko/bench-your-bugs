Для проверки лимита скорости или оставшихся кредитов на API-ключе необходимо сделать GET-запрос на https://openrouter.ai/api/v1/key.
Что касается полей ответа, ответ содержит такие поля как: label, limit (лимит кредитов для ключа), limit_reset, limit_remaining, include_byok_in_limit, usage, usage_daily, usage_weekly и usage_monthly.
Кроме того, документированный GET /api/v1/credits эндпоинт возвращает total_credits и total_usage для аккаунтов с ключом управления.
Источники: openrouter.ai/docs/api_reference/limits, apis.io/apis/openrouter/openrouter-credits-api/, docs.robomotion.io/reference/packages/openrouter/get-credits/
