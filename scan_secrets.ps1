$repo='D:\phi-ops\github\dominion-demo-build'
Set-Location $repo
$patterns = @(
  'ghp_',
  'sk_live',
  'sk_test',
  'AKIA',
  'AIza',
  'xoxp-',
  'xoxb-',
  'xoxa-',
  '-----BEGIN',
  'PRIVATE KEY',
  'id_rsa',
  'POSTGRES_PASSWORD=',
  'STRIPE',
  'OAUTH_CLIENT_SECRET',
  'JWT_SECRET',
  'SECRET_KEY',
  'PASSWORD=',
  'API_KEY'
)
$out = Join-Path $repo 'scan_results.txt'
if (Test-Path $out) { Remove-Item $out -Force }
Add-Content -Path $out -Value "Scan started at: $(Get-Date -Format o)"
foreach ($p in $patterns) {
  Add-Content -Path $out -Value "\n===PATTERN: $p ==="
  try {
    git grep -nI -F -i -- $p 2>$null | ForEach-Object { Add-Content -Path $out -Value $_ }
    if ($LASTEXITCODE -ne 0) { Add-Content -Path $out -Value 'NO_MATCH' }
  } catch {
    Add-Content -Path $out -Value "ERROR_RUNNING_GIT_GREP: $($_.Exception.Message)"
  }
}
Add-Content -Path $out -Value "\n===FILENAME SEARCH==="
Get-ChildItem -Path $repo -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.pem$|\.p12$|\.key$|id_rsa$|\.env$|\.crt$' } | ForEach-Object { Add-Content -Path $out -Value $_.FullName }
Add-Content -Path $out -Value "\nScan completed at: $(Get-Date -Format o)"
