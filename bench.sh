#!/bin/bash
# Превращает коммит-починку в постоянную проверку.
#
#   ./bench.sh from-commit <sha> [--repo <путь>] [--file <путь>]
#   ./bench.sh run [<случай> ...]
#   ./bench.sh list
#
# Эталон берётся из истории, а не выдумывается: коммит, который чинил баг,
# знает, что было не так и где. Модель, которая сама заложила бы ошибку и сама
# написала к ней ответ, мерила бы саму себя.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
CASES="${CASES_DIR:-$ROOT/mycases}"

die() { echo "$*" >&2; exit 1; }

cmd_from_commit() {
  local sha="" repo="." file=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo) repo="${2:?--repo без значения}"; shift 2 ;;
      --file) file="${2:?--file без значения}"; shift 2 ;;
      *) [ -z "$sha" ] && sha="$1" || die "лишний аргумент: $1"; shift ;;
    esac
  done
  [ -n "$sha" ] || die "укажи коммит: ./bench.sh from-commit <sha> [--repo путь]"
  repo=$(cd "$repo" && pwd) || die "нет каталога $repo"
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$repo не git-репозиторий"
  git -C "$repo" cat-file -e "$sha^{commit}" 2>/dev/null || die "нет коммита $sha в $repo"
  git -C "$repo" rev-parse -q --verify "$sha^" >/dev/null || die "$sha без родителя, брать «до» неоткуда"

  # Какой файл чинили. При нескольких берём тот, где больше правок, но говорим
  # об этом вслух: тихий выбор здесь — это тихо неверный случай.
  if [ -z "$file" ]; then
    local stat; stat=$(git -C "$repo" diff --numstat "$sha^" "$sha" | sort -k1 -nr)
    [ -n "$stat" ] || die "коммит $sha ничего не менял"
    # Не брать «самый правленый файл»: в коммите-починке документация меняется
    # чаще кода, и случай собирается по README вместо исходника. Отсеиваем
    # заведомо не-код по расширению.
    local src; src=$(echo "$stat" | cut -f3 | grep -vEi '\.(md|txt|rst|adoc|json|ya?ml|toml|ini|cfg|csv|tsv|lock|svg|png|jpe?g|gif|html?)$|^(LICENSE|CHANGELOG|\.gitignore|\.gitattributes)')
    if [ -z "$src" ]; then
      echo "В коммите $sha нет файлов, похожих на исходный код:" >&2
      echo "$stat" | cut -f3 | sed 's/^/  /' >&2
      die "Укажи файл явно через --file, если считаешь иначе."
    fi
    file=$(echo "$src" | head -1)
    local n; n=$(echo "$src" | wc -l)
    if [ "$n" -gt 1 ]; then
      echo "Файлов с кодом в коммите: $n. Взят первый: $file"
      echo "Другой выбрать через --file. Остальные:"
      echo "$src" | tail -n +2 | sed 's/^/  /'
    fi
  fi
  git -C "$repo" cat-file -e "$sha^:$file" 2>/dev/null || die "файла $file до починки не было, случай не собрать"

  local short; short=$(git -C "$repo" rev-parse --short "$sha")
  local base; base=$(basename "$file")
  local dir="$CASES/${short}-${base%.*}"
  [ -e "$dir" ] && die "случай $dir уже есть, удали его или возьми другой коммит"
  mkdir -p "$dir"

  # Исходник — версия ДО починки. Именно её увидит модель.
  git -C "$repo" show "$sha^:$file" > "$dir/$base" || die "не достал $file до починки"

  # Диапазоны строк берём со стороны «до»: модель читает багованный файл,
  # и ссылаться она будет на его нумерацию, а не на нумерацию после фикса.
  local diff; diff=$(git -C "$repo" diff --unified=0 "$sha^" "$sha" -- "$file")
  local ranges names
  ranges=$(echo "$diff" | grep -oE '^@@ -[0-9]+(,[0-9]+)?' | sed 's/^@@ -//' | awk -F, '{s=$1; n=($2==""?1:$2); if(n<1)n=1; print s"-"(s+n-1)}')
  # Имя функции git кладёт в хвост заголовка ханка, если умеет для этого языка.
  names=$(echo "$diff" | sed -nE 's/^@@[^@]*@@[[:space:]]*(.*)$/\1/p' \
          | grep -oE '[A-Za-z_][A-Za-z0-9_]{2,}' | sort -u | head -4)

  # Все диапазоны, а не только первый: починка часто трогает несколько мест,
  # а модель сошлётся на любое из них. Узкий паттерн даёт ложный промах —
  # это первая и самая частая ложь счётчика.
  {
    local parts=()
    for n in $names; do parts+=("$n"); done
    local esc; esc=$(echo "$base" | sed 's/\./\\./g')
    while read -r r; do
      [ -z "$r" ] && continue
      parts+=("$esc:$(range_class "${r%-*}" "${r#*-}")")
    done <<< "$ranges"
    local IFS='|'; printf '%s\n' "${parts[*]}"
  } > "$dir/expect.txt"

  # notes.md знает ответ дословно, поэтому в рабочий каталог модели он не
  # попадает: run.sh копирует туда только исходник.
  {
    echo "# Случай из коммита $short"
    echo
    echo "Репозиторий: $(basename "$repo")"
    echo "Файл: $file"
    echo "Строки до починки: $(echo "$ranges" | tr '\n' ' ')"
    echo
    echo "## Сообщение коммита"
    echo
    git -C "$repo" log -1 --format='%s%n%n%b' "$sha"
    echo "## Что изменила починка"
    echo
    echo '```diff'
    echo "$diff"
    echo '```'
  } > "$dir/notes.md"

  echo
  echo "Случай собран: $dir"
  echo "  исходник:  $base ($(wc -l < "$dir/$base") строк, версия до починки)"
  echo "  ожидание:  $(cat "$dir/expect.txt")"
  echo
  echo "ПРОВЕРЬ expect.txt ГЛАЗАМИ. Это черновик, выведенный из диффа."
  echo "  - имена взяты из заголовков ханков и могут быть не тем именем функции;"
  echo "  - модель описывает дефект своими словами, а не словами починки;"
  echo "  - если починка была вперемешку с рефакторингом, случай надо сузить руками."
  echo
  echo "Дальше: ./bench.sh run $(basename "$dir")"
}

# 12-15 -> 1[2-5]; одна строка -> просто число. Нужно, чтобы паттерн ловил
# ссылку на любую строку из диапазона, а не только на первую.
range_class() {
  local from=$1 to=$2
  [ "$from" = "$to" ] && { printf '%s' "$from"; return; }
  local pf=$from lf=$from lt=$to
  if [ ${#from} -eq ${#to} ] && [ "${from%?}" = "${to%?}" ]; then
    printf '%s[%s-%s]' "${from%?}" "${from: -1}" "${to: -1}"
  else
    printf '%s' "$from"
  fi
}

cmd_run() {
  [ -d "$CASES" ] || die "нет каталога случаев $CASES, собери первый: ./bench.sh from-commit <sha>"
  local model="${MODEL:-sonnet}"
  local runs="${RUNS:-3}"
  local list=("$@")
  [ ${#list[@]} -eq 0 ] && mapfile -t list < <(ls -1 "$CASES" 2>/dev/null)
  [ ${#list[@]} -eq 0 ] && die "в $CASES пусто"

  echo "модель: $model, прогонов: $runs"
  echo "Три прогона не для красоты: разброс между прогонами одной модели"
  echo "на одном случае бывает больше, чем разница между разными моделями."
  echo
  for i in $(seq 1 "$runs"); do
    echo "=== прогон $i из $runs ==="
    CASES_DIR="$CASES" "$ROOT/code-review/run.sh" "$model" "${list[@]}" || die "прогон $i сорвался"
    echo
  done
  echo "Сводка по всем прогонам:"
  "$ROOT/code-review/summary.sh" "$ROOT/code-review/results/log.csv"
}

cmd_list() {
  [ -d "$CASES" ] || { echo "случаев нет"; return; }
  for d in "$CASES"/*/; do
    [ -d "$d" ] || continue
    printf '%-28s %s\n' "$(basename "$d")" "$(head -1 "$d/expect.txt" 2>/dev/null)"
  done
}

case "${1:-}" in
  from-commit) shift; cmd_from_commit "$@" ;;
  run)         shift; cmd_run "$@" ;;
  list)        shift; cmd_list "$@" ;;
  *) sed -n '2,9p' "$0" | sed 's/^# \?//'; exit 1 ;;
esac
