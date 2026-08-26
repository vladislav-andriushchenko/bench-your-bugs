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

**Code review** — 8 cases, 16 planted bugs, four clean runs per model:

| model | found of 14 | false positives | $/M in | s/run |
|---|---|---|---|---|
| `deepseek-chat` | 13–14 | 5 | 0.40 | 61 |
| `glm-5.2` | 12–14 | 2 | 0.97 | 155 |
| `kimi-k2.7-code` | 10–14 | 2 | 0.67 | 161 |
| `gemini-3.7-flash` | 10–11 | 4 | 0.375 | 97 |

Read the spread, not the mean. The top two are indistinguishable on hit rate; they
separate on false positives and on cost. `kimi` matches the leaders on its best run and
collapses to zero on its worst, on the same case.

**Search** — 8 questions, 2 runs, 3 tools, 48 answers:

| tool | hits of 16 | fabrications | $/query | s |
|---|---|---|---|---|
| built-in WebSearch | 13 | 0 | free | 5–15 |
| Perplexity `sonar-pro` | 12 | 2 | 0.0084 | 2–6 |
| Vane `balanced_search` | 9 | 2 | 0.004 | 30–60 |

13 against 12 is noise; eight questions cannot separate those two. What the bench does
separate is fabrication. One question asks the price of a model that no longer exists.
The correct answer is to say so. Two of the three tools invented a price, and one of
them attributed the invented price to a vendor page while actually citing an aggregator.
A wrong fact is visible. A fabricated citation is not.

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

**The scorer under-counted, twice, for two different reasons.** A pattern written for the
phrasing we expected missed the phrasing the model used, scoring a hit as a miss. Separately,
Cyrillic in `grep` without a UTF-8 locale breaks in two ways at once: `\w` stops treating
Russian letters as word characters, and `.` counts bytes instead of characters. Both
failures under-count, and both look plausible. Hence rule 3.

**One run measures nothing.** Run-to-run spread for a single model on a single case turned
out larger than the gap between different models. Four of eight search questions disagreed
between two runs of the same tool. Any conclusion here rests on at least three runs.

## Layout

```
code-review/   planted-bug bench: cases/, run.sh, score.sh, selftest.sh, summary.sh
search/        search bench: ORACLE.md, questions.tsv, score.sh, selftest.sh, answers/
```

Each directory has its own README with the full method, the failure log, and instructions
for adding a case. Those are currently in Russian; an English translation is planned.

## Notes

Raw tool outputs are committed on purpose, so the scoring can be re-run and disputed.
Numbers were measured in August 2026 — model versions move, so treat them as a snapshot
of the method rather than a current leaderboard.

Nothing here comes from any employer's codebase. The cases are small synthetic programs
written for this bench.
