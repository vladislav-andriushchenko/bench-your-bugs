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
    $t0.Stop()
    "$qid`t$run`t$([int]$t0.Elapsed.TotalSeconds)`t$($line.Trim())" |
      Out-File -FilePath "$base\answers\pplx-timing.tsv" -Encoding utf8 -Append
  }
}
"DONE"
