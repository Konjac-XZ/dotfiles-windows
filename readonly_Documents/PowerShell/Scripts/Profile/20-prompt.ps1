$starship = Get-Command starship -ErrorAction SilentlyContinue
$starshipExe = $starship.Source

if (-not $starshipExe) {
  $starshipPath = Join-Path $env:ProgramFiles "starship\bin\starship.exe"
  if (Test-Path $starshipPath) {
    $starshipExe = $starshipPath
  }
}

if ($starshipExe) {
  & $starshipExe init powershell | Invoke-Expression
}
