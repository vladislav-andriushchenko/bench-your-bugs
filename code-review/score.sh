#!/bin/bash
# Считает попадания одного прогона.
# Использование: score.sh <каталог случая> <файл с ответом модели>
# Печатает: найдено ожидалось ложных
# Код 2 — прогон сорвался (отказ провайдера, таймаут), считать нечего.
set -u
DIR="${1:?каталог случая}"
ANSWER="${2:?файл с ответом модели}"

# Сорванный прогон отличать от нулевого результата: иначе отказ провайдера
# выглядит в таблице как плохая модель.
if grep -qE 'Internal Server Error|"code":5[0-9][0-9]|rate.?limit|Request timed out|terminated by signal' "$ANSWER"; then
  echo "- - -"
  exit 2
fi

# Модели ссылаются на строку кто во что горазд:
#   tokens.py:7 | **tokens.py, строки 7-9** | в файле `tokens.py` на строке 7 | tokens.py line 7
# Приводим к виду <файл>.py:<число>, иначе шаблон ловит одну форму из четырёх.
# Внутри [ ] только однобайтные символы: кириллица в скобочном классе распадается
# на байты вне UTF-8 локали и молча перестаёт работать.
NORM=$(mktemp)
trap 'rm -f "$NORM"' EXIT
LINE_WORD='строках|строки|строка|строке|строку|строк|lines|line'
PREP='на|в|at|on'
sed -E 's/\*+//g; s/`//g' "$ANSWER" \
  | sed -E "s/(\.py)[[:space:]]*[,;:-]*[[:space:]]*($PREP)?[[:space:]]*($LINE_WORD)?[[:space:]]*(No\.|#)?[[:space:]]*:?[[:space:]]*([0-9])/\1:\5/g" \
  > "$NORM"

: > "$ANSWER.missed"
found=0
expected=0
while IFS= read -r pat || [ -n "$pat" ]; do
  [ -z "${pat// /}" ] && continue
  expected=$((expected + 1))
  if grep -qiE -- "$pat" "$NORM"; then
    found=$((found + 1))
  else
    echo "$pat" >> "$ANSWER.missed"
  fi
done < "$DIR/expect.txt"

false_hits=0
if [ -f "$DIR/forbid.txt" ]; then
  while IFS= read -r pat || [ -n "$pat" ]; do
    [ -z "${pat// /}" ] && continue
    grep -qiE -- "$pat" "$NORM" && false_hits=$((false_hits + 1))
  done < "$DIR/forbid.txt"
fi

echo "$found $expected $false_hits"
