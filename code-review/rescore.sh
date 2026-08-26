#!/bin/bash
# Пересобирает results/log.csv из сохранённых ответов моделей.
# Нужен после любой правки score.sh: иначе в журнале остаются цифры,
# посчитанные старым счётчиком, и тренд врёт.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG="$ROOT/results/log.csv"

echo "дата,модель,случай,найдено,ожидалось,ложных,секунд" > "$LOG.new"
n=0
broken=0
for d in "$ROOT"/results/*/; do
  [ -d "$d" ] || continue
  stamp=$(basename "$d" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}')
  if [ -f "$d/model.txt" ]; then
    model=$(cat "$d/model.txt")
  else
    model="неизвестно:$(basename "$d")"
  fi
  for f in "$d"*.txt; do
    [ -e "$f" ] || continue
    c=$(basename "$f" .txt)
    [ -d "$ROOT/cases/$c" ] || continue
    if res=$("$ROOT/score.sh" "$ROOT/cases/$c" "$f" 2>/dev/null); then
      read -r fo ex fa <<< "$res"
      echo "$stamp,$model,$c,$fo,$ex,$fa," >> "$LOG.new"
      n=$((n + 1))
    else
      echo "$stamp,$model,$c,,,," >> "$LOG.new"
      broken=$((broken + 1))
    fi
  done
done
mv "$LOG.new" "$LOG"
echo "пересчитано прогонов: $n, сорванных: $broken"
echo "время выполнения в пересобранном журнале не восстанавливается — оно нигде не сохранено"
