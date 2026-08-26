Флаг --force в StrykerJS заставляет перезапустить всех мутантов, полностью игнорируя результаты, сохраненные в инкрементальном файле. С его помощью вы указываете StrykerJS выполнить повторный прогон всех мутантов в области действия, независимо от предыдущего результата.
Результаты инкрементального режима сохраняются в файле reports/stryker-incremental.json.
Использование --force особенно выгодно в сочетании с пользовательским шаблоном --mutate.
Источники: stryker-mutator.io/blog/announcing-incremental-mode/, stryker-mutator.io/docs/stryker-js/incremental/, github.com/stryker-mutator/stryker-js/issues/6119, github.com/stryker-mutator/stryker-js/blob/master/docs/incremental.md
