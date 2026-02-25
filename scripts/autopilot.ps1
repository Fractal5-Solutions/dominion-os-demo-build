param(
  [ValidateSet('small','medium','large')][string]$Scale = 'large',
  [int]$Duration = 180,
  [int]$Runs = 1,
  [int]$IntervalMs = 0,
  [string]$DominionOsPath
)

if ($PSBoundParameters.ContainsKey('DominionOsPath')) {
  $env:DOMINION_OS_PATH = $DominionOsPath
}

$guard = Join-Path $PSScriptRoot '..\tools\autopilot_guard.sh'
if (Get-Command bash -ErrorAction SilentlyContinue) {
  if (Test-Path $guard) {
    bash $guard preflight
    if ($LASTEXITCODE -ne 0) { throw "autopilot guard preflight failed" }
  }
} else {
  Write-Warning "bash not found; autopilot_guard.sh was not run."
}

python demo_build.py autopilot --scale $Scale --duration $Duration --runs $Runs --interval-ms $IntervalMs

if (Get-Command bash -ErrorAction SilentlyContinue) {
  if (Test-Path $guard) {
    bash $guard push-or-abort
    if ($LASTEXITCODE -ne 0) { throw "autopilot push-or-abort failed" }
  }
}
