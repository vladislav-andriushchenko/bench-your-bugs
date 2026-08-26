$base = $PSScriptRoot
$rows = Get-Content "$base\questions.tsv" -Encoding UTF8 | Where-Object { $_.Trim() -ne '' }
foreach ($run in 1..2) {
  foreach ($row in $rows) {
    $f = $row -split "`t"
    $qid = $f[0]; $q = $f[2]
    $out = "$base\answers\pplx-r$run-$qid.md"
    $t0 = [Diagnostics.Stopwatch]::StartNew()
    try {
      $line = & "$env:USERPROFILE\bin\pplx.ps1" $q -Mode balanced -Out $out 2>&1 | Out-String
    } catch {
      "ERROR: $_" | Out-File -FilePath $out -Encoding utf8
      $line = "error"
    }
    # Отказ без исключения кодом выхода не ловится try/catch: без этой строки
    # диагностика провайдера попадёт в таблицу как ответ модели.
    if ($LASTEXITCODE -ne 0) { $line = "FAILED exit=$LASTEXITCODE $line" }
    $t0.Stop()
    # Схлопнуть переносы строк: многострочный вывод ломает формат TSV.
    $note = ($line -replace '\s+', ' ').Trim()
    "$qid`t$run`t$([int]$t0.Elapsed.TotalSeconds)`t$note" |
      Out-File -FilePath "$base\answers\pplx-timing.tsv" -Encoding utf8 -Append
  }
}
"DONE"
