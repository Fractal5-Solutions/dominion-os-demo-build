param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$required = @(
    "brand/fractal5-software.tokens.light.css",
    "brand/fractal5-software.tokens.dark.css",
    "brand/fractal5-software.theme.contract.json"
)

$frontendFiles = @(
    "demo/index.html",
    "store/index.html"
)

$missing = @()
foreach ($item in $required) {
    if (-not (Test-Path (Join-Path $RepoRoot $item))) {
        $missing += $item
    }
}

$themeRefMissing = @()
foreach ($file in $frontendFiles) {
    $full = Join-Path $RepoRoot $file
    if (-not (Test-Path $full)) {
        $themeRefMissing += $file
        continue
    }
    $content = Get-Content $full -Raw
    if ($content -notmatch "/brand/fractal5-software.tokens.light.css" -or
        $content -notmatch "/brand/fractal5-software.tokens.dark.css" -or
        $content -notmatch "Fractal5 Solutions Inc\.") {
        $themeRefMissing += $file
    }
}

if ($missing.Count -gt 0) {
    Write-Output "FAIL_MISSING_PACK"
    $missing | ForEach-Object { Write-Output "missing: $_" }
    exit 1
}

if ($themeRefMissing.Count -gt 0) {
    Write-Output "FAIL_FRONTEND_THEME"
    $themeRefMissing | ForEach-Object { Write-Output "check: $_" }
    exit 1
}

Write-Output "PASS_FRONTEND"
exit 0
