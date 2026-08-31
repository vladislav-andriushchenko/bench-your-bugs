#!/bin/bash
# Пересобирает results/log.csv из сохранённых ответов моделей.
# Нужен после любой правки score.sh: иначе в журнале остаются цифры,
# посчитанные старым счётчиком, и тренд врёт.
set -u
export LC_ALL=C.UTF-8
ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG="$ROOT/results/log.csv"

# Секунды нигде, кроме журнала, не сохранены: пересчёт по ответам их не
# восстанавливает. Поэтому переносим их из прежнего журнала по ключу
# дата+модель+случай, иначе правка счётчика стирает всю историю времени.
SECS=$(mktemp)
trap 'rm -f "$SECS"' EXIT
if [ -f "$LOG" ]; then
  tail -n +2 "$LOG" | awk -F, 'NF>=7 && $7 != "" { print $1 "|" $2 "|" $3 "\t" $7 }' > "$SECS"
fi

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
    sec=$(awk -F'\t' -v k="$stamp|$model|$c" '$1 == k { print $2; exit }' "$SECS")
    if res=$("$ROOT/score.sh" "$ROOT/cases/$c" "$f" 2>/dev/null); then
      read -r fo ex fa <<< "$res"
      echo "$stamp,$model,$c,$fo,$ex,$fa,$sec" >> "$LOG.new"
      n=$((n + 1))
    else
      echo "$stamp,$model,$c,,,,$sec" >> "$LOG.new"
      broken=$((broken + 1))
    fi
  done
done
mv "$LOG.new" "$LOG"
echo "пересчитано прогонов: $n, сорванных: $broken"
lost=$(awk -F, 'NR>1 && $7 == "" {n++} END {print n+0}' "$LOG")
echo "строк без времени после переноса: $lost (время берётся из прежнего журнала, из ответов моделей оно не восстанавливается)"
