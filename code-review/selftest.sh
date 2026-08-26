#!/bin/bash
# Проверка самого счётчика, без вызова моделей. Ловит поломку разбора expect/forbid
# и, главное, разные способы записи ссылки на строку.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/case"
printf 'issue_stamp|created_at or time|tokens\.py:[0-9]\n' > "$T/case/expect.txt"
printf 'clamp_ttl\n' > "$T/case/forbid.txt"

fail=0
check() {
  local name="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    echo "ок    $name"
  else
    echo "СБОЙ  $name: ожидалось [$want], получено [$got]"
    fail=1
  fi
}

run() { "$ROOT/score.sh" "$T/case" "$1"; }

printf 'ISSUE_STAMP подставляет текущее время\n'   > "$T/a.txt"
check "по имени функции"          "1 1 0" "$(run "$T/a.txt")"

printf 'tokens.py:7 — значение подменяется\n'      > "$T/b.txt"
check "файл:строка через двоеточие" "1 1 0" "$(run "$T/b.txt")"

printf '**tokens.py, строки 7-9**: значение подменяется\n' > "$T/c.txt"
check "запятая и слово строки"      "1 1 0" "$(run "$T/c.txt")"

printf 'в файле `tokens.py` на строке 7 неверно\n' > "$T/d.txt"
check "предлог и обратные кавычки"  "1 1 0" "$(run "$T/d.txt")"

printf 'tokens.py line 7 is wrong\n'               > "$T/e.txt"
check "английская форма"            "1 1 0" "$(run "$T/e.txt")"

printf 'clamp_ttl не имеет верхней границы\n'      > "$T/f.txt"
check "ложное срабатывание"         "0 1 1" "$(run "$T/f.txt")"

: > "$T/g.txt"
check "пустой ответ"                "0 1 0" "$(run "$T/g.txt")"

printf 'Error: Internal Server Error: {"error":{"code":500}}\n' > "$T/h.txt"
out=$(run "$T/h.txt"); rc=$?
check "сорванный прогон отличён от нуля" "- - - 2" "$out $rc"

check "промах записан в .missed" "issue_stamp|created_at or time|tokens\.py:[0-9]" "$(cat "$T/f.txt.missed")"

exit $fail
