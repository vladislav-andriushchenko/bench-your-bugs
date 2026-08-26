#!/bin/bash
# Прогон одной модели по задачам с известными ответами.
# Использование: run.sh <модель> [случай ...]
# Пример:        run.sh openrouter/moonshotai/kimi-k2.7-code
#                run.sh deepseek/deepseek-chat 01-tokens 05-volume
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
MODEL="${1:?укажи модель, например sonnet}"
shift

# Чем гонять модель. По умолчанию Claude Code в неинтерактивном режиме: он
# ходит по подписке, API-ключи и второй провайдер не нужны. RUNNER=opencode
# нужен только для сравнения моделей разных провайдеров.
#
# Это единственное место, которое привязывает стенд к конкретному инструменту.
# Свой вызов подставляется здесь: команда получает промпт первым аргументом и
# печатает ответ модели в stdout.
RUNNER=${RUNNER:-claude}
# Проверять здесь, а не внутри run_model: там вызов идёт в подоболочке, и
# выход из неё не останавливает прогон. Неизвестный RUNNER молча писал бы
# сообщение об ошибке в файл ответа, и счётчик записал бы это как «0 из N».
case "$RUNNER" in
  claude|opencode) ;;
  *) echo "неизвестный RUNNER=$RUNNER, поддерживаются claude и opencode" >&2; exit 1 ;;
esac
command -v "$RUNNER" >/dev/null || { echo "$RUNNER не найден в PATH" >&2; exit 1; }

run_model() {
  case "$RUNNER" in
    claude)
      # < /dev/null обязателен: без него claude ждёт stdin и тратит на это время
      timeout 600 claude -p --model "$MODEL" "$1" < /dev/null
      ;;
    opencode)
      # tail -n +3 срезает баннер opencode. Для других инструментов баннера
      # нет, и срезать нельзя: срежется первая находка.
      timeout 600 opencode run --model "$MODEL" "$1" 2>&1 | tail -n +3
      ;;
  esac
}

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
  ( cd "$WORK" && run_model "Проверь $N. $TASK" ) > "$OUT/$C.txt" 2>&1
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
