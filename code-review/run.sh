#!/bin/bash
# Прогон одной модели по задачам с известными ответами.
# Использование: run.sh <модель> [случай ...]
# Пример:        run.sh openrouter/moonshotai/kimi-k2.7-code
#                run.sh deepseek/deepseek-chat 01-tokens 05-volume
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
MODEL="${1:?укажи модель, например deepseek/deepseek-chat}"
shift

if [ $# -gt 0 ]; then
  CASES=("$@")
else
  mapfile -t CASES < <(ls -1 "$ROOT/cases")
fi

STAMP=$(date +%Y-%m-%d_%H%M%S)
SLUG=${MODEL//\//_}
OUT="$ROOT/results/${STAMP}_${SLUG}"
mkdir -p "$OUT"
echo "$MODEL" > "$OUT/model.txt"

LOG="$ROOT/results/log.csv"
[ -f "$LOG" ] || echo "дата,модель,случай,найдено,ожидалось,ложных,секунд" > "$LOG"

TASK='Ищи: ошибки, которые приведут к неверному поведению.
Нумерованный список. По каждой находке: файл, строка, в чём проблема — одной фразой.
Не предлагай улучшения стиля и не переписывай код. Только то, что работает неверно.'

sum_f=0
sum_e=0
sum_x=0
broken=0

echo "модель: $MODEL"
echo
printf '%-14s %11s %8s %8s\n' случай найдено ложных секунд
for C in "${CASES[@]}"; do
  DIR="$ROOT/cases/$C"
  if [ ! -d "$DIR" ]; then
    echo "нет случая $C"
    continue
  fi
  SRC=$(ls "$DIR"/*.py | head -1)
  N=$(basename "$SRC")

  # Модель запускать в пустом каталоге с одним файлом: в каталоге случая
  # лежат expect.txt, forbid.txt и notes.md, и агент их читает — глобом по
  # рабочему каталогу. Проверено: 11 прогонов из 44 прочитали ответы.
  WORK=$(mktemp -d)
  cp "$SRC" "$WORK/"

  T0=$(date +%s)
  ( cd "$WORK" && timeout 600 opencode run --model "$MODEL" "Проверь $N. $TASK" ) 2>&1 | tail -n +3 > "$OUT/$C.txt"
  rm -rf "$WORK"
  T=$(( $(date +%s) - T0 ))

  # Сорванный прогон не смешивать с нулевым результатом.
  if RES=$("$ROOT/score.sh" "$DIR" "$OUT/$C.txt"); then
    read -r f e x <<< "$RES"
    printf '%-14s %6s из %-3s %8s %8s\n' "$C" "$f" "$e" "$x" "$T"
    echo "$STAMP,$MODEL,$C,$f,$e,$x,$T" >> "$LOG"
    sum_f=$((sum_f + f))
    sum_e=$((sum_e + e))
    sum_x=$((sum_x + x))
  else
    printf '%-14s %11s %8s %8s\n' "$C" "сорвано" "-" "$T"
    echo "$STAMP,$MODEL,$C,,,,$T" >> "$LOG"
    broken=$((broken + 1))
  fi
done

echo
printf '%-14s %6s из %-3s %8s\n' ИТОГО "$sum_f" "$sum_e" "$sum_x"
[ "$broken" -gt 0 ] && echo "сорвано прогонов: $broken (в счёт не идут, перезапустить отдельно)"
echo
echo "ответы:  $OUT/"
echo "журнал:  $LOG"
