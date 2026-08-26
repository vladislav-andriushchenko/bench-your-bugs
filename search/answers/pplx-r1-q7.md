В Stryker для повторного прогонки **всех мутантов** с игнорированием инкрементального кэша обычно используют флаг **`--force`** (он принудительно запускает тестирование заново, не полагаясь на предыдущий кэш).  

Если речь о **StrykerJS**, это именно тот флаг, который чаще всего нужен для полного повторного прогона; для точной команды иногда также очищают temp/cache каталог, если нужно полностью сбросить локальное состояние.

## Istochniki

1. [What is mutation testing?](https://stryker-mutator.io/docs/)
2. [Frequently Asked Questions](https://stryker-mutator.io/docs/General/faq/)
3. [Static mutants](https://stryker-mutator.io/docs/mutation-testing-elements/static-mutants/)
4. [Configuration](https://stryker-mutator.io/docs/stryker-net/configuration/)
5. [stryker-js/CHANGELOG.md at master · stryker-mutator/stryker-js](https://github.com/stryker-mutator/stryker-js/blob/master/CHANGELOG.md)
6. [Configuration | Stryker Mutator](https://stryker-mutator.io/docs/stryker-js/configuration/)
7. [Тестирование мутаций - .NET](https://learn.microsoft.com/ru-ru/dotnet/core/testing/mutation-testing)
8. [Introduction to Mutation Testing with Stryker](https://medium.com/digio-australia/introduction-to-mutation-testing-with-stryker-1338451ad4e5)
9. [Vitest Runner - Stryker Mutator](https://stryker-mutator.io/docs/stryker-js/vitest-runner/)
10. [Mutation Testing - A .NET Developer's Guide](https://dev.to/jacksteel97/mutation-testing-a-net-developers-guide-2fhj)
11. [мутационное тестирование unit тестов на проекте в крупном ...](https://tproger.ru/articles/kak-my-avtomatizirovali-mutacionnoe-testirovanie-unit-testov-na-proekte-gazprombanka-s-ispolzovaniem-stryker-net)
12. [Все мутанты в Сталкер 2 — как победить все виды монстров — Escorenews](https://escorenews.com/ru/article/64035-vse-mutanty-v-stalker-2-kak-pobedit-vse-vidy-monstrov)
13. [Мутанты | S.T.A.L.K.E.R. Wiki - Fandom](https://stalker.fandom.com/ru/wiki/%D0%9C%D1%83%D1%82%D0%B0%D0%BD%D1%82%D1%8B)
14. [William Stryker (Уильям Страйкер)](https://www.strangearts.ru/heroes/william-stryker)
15. [Stryker 2023 Comprehensive Report](https://www.stryker.com/content/dam/stryker/about/annual-review/2023/Stryker-2023-Comprehensive-Report.pdf)
16. [Stryker 2024 Comprehensive Report](https://www.stryker.com/content/dam/stryker/about/annual-review/2024/Stryker-2024-Comprehensive-Report.pdf)
17. [2022](https://www.stryker.com/content/dam/stryker/about/annual-review/2022/stryker-2022-comprehensive-report.pdf)

---
sonar-pro | 4 s | $0.00803