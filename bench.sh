#!/bin/bash
# Превращает коммит-починку в постоянную проверку.
#
#   ./bench.sh from-commit <sha> [--repo <путь>] [--file <путь>]
#                               [--class <класс>] [--area <область>]
#   ./bench.sh run [<случай> ...]
#   ./bench.sh list [--all]
#   ./bench.sh archive <случай> [причина]
#
# Эталон берётся из истории, а не выдумывается: коммит, который чинил баг,
# знает, что было не так и где. Модель, которая сама заложила бы ошибку и сама
# написала к ней ответ, мерила бы саму себя.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
CASES="${CASES_DIR:-$ROOT/mycases}"
MANIFEST="$CASES/manifest.tsv"

die() { echo "$*" >&2; exit 1; }

# Классы дефектов. Список закрытый и короткий намеренно: как только их станет
# двадцать, поле перестанет отвечать на вопрос «чего мы не ловим».
CLASSES="тихий-фолбэк граница-пустого-значения порядок-операций нарушение-контракта утечка-ресурса неверное-условие"

manifest_init() {
  mkdir -p "$CASES"
  [ -f "$MANIFEST" ] || printf 'случай\tкоммит\tобласть\tкласс\tстатус\tпоследний_прогон\n' > "$MANIFEST"
}

manifest_add() { # случай коммит область класс
  manifest_init
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "активен" "-" >> "$MANIFEST"
}

manifest_field() { # случай номер_колонки
  [ -f "$MANIFEST" ] || return 1
  awk -F'\t' -v c="$1" -v n="$2" 'NR>1 && $1==c {print $n; exit}' "$MANIFEST"
}

manifest_set() { # случай номер_колонки значение
  [ -f "$MANIFEST" ] || return 0
  awk -F'\t' -v OFS='\t' -v c="$1" -v n="$2" -v v="$3" \
    'NR==1 || $1!=c {print; next} {$n=v; print}' "$MANIFEST" > "$MANIFEST.tmp" \
    && mv "$MANIFEST.tmp" "$MANIFEST"
}

cmd_from_commit() {
  local sha="" repo="." file="" class="" area=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo)  repo="${2:?--repo без значения}"; shift 2 ;;
      --file)  file="${2:?--file без значения}"; shift 2 ;;
      --class) class="${2:?--class без значения}"; shift 2 ;;
      --area)  area="${2:?--area без значения}"; shift 2 ;;
      *) [ -z "$sha" ] && sha="$1" || die "лишний аргумент: $1"; shift ;;
    esac
  done
  if [ -n "$class" ]; then
    case " $CLASSES " in
      *" $class "*) ;;
      *) echo "неизвестный класс «$class». Известные:" >&2
         for c in $CLASSES; do echo "  $c" >&2; done
         die "Список закрыт намеренно. Новый класс заводится правкой CLASSES в bench.sh." ;;
    esac
  fi
  [ -n "$sha" ] || die "укажи коммит: ./bench.sh from-commit <sha> [--repo путь]"
  repo=$(cd "$repo" && pwd) || die "нет каталога $repo"
  git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$repo не git-репозиторий"
  git -C "$repo" cat-file -e "$sha^{commit}" 2>/dev/null || die "нет коммита $sha в $repo"
  git -C "$repo" rev-parse -q --verify "$sha^" >/dev/null || die "$sha без родителя, брать «до» неоткуда"

  # Какой файл чинили. При нескольких берём тот, где больше правок, но говорим
  # об этом вслух: тихий выбор здесь — это тихо неверный случай.
  if [ -z "$file" ]; then
    # Только изменённые файлы: у добавленного в этом же коммите нет версии «до»,
    # а значит и случая из него не собрать. Без фильтра самый правленый файл
    # коммита оказывается новым, и сборка отказывает там, где годных файлов ещё двадцать.
    local stat; stat=$(git -C "$repo" diff --numstat --diff-filter=M "$sha^" "$sha" | sort -k1 -nr)
    [ -n "$stat" ] || die "коммит $sha ничего не менял"
    # Не брать «самый правленый файл»: в коммите-починке документация меняется
    # чаще кода, и случай собирается по README вместо исходника. Отсеиваем
    # заведомо не-код по расширению.
    local src; src=$(echo "$stat" | cut -f3 | grep -vEi '\.(md|txt|rst|adoc|json|ya?ml|toml|ini|cfg|csv|tsv|lock|svg|png|jpe?g|gif|html?)$|^(LICENSE|CHANGELOG|\.gitignore|\.gitattributes)')
    if [ -z "$src" ]; then
      echo "В коммите $sha нет изменённых файлов с кодом (новые не годятся, у них нет версии «до»):" >&2
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
  # Дата починки, а не сегодняшняя: она отвечает на вопрос «когда это болело».
  local when; when=$(git -C "$repo" log -1 --format=%ad --date=short "$sha")
  [ -n "$area" ] || area=${base%.*}
  # Слаг из темы коммита. Кириллица и знаки выкидываются, поэтому у русской
  # темы слаг выйдет пустым — тогда берём короткий sha, он всегда есть.
  local slug; slug=$(git -C "$repo" log -1 --format=%s "$sha" \
    | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' \
    | sed 's/^-*//; s/-*$//' |  cut -c1-22 | sed 's/-*$//')
  [ -n "$slug" ] || slug="$short"
  local name="${when}-${area}-${slug}"
  local dir="$CASES/$name"
  [ -e "$dir" ] && die "случай $dir уже есть, возьми другой коммит или переименуй"
  mkdir -p "$dir"

  # Пять случаев с одной области — сигнал, что корпус растёт вглубь одного
  # больного места. Не запрет, а повод посмотреть на код, а не на тесты.
  if [ -f "$MANIFEST" ]; then
    local same; same=$(awk -F'\t' -v a="$area" 'NR>1 && $3==a && $5=="активен"' "$MANIFEST" | wc -l)
    [ "$same" -ge 5 ] && echo "В области «$area» уже $same активных случаев. Похоже, дело не в тестах."
  fi

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
    # Склейка через | без подмены IFS: присваивание IFS живёт до конца функции
    # и ломает всякое дальнейшее разделение по пробелам. Один раз уже сломало.
    printf '%s\n' "${parts[@]}" | paste -sd '|' -
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

  manifest_add "$name" "$short" "$area" "${class:-?}"

  echo
  echo "Случай собран: $dir"
  echo "  исходник:  $base ($(wc -l < "$dir/$base") строк, версия до починки)"
  echo "  ожидание:  $(cat "$dir/expect.txt")"
  echo "  область:   $area"
  echo "  класс:     ${class:-? — не задан}"
  echo
  echo "ПРОВЕРЬ expect.txt ГЛАЗАМИ. Это черновик, выведенный из диффа."
  echo "  - имена взяты из заголовков ханков и могут быть не тем именем функции;"
  echo "  - модель описывает дефект своими словами, а не словами починки;"
  echo "  - если починка была вперемешку с рефакторингом, случай надо сузить руками."
  if [ -z "$class" ]; then
    echo
    echo "КЛАСС НЕ ЗАДАН. Без него корпус нельзя спросить, чего он не ловит."
    echo "Проставь в $MANIFEST или пересобери с --class. Известные классы:"
    for c in $CLASSES; do echo "  $c"; done
    echo "Это единственное поле, которое требует суждения, поэтому и не выводится само."
  fi
  echo
  echo "Дальше: ./bench.sh run $name"
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
  if [ ${#list[@]} -eq 0 ]; then
    # Архивные в прогон не идут: их код уже не существует, и их падение
    # ничего не сообщает.
    if [ -f "$MANIFEST" ]; then
      mapfile -t list < <(awk -F'\t' 'NR>1 && $5=="активен" {print $1}' "$MANIFEST")
    else
      mapfile -t list < <(ls -1 "$CASES" 2>/dev/null | grep -v '^manifest\.tsv$')
    fi
  fi
  [ ${#list[@]} -eq 0 ] && die "активных случаев нет в $CASES"

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

  local stamp; stamp=$(date +%Y-%m-%d)
  for c in "${list[@]}"; do manifest_set "$c" 6 "$stamp"; done
}

cmd_list() {
  local all=0; [ "${1:-}" = "--all" ] && all=1
  [ -f "$MANIFEST" ] || { echo "корпус пуст: $CASES"; return; }

  # Ширину колонки имени считаем по факту: имена разной длины, а сдвинутая
  # таблица читается хуже, чем длинная.
  local w; w=$(awk -F'\t' -v all="$all" 'NR>1 && (all==1 || $5=="активен") {
    if (length($1) > m) m = length($1) } END { print (m<10 ? 10 : m) }' "$MANIFEST")
  awk -F'\t' -v all="$all" 'NR>1 && (all==1 || $5=="активен")' "$MANIFEST" \
    | sort | awk -F'\t' -v w="$w" 'BEGIN{printf "%-*s %-12s %-26s %-9s %s\n",w,"случай","область","класс","статус","прогон"}
        {printf "%-*s %-12s %-26s %-9s %s\n",w,$1,$3,$4,$5,$6}'

  echo
  echo "по классам (активные):"
  awk -F'\t' 'NR>1 && $5=="активен" {n[$4]++} END{for(k in n) printf "  %-26s %s\n", k, n[k]}' "$MANIFEST" | sort -k2 -nr
  echo "по областям (активные):"
  awk -F'\t' 'NR>1 && $5=="активен" {n[$3]++} END{for(k in n) printf "  %-26s %s\n", k, n[k]}' "$MANIFEST" | sort -k2 -nr

  local noclass; noclass=$(awk -F'\t' 'NR>1 && $5=="активен" && $4=="?"' "$MANIFEST" | wc -l)
  [ "$noclass" -gt 0 ] && echo && echo "Без класса: $noclass. Пока они так лежат, срез по классам врёт."
  return 0
}

cmd_archive() {
  local name="${1:?укажи случай: ./bench.sh archive <случай> [причина]}"
  shift || true
  local why="${*:-код переписан}"
  [ -f "$MANIFEST" ] || die "манифеста нет"
  manifest_field "$name" 1 >/dev/null || die "случая $name нет в манифесте"
  # Не удалять: по той же причине, по которой заражённые прогоны стенда лежат
  # отдельным файлом, а не стёрты. Выброшенное надо уметь предъявить.
  manifest_set "$name" 5 "архив"
  manifest_set "$name" 6 "архив: $why"
  echo "«$name» в архиве. Файлы на месте, из прогонов исключён."
}

case "${1:-}" in
  from-commit) shift; cmd_from_commit "$@" ;;
  run)         shift; cmd_run "$@" ;;
  list)        shift; cmd_list "$@" ;;
  archive)     shift; cmd_archive "$@" ;;
  *) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 1 ;;
esac
