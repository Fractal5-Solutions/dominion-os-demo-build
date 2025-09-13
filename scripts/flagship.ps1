param(
  [ValidateSet('small','medium','large')][string]$Scale = 'large',
  [int]$Duration = 300,
  [int]$RefreshMs = 0,
  [switch]$NoUi,
  [string]$DominionOsPath
)

if ($PSBoundParameters.ContainsKey('DominionOsPath')) {
  $env:DOMINION_OS_PATH = $DominionOsPath
}

$argsList = @('flagship', '--scale', $Scale, '--duration', $Duration, '--refresh-ms', $RefreshMs)
if ($NoUi) { $argsList += '--no-ui' }
python demo_build.py @argsList
