# Your own bug benchmark

[![selftests](https://github.com/vladislav-andriushchenko/llm-eval-benches/actions/workflows/selftests.yml/badge.svg)](https://github.com/vladislav-andriushchenko/llm-eval-benches/actions/workflows/selftests.yml)

**Build a private benchmark out of the bugs you have already fixed, and find out whether AI
review actually catches them.** It runs on your machine, on your code, against your own
answer key. A Claude Code subscription and `bash` are all it needs — no API key, no second
provider, no orchestration.

```bash
./bench.sh from-commit a1b2c3d --repo ~/my-project   # a bug you fixed becomes a test case
./bench.sh run                                        # three passes, one table
```

The first command checks out the file as it was *before* your fix, keeps the fix itself
where the model cannot see it, and turns the diff into the expected answer. Twenty seconds
per bug. Fix ten bugs over a month and you own a benchmark nobody else has.

## Why a private benchmark beats a public score

Public leaderboards answer a question you do not have. This one answers three you do.

**Your bugs are not in anyone's training data.** Public benchmarks leak into training sets
and stop measuring anything. Yesterday's commit in your repository cannot.

**Your bug classes are not the average bug class.** If your pain is idempotency, or timezone
arithmetic, or one API contract that everyone gets wrong, no general benchmark will tell you
whether a model catches *that*.

**It answers "better or worse than last week".** You edit an instruction file, rewrite a
skill, or a new model version ships. Rerun the same cases. Today that question gets answered
by feel; this turns it into a number.

The two benches in this repository are worked examples of the same method, not the product:
one on planted bugs in code review, one on search tools. The machinery is what transfers.

## See it work in five seconds

The search bench has every raw tool answer committed, so scoring re-runs with nothing
installed beyond `bash` and `grep`:

```bash
git clone https://github.com/vladislav-andriushchenko/llm-eval-benches
cd llm-eval-benches/search
./selftest.sh      # the scorer, checked against fake answers with known verdicts
./score.sh         # rescores the committed answers and reproduces the published table
```

No keys, no network, no model calls. If those two commands pass, the whole method just
demonstrated itself on your machine.

## The one thing that cannot be automated

The answer key. A model that plants a bug and then writes its own expected answer is
measuring itself, and it will hand you a clean green number that means nothing.

So the answer key is not invented, it is harvested. A commit that fixed a bug is ground
truth verified by reality: it knows what was wrong and where. `from-commit` reads it and
builds the case. What stays manual is picking a commit that genuinely fixed a bug, and
glancing at the generated pattern. Seconds, not hours — but not zero, and it cannot be zero.

One bias to keep in mind: only bugs that were **found and fixed** can enter the corpus. The
ones that shipped and were never noticed are exactly the ones you would most want to catch,
and they are not here.

## The method, in three rules

**1. Ground truth is fixed before the run, and never comes from the tools being compared.**
In the search bench every expected answer is recorded in [`search/ORACLE.md`](search/ORACLE.md)
before any tool runs, and each one is verified against a primary source using a tool that
does not take part in the comparison. Score the tools against each other and you measure
agreement, not correctness.

**2. There is no LLM judge.**
Scoring is `grep` over the tool's raw output against patterns committed alongside the
ground truth. A judge model adds its own errors and its own bill, and a marker either
appears in the text or it does not.

**3. The scorer has its own selftest.**
`./selftest.sh` in both benches runs the scorer against hand-written fake answers with
known verdicts. It exists because a scorer that silently under-counts produces a result
that looks completely convincing. That happened here more than once — see below.

Both selftests run in CI on every push, along with a check that scoring the committed
answers still reproduces the committed results byte for byte. If the scorer changes and the
published numbers stop falling out of the published data, the build fails. A benchmark whose
own numbers cannot be regenerated is a claim, not a measurement.

## Building your corpus

**The normal path is `from-commit`.** Every time you fix a bug, spend twenty seconds turning
it into a case:

```bash
./bench.sh from-commit a1b2c3d --repo ~/my-project
./bench.sh list                    # what you have so far
./bench.sh run                     # three passes over all of it
```

Cases land in `mycases/`, which is git-ignored: your code stays yours. `from-commit` prints
the generated `expect.txt` and asks you to look at it, because the draft is derived from diff
hunks and the hunk header is not always the function name. When a fix was tangled with
refactoring, narrow the case by hand.

**Writing a case by hand** is the fallback when there is no commit to harvest — a bug you
know about but never fixed, or a defect class you want to probe deliberately. A case is a
directory with three files:

```
mycases/my-case/
  source.py      the code, containing the defect
  expect.txt     one line per defect: a regex naming every way a model might describe it
  forbid.txt     patterns matching code that is deliberately correct (optional)
```

```
pick_deadline|explicit_deadline or|pipeline\.py:4[0-3]
```

Two requirements for a planted defect. It must be **indisputable**: you can state the inputs
that produce the wrong result. And it must be **identifiable**: it lives in a function whose
name appears nowhere else in the file.

`forbid.txt` is the false-positive counter, and it matters more than the hit counter. A model
that calls everything a bug scores full marks on the first column and fails here.

**Three passes, not one.** `bench.sh run` does this by default. Run-to-run spread for one
model on one case turned out larger than the gap between different models, so a single pass
is a coin flip formatted as a table.

**Using a different tool is one function.** `run_model` in `code-review/run.sh` receives the
prompt and prints the answer to stdout; replace its body and everything downstream keeps
working. It calls `claude -p` by default, on your existing subscription. `RUNNER=opencode`
exists only for comparing models across providers. Note the detail in there: the `opencode`
branch strips two banner lines, and doing that to a tool without a banner would silently eat
the first finding.

## What it costs to run

| | Needed |
|---|---|
| Rescore the committed search answers | `bash`, `grep`. Nothing else |
| Run the code-review bench on your own cases | the above, plus Claude Code on a subscription |
| Compare models across providers | the above, plus `opencode` and that provider's key |

Only the third row needs an API key, and it is the narrowest use. The first two are the point.

## Where this method stops working

Being honest about this is part of the method, so it goes above the results rather than below.

**`grep` needs a textual signature.** "Did the model name this specific defect" has one: a
function name, a line of code, a line number. "Is this summary any good" does not, and no
regular expression will help. There an LLM judge is the reasonable tool — just be clear that
you are then measuring two models' agreement, not correctness.

**Patterns are written by hand,** and every new phrasing needs another one. Eight cases is an
evening. Eight hundred would not be.

**The false-positive counter matches mentions, not claims.** A model that writes "`clamp_ttl`
has no upper bound, but that is not a bug here" is scored as a false positive, because the
pattern only sees the name. Verbose models that discuss and dismiss are penalised against
terse ones that stay silent. The false-positive numbers below should be read with that in
mind; separating the two would need a human pass over the raw answers.

## What the benches found

This is what the bench was originally built to answer: which model to make the default for
code review. It is the narrowest of the three uses above, and it is here as a worked example
rather than as a leaderboard — the numbers are a snapshot of August 2026 and model versions
move underneath them. The part worth copying is the shape of the answer, not the values.

**Code review** — **3 clean runs per model** over the 6 cases every model was run on,
14 planted bugs in those 6:

| model | found of 14 | false positives (3 runs) | $/M in | s/run |
|---|---|---|---|---|
| `deepseek-chat` | 13–14 | 4 | 0.40 | 56 |
| `glm-5.2` | 12–14 | 2 | 0.97 | 163 |
| `kimi-k2.7-code` | 10–14 | 0 | 0.67 | 168 |
| `gemini-3.7-flash` | 10–11 | 3 | 0.375 | 101 |

The ranges are the point; this is not a leaderboard. The top two overlap on hit rate and
this bench does not separate them — they separate on false positives and on cost. `kimi`
is the interesting case: it never once flagged correct code, and it is also the least
predictable, spanning 10 to 14 across three runs. Cheapest and steadiest is not the same
model as quietest and least reliable, and a single mean would have hidden both facts.

A fifth model, `qwen3-coder-plus`, was run only once, and that single run is among the
excluded ones below. It therefore has no clean data here at all and is not listed.

**Search** — 8 questions, 3 tools, **2 runs only**. The three tools, since one of them is
not widely known:

- **built-in WebSearch** — the web search tool that ships inside Claude Code, used as-is.
- **Perplexity `sonar-pro`** — the hosted Perplexity API, called directly.
- **[Vane](https://github.com/ItzCrazyKns/Vane) `balanced_search`** — an open-source,
  self-hosted answer engine (formerly Perplexica). It queries a private SearxNG metasearch
  instance and has an LLM write the answer with citations. In this setup it ran locally in
  Docker with DeepSeek as the writing model, which is where its per-query cost comes from.
  It is included precisely because it is the option a person builds themselves, and the
  interesting question was whether that is worth the trouble.

| tool | hits of 16 | fabrications | $/query | s |
|---|---|---|---|---|
| built-in WebSearch | 13 | 0 | free | 5–15 |
| Perplexity `sonar-pro` | 12 | 2 | 0.0084 | 2–6 |
| Vane `balanced_search` | 9 | 2 | 0.004 | 30–60 |

**Treat these three numbers as indicative, not settled**, and by this repository's own rule:
two runs are below the three-run minimum stated further down, and the two runs disagreed
with each other on four of the eight questions. 13 against 12 is certainly noise. The gap
down to 9 is larger than the disagreement we observed, but two runs cannot establish it.

What the bench does separate, and what does not need many runs, is fabrication. One question
asks the price of a model that no longer exists; the correct answer is to say so. Two of the
three tools invented a price, and one of them attributed the invented price to a vendor page
while actually citing an aggregator. A wrong fact is visible. A fabricated citation is not.

## Three findings that cost real reruns

This section is the reason the repository is worth reading. Each of these produced a
convincing-looking result from a broken measurement.

**The model was reading the answer key.** The agent under test does not restrict itself
to the file named in the task — it globs the working directory and reads everything it
finds. The expected-findings file sat next to the source. One model "found" exactly the
planted bugs, phrased in the words of the notes file. Checking every saved transcript:
**11 runs out of 44 had read the key.** Fixed by copying a single source file into a
temporary directory and running there. Anything that knows the answer must live outside
the model's reach — not "in another file", outside the working directory.

Every run recorded before that fix is excluded from the table above and kept separately in
[`code-review/results-log-excluded.csv`](code-review/results-log-excluded.csv), so the
exclusion can be checked rather than taken on trust. It costs one run per model and removes
the fifth model entirely. For the record, the hit ranges did not move — the contaminated
runs sat inside the clean ranges, not above them — but false-positive counts did, most
sharply for `kimi`, which drops from 2 to 0. Publishing a number computed over a run you
know was contaminated is not a rounding error; it is the thing this bench exists to catch.

**The scorer under-counted, twice, for two different reasons.** A pattern written for the
phrasing we expected missed the phrasing the model used, scoring a hit as a miss. Separately,
Cyrillic in `grep` without a UTF-8 locale breaks in two ways at once: `\w` stops treating
Russian letters as word characters, and `.` counts bytes instead of characters. Both
failures under-count, and both look plausible. Hence rule 3.

**One run measures nothing.** Run-to-run spread for a single model on a single case turned
out larger than the gap between different models. Four of eight search questions disagreed
between two runs of the same tool. Any conclusion here rests on at least three runs.

**A dead run scored as a bad model.** Found while preparing this repository for publication,
which is why it is here rather than quietly fixed. `run.sh` strips the first two lines of the
runner's output to drop its banner. When the process dies before printing a third line — a
reset connection, a killed session — the error message is stripped along with the banner and
the answer file ends up empty. The scorer found no failure marker in an empty file and
returned "0 found", so a transport failure entered the journal as a model that found nothing.
The selftest made it worse: it asserted that an empty answer scores zero, encoding the bug as
intended behaviour. Empty answers are now classified as a failed run, and the selftest asserts
that instead. A scorer that reports a plausible number for work that never happened is worse
than one that crashes.

## Layout

```
code-review/   planted-bug bench: cases/, run.sh, score.sh, selftest.sh, summary.sh
search/        search bench: ORACLE.md, questions.tsv, score.sh, selftest.sh, answers/
```

Three files carry everything worth copying: `score.sh` (the scorer, ~35 and ~66 lines),
`selftest.sh` (the scorer's own tests, longer than the scorer in both benches), and one
case folder as a template.

Each directory has its own README with the full method, the failure log, and instructions
for adding a case. Those are currently in Russian; an English translation is planned.

## Notes

**What is and is not reproducible from this repository.** For the search bench, every raw
tool answer is committed under `search/answers/`, so `./score.sh` can be re-run and the
scoring disputed line by line. For the code-review bench, only the scored journal
(`code-review/results-log.csv`) is here — the raw model transcripts are not, which means
`rescore.sh` has nothing to recompute from until you produce your own runs.

Numbers were measured in August 2026. Model versions move; read this as a snapshot of a
method, not a current leaderboard.

**Two case folders have no runs.** `cases/06-split-a` and `cases/06-split-b` are the halves
of a long file, prepared to test whether splitting a long source into chunks changes what a
model finds. That experiment has not been run cleanly yet, so neither journal contains a
single row for them. They are left in place because the cases themselves are usable; the
claim they were meant to support is not made anywhere here.

The bench cases are small synthetic programs written from scratch for this repository —
generic token, order, storage, job-queue and pipeline code, with bugs planted deliberately.

