#!/usr/bin/env bash
# Считает ответы в answers/ по паттернам из questions.tsv.
# Кириллица в grep без UTF-8 локали ломается дважды: \w не считает русские
# буквы словесными, а точка считает байты, не символы. Оба раза счётчик молча
# занижает. Локаль задаётся здесь, а не снаружи.
export LC_ALL=C.UTF-8
# Никакой модели-судьи: только grep, как на стенде моделей.
set -u
cd "$(dirname "$0")"
Q=${1:-questions.tsv}
A=${2:-answers}
printf 'tool,run,qid,class,hit,false_positive,bytes\n'
while IFS=$'\t' read -r qid cls question expect forbid; do
  [ -z "${qid:-}" ] && continue
  for f in "$A"/*-"$qid".md; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .md)
    tool=${base%%-r*}
    run=${base#*-r}; run=${run%%-*}
    sz=$(wc -c < "$f" | tr -d ' ')
    if [ "$sz" -lt 40 ]; then
      printf '%s,%s,%s,%s,сорвано,-,%s\n' "$tool" "$run" "$qid" "$cls" "$sz"; continue
    fi
    hit=нет
    grep -qiE -- "$expect" "$f" && hit=да
    fp=-
    if [ -n "${forbid:-}" ]; then fp=нет; grep -qiE -- "$forbid" "$f" && fp=да; fi
    printf '%s,%s,%s,%s,%s,%s,%s\n' "$tool" "$run" "$qid" "$cls" "$hit" "$fp" "$sz"
  done
done < "$Q"
