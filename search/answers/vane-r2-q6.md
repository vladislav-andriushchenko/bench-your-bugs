Для получения информации о кредитах используется HTTP-эндпоинт GET /api/v1/credits. Запрос требует аутентификации, может потребоваться управляющий ключ (management key).
Структура ответа:
- total_credits — общая сумма купленных кредитов;
- total_usage — общая сумма потребленных кредитов;
- rate_limit — информация об ограничении скорости запросов, если используется.
Остаток баланса вычисляется формулой total_credits - total_usage. Структура ответа содержит поле data.
Альтернативно GET /api/v1/key возвращает limit, limit_reset и limit_remaining.
Источники: deepwiki.com/socrates8300/openrouter_api/3.7-credits-api, openrouter.ai/docs/api_reference/limits, github.com/voldmar/or-credits, aicostplanner.com
