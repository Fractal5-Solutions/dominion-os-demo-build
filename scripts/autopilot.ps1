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

python demo_build.py autopilot --scale $Scale --duration $Duration --runs $Runs --interval-ms $IntervalMs
