param(
  [string]$DominionOsPath
)

if ($PSBoundParameters.ContainsKey('DominionOsPath')) {
  $env:DOMINION_OS_PATH = $DominionOsPath
}
python demo_build.py run
