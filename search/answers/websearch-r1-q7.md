The `--force` flag is used to tell StrykerJS to rerun all mutants in scope, regardless of the incremental file. This flag overrides the incremental cache, forcing Stryker Mutator to re-test all mutants instead of reusing cached results from previous runs.
Using `--force` is especially beneficial when combined with a custom `--mutate` pattern.
So to answer your question: `--force` is the flag that causes Stryker to re-run all mutants while ignoring the incremental cache.
Источники: stryker-mutator.io/docs/stryker-js/incremental/, stryker-mutator.io/blog/announcing-incremental-mode/
