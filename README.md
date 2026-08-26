# LLM eval benches

Two small benchmarks that answer "which tool is actually better" by running it,
not by arguing about it. One measures how well LLMs find planted bugs during code
review. The other measures how well search tools answer factual questions.

Both are built the same way, and the method is the point of this repository.

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

## What the benches found

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

The bench cases are small synthetic programs written from scratch for this repository —
generic token, order, storage, job-queue and pipeline code, with bugs planted deliberately.

