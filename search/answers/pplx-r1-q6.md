OpenRouter для остатка кредитов по **аккаунту** использует эндпоинт **`GET /api/v1/credits`**; он требует **Management key**.[1][2]

Ответ приходит в JSON и содержит как минимум поле **`data`**, внутри которого есть:

- **`total_credits`** — всего куплено кредитов.[1]
- **`total_usage`** — всего израсходовано кредитов.[1]

В документации показан пример ответа вида:

```json
{
  "data": {
    "total_credits": 100.5,
    "total_usage": 25.75
  }
}
```

Если нужен именно *остаток*, его обычно считают как **`total_credits - total_usage`**.[4][13]

Если хотите, я могу также показать разницу между **`/api/v1/credits`** и **`/api/v1/key`** — второй эндпоинт возвращает остаток уже *по конкретному API-ключу*, а не по всему аккаунту.[6][9]

## Istochniki

1. [Get remaining credits - OpenRouter | Documentation](https://openrouter.ai/docs/api/api-reference/credits/get-remaining-credits)
2. [Credits - TypeScript SDK](https://openrouter.ai/docs/agent-sdk/typescript/api-reference/credits)
3. [OpenRouter API Quickstart Guide | PDF | Credit Card | Privacy - Scribd](https://www.scribd.com/document/869227384/Openrouter-ai-Docs-Llms-full-txt)
4. [OpenRouter 余额查询:API Key 剩余额度、Credits 与Usage 对账](https://aiapiprice.com/openrouter-yue/)
5. [OpenRouter Credits: Expiry & 402/403 Errors - AICostPlanner](https://aicostplanner.com/openrouter-credits/)
6. [API Credit & Rate Limits - Handle 402 and 429 Errors](https://openrouter.ai/docs/api_reference/limits)
7. [API Endpoints Reference - OpenRouter](https://openrouter.gr.com/endpoints-reference.html)
8. [OpenRouter Credits API — Documentation, OpenAPI](https://apis.io/apis/openrouter/openrouter-credits-api/)
9. [OpenRouter:API Usage Query - chunhualiao/public-docs GitHub Wiki](https://github-wiki-see.page/m/chunhualiao/public-docs/wiki/OpenRouter:API-Usage-Query)
10. [Get Credits | TheRouter.ai](https://therouter.ai/docs/api/api-reference/credits/get-credits/)
11. [Get Credits | Robomotion RPA Documentation](https://docs.robomotion.io/reference/packages/openrouter/get-credits/)
12. [How do I query my remaining credits using the API? · Issue #7 · OpenRouterTeam/openrouter-examples](https://github.com/OpenRouterTeam/openrouter-examples/issues/7)
13. [CodexBar/docs/openrouter.md at main](https://github.com/steipete/CodexBar/blob/main/docs/openrouter.md)
14. [Credits and Billing | OpenRouterTeam/python-sdk | DeepWiki](https://deepwiki.com/OpenRouterTeam/python-sdk/5.8-credits-and-billing)
15. [How to check credit usage per api call?](https://www.reddit.com/r/openrouter/comments/1o9009p/how_to_check_credit_usage_per_api_call/)
16. [Step 3: Check balance. GET /api/v1/credits to see current ...](https://x.com/OpenRouter/status/1870227181260923360)
17. [openrouter-common-errors - Skill](https://smithery.ai/skills/jeremylongshore/openrouter-common-errors)
18. [openrouter-cost-controls — Agent Skill — MCP.Directory](https://mcp.directory/skills/openrouter-cost-controls)

---
sonar-pro | 6 s | $0.00988