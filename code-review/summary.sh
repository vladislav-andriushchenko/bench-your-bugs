#!/bin/bash
# Сводка по results/log.csv: сколько набрала каждая модель в каждом прогоне
# и насколько прогоны одной модели расходятся между собой.
#
# Главный вопрос, на который отвечает эта таблица: разница между моделями
# больше разброса между прогонами одной модели, или нет. Если нет —
# выбирать модель по этим числам нельзя.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
LOG="${1:-$ROOT/results/log.csv}"
[ -f "$LOG" ] || { echo "нет файла $LOG"; exit 1; }

awk -F, '
NR == 1 { next }
$4 == "" { next }
{
  run = $2 SUBSEP $1
  found[run] += $4
  total[run] += $5
  false_hits[run] += $6
  secs[run] += $7
  ncases[run]++
  models[$2] = 1
  if (ncases[run] > maxcases) maxcases = ncases[run]

  key = $2 SUBSEP $3
  vals[key] = vals[key] " " $4
}
END {
  # Незавершённые прогоны в счёт не идут: идущий прямо сейчас прогон
  # иначе выглядит как провал модели.
  nm = 0
  for (m in models) sorted[++nm] = m
  for (i = 1; i < nm; i++)
    for (j = i + 1; j <= nm; j++)
      if (sorted[i] > sorted[j]) { t = sorted[i]; sorted[i] = sorted[j]; sorted[j] = t }

  printf "%-38s %8s %9s %9s %8s %8s\n", "модель", "прогонов", "лучший", "худший", "ложных", "секунд"
  skipped = 0
  for (i = 1; i <= nm; i++) {
    m = sorted[i]
    n = 0; best = -1; worst = 9999; sumx = 0; sums = 0; tot = 0
    for (run in found) {
      split(run, a, SUBSEP)
      if (a[1] != m) continue
      if (ncases[run] < maxcases) { skipped++; continue }
      n++
      v = found[run]
      if (v > best) best = v
      if (v < worst) worst = v
      sumx += false_hits[run]; sums += secs[run]; tot = total[run]
    }
    if (n == 0) { printf "%-38s %8s\n", m, "нет полных"; continue }
    printf "%-38s %8d %7d/%-2d %7d/%-2d %8d %8d\n", m, n, best, tot, worst, tot, sumx, sums
  }
  if (skipped > 0) printf "\nнезавершённых прогонов пропущено: %d\n", skipped

  printf "\n%s\n", "случаи, где прогоны одной модели разошлись:"
  any = 0
  for (i = 1; i <= nm; i++) {
    m = sorted[i]
    for (key in vals) {
      split(key, a, SUBSEP)
      if (a[1] != m) continue
      n = split(vals[key], arr, " ")
      if (n < 2) continue
      lo = arr[1]; hi = arr[1]
      for (k = 2; k <= n; k++) { if (arr[k] < lo) lo = arr[k]; if (arr[k] > hi) hi = arr[k] }
      if (lo == hi) continue
      printf "  %-38s %-14s %s\n", m, a[2], vals[key]
      any = 1
    }
  }
  if (!any) printf "  нет — все прогоны совпали\n"
}
' "$LOG"
