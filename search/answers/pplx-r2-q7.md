В Stryker для этого используется флаг **`--force`**: он заставляет прогнать мутационное тестирование заново, **игнорируя инкрементальный кэш**. [8]

Если нужен именно эквивалент в конфиге, то для повторного полного прогона обычно запускают Stryker без использования сохранённого результата предыдущего запуска; в документации по конфигурации явно описаны флаги вроде `excludedMutations`, `ignore-mutations` и `disable-mix-mutants`, но не кэш как отдельная настройка в приведённых результатах. [8][5]

## Istochniki

1. [What is mutation testing?](https://stryker-mutator.io/docs/)
2. [Static mutants](https://stryker-mutator.io/docs/mutation-testing-elements/static-mutants/)
3. [Frequently Asked Questions](https://stryker-mutator.io/docs/General/faq/)
4. [Мутанты в файлах Страйкера в фильме "Люди Икс 2"](https://www.reddit.com/r/xmen/comments/1mmu3zp/mutants_in_strykers_files_in_x2/)
5. [Configuration](https://stryker-mutator.io/docs/stryker-net/configuration/)
6. [stryker-js/CHANGELOG.md at master · stryker-mutator/stryker-js](https://github.com/stryker-mutator/stryker-js/blob/master/CHANGELOG.md)
7. [Introduction to Mutation Testing with Stryker](https://medium.com/digio-australia/introduction-to-mutation-testing-with-stryker-1338451ad4e5)
8. [Configuration | Stryker Mutator](https://stryker-mutator.io/docs/stryker-js/configuration/)
9. [Vitest Runner - Stryker Mutator](https://stryker-mutator.io/docs/stryker-js/vitest-runner/)
10. [Тестирование мутаций - .NET](https://learn.microsoft.com/ru-ru/dotnet/core/testing/mutation-testing)
11. [Mutation Testing - A .NET Developer's Guide](https://dev.to/jacksteel97/mutation-testing-a-net-developers-guide-2fhj)
12. [мутационное тестирование unit тестов на проекте в крупном ...](https://tproger.ru/articles/kak-my-avtomatizirovali-mutacionnoe-testirovanie-unit-testov-na-proekte-gazprombanka-s-ispolzovaniem-stryker-net)
13. [William Stryker (Уильям Страйкер) - Биография персонажа](https://www.strangearts.ru/heroes/william-stryker)
14. [Все мутанты в Сталкер 2 — как победить все виды монстров — Escorenews](https://escorenews.com/ru/article/64035-vse-mutanty-v-stalker-2-kak-pobedit-vse-vidy-monstrov)
15. [Все виды мутантов в STALKER 2: Heart of Chernobyl. Как ...](https://steamcommunity.com/sharedfiles/filedetails/?l=swedish&id=3405225648)
16. [Мутанты | S.T.A.L.K.E.R. Wiki - Fandom](https://stalker.fandom.com/ru/wiki/%D0%9C%D1%83%D1%82%D0%B0%D0%BD%D1%82%D1%8B)
17. [Страйкер - Mortal Kombat Wiki - Fandom](https://mortalkombat.fandom.com/ru/wiki/%D0%A1%D1%82%D1%80%D0%B0%D0%B9%D0%BA%D0%B5%D1%80)
18. [Уильям Страйкер (Земля 10005)](https://vcomicse.ru/marvel/personazhi/uilyam-strajker-zemlya-10005/)
19. [Баланс монстров в S.T.A.L.K.E.R. 2: Сердце Чернобыля. ...](https://vk.ru/wall-15844953_839699)
20. [Stryker 2023 Comprehensive Report](https://www.stryker.com/content/dam/stryker/about/annual-review/2023/Stryker-2023-Comprehensive-Report.pdf)

---
sonar-pro | 3 s | $0.0085