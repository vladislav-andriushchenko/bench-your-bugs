OpenRouter для остатка по **аккаунту** использует `GET https://openrouter.ai/api/v1/credits`, но в официальной документации этот эндпоинт возвращает не “remaining”, а **`total_credits`** и **`total_usage`** для аутентифицированного пользователя; остаток нужно вычислять как `total_credits - total_usage`.[1]

В ответе `200 OK` указана JSON-структура с полем **`data`**, внутри которого есть:

- **`total_credits`** — всего купленных кредитов[1]
- **`total_usage`** — всего использованных кредитов[1]

Если же вы имели в виду остаток по **конкретному API-ключу**, то это другой эндпоинт: `GET https://openrouter.ai/api/v1/key`, и там поле **`limit_remaining`** прямо показывает оставшийся лимит для ключа.[7]

## Istochniki

1. [Get remaining credits - OpenRouter | Documentation](https://openrouter.ai/docs/api/api-reference/credits/get-remaining-credits)
2. [Как начать работать с OpenRouter: ключ, первый запрос и ...](https://bigdataschool.ru/blog/news/openrouter-start-key-first-request-payment/)
3. [OpenRouter API Quickstart Guide | PDF | Credit Card | Privacy - Scribd](https://www.scribd.com/document/869227384/Openrouter-ai-Docs-Llms-full-txt)
4. [Как проверить использование кредитов на один API- ...](https://www.reddit.com/r/openrouter/comments/1o9009p/how_to_check_credit_usage_per_api_call/)
5. [OpenRouter 余额查询:API Key 剩余额度、Credits 与Usage 对账](https://aiapiprice.com/openrouter-yue/)
6. [OpenRouter Credits: Expiry & 402/403 Errors - AICostPlanner](https://aicostplanner.com/openrouter-credits/)
7. [API Credit & Rate Limits - Handle 402 and 429 Errors](https://openrouter.ai/docs/api_reference/limits)
8. [Get Credits | Robomotion RPA Documentation](https://docs.robomotion.io/reference/packages/openrouter/get-credits/)
9. [API Endpoints Reference - OpenRouter](https://openrouter.gr.com/endpoints-reference.html)
10. [OpenRouter Credits API — Documentation, OpenAPI](https://apis.io/apis/openrouter/openrouter-credits-api/)
11. [OpenRouter:API Usage Query - chunhualiao/public-docs GitHub Wiki](https://github-wiki-see.page/m/chunhualiao/public-docs/wiki/OpenRouter:API-Usage-Query)
12. [Module apiCopy item path](https://docs.rs/openrouter-rs/latest/openrouter_rs/api/index.html)
13. [How do I query my remaining credits using the API? · Issue #7 · OpenRouterTeam/openrouter-examples](https://github.com/OpenRouterTeam/openrouter-examples/issues/7)
14. [OpenRouter перестал принимать платежи для учеток с ...](https://habr.com/ru/news/1034012/)
15. [CodexBar/docs/openrouter.md at main](https://github.com/steipete/CodexBar/blob/main/docs/openrouter.md)
16. [OpenRouter::API - Raku Land](https://raku.land/zef:apogee/OpenRouter::API)
17. [OpenRouter · GitHub](https://gist.github.com/rbiswasfc/f38ea50e1fa12058645e6077101d55bb)
18. [openrouter-usage-analytics - Agent Skill](https://tonsofskills.com/skills/openrouter-usage-analytics/)
19. [openrouter-cost-controls — Agent Skill — MCP.Directory](https://mcp.directory/skills/openrouter-cost-controls)
20. [openrouter-common-errors - Skill](https://smithery.ai/skills/jeremylongshore/openrouter-common-errors)

---
sonar-pro | 5 s | $0.00935