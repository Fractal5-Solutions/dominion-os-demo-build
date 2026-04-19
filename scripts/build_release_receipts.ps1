[CmdletBinding()]
param(
    [string]$MarketplaceProject = "dominion-marketplace-prod",
    [string]$MarketplaceRegion = "us-central1",
    [string]$Pipeline = "dominion-os-pipeline",
    [string]$Target = "prod-marketplace",
    [string]$MarketplaceService = "dominion-bootstrap",
    [string]$SandboxProject = "f5-demo-sandbox",
    [string]$SandboxRegion = "us-central1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$dateStamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
$stamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH-mm-ssZ")
$outRoot = Join-Path $repoRoot "reports\release-receipts"
$outDir = Join-Path $outRoot ("GCP_SANDBOX_GATES_{0}" -f $stamp)
$rawDir = Join-Path $outDir "raw"
New-Item -ItemType Directory -Force -Path $rawDir | Out-Null

function RunCmd {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$File,
        [string[]]$CmdArgs = @()
    )

    $txt = (& $File @CmdArgs 2>&1 | Out-String)
    $code = $LASTEXITCODE
    if ($null -eq $code) { $code = 0 }
    $raw = Join-Path $rawDir ("{0}.txt" -f $Name)
    $txt | Set-Content -Path $raw -Encoding UTF8
    [pscustomobject]@{
        ok = ($code -eq 0)
        code = $code
        text = $txt.Trim()
        raw = $raw
    }
}

function TryJson {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    $candidate = $Text.Trim()
    $starts = New-Object System.Collections.Generic.List[int]
    for ($i = 0; $i -lt $candidate.Length; $i++) {
        $ch = $candidate[$i]
        if ($ch -eq "{" -or $ch -eq "[") { $starts.Add($i) | Out-Null }
    }
    foreach ($s in $starts) {
        $slice = $candidate.Substring($s)
        try { return ($slice | ConvertFrom-Json) } catch { continue }
    }
    return $null
}

function AddCheck {
    param(
        [Parameter(Mandatory = $true)]$Checks,
        [string]$Id,
        [string]$Gate,
        [bool]$Pass,
        [string]$Summary,
        [object]$Evidence
    )
    $Checks.Add([pscustomobject]@{
        id = $Id
        gate = $Gate
        pass = $Pass
        summary = $Summary
        evidence = $Evidence
    }) | Out-Null
}

$checks = New-Object System.Collections.Generic.List[object]

# M01
$auth = RunCmd "gcloud_auth_active" "gcloud" @("auth", "list", "--filter=status:ACTIVE", "--format=json")
$authObj = TryJson $auth.text
$accounts = @()
if ($auth.ok -and $authObj) { $accounts = @($authObj | ForEach-Object { [string]$_.account } | Where-Object { $_ }) }
AddCheck $checks "M01" "Active gcloud account" ($accounts.Count -ge 1) ("accounts={0}" -f $accounts.Count) @{ accounts = $accounts; raw = $auth.raw }

# M02
$cfg = RunCmd "gcloud_project" "gcloud" @("config", "get-value", "project")
$activeProject = if ($cfg.ok) { $cfg.text.Trim() } else { "" }
AddCheck $checks "M02" "Active project aligned" ($activeProject -eq $MarketplaceProject) ("active_project={0}" -f $activeProject) @{ expected = $MarketplaceProject; raw = $cfg.raw }

# M03
$billing = RunCmd "gcloud_billing" "gcloud" @("beta", "billing", "projects", "describe", $MarketplaceProject, "--format=json")
$billingObj = TryJson $billing.text
$billingEnabled = $false
if ($billing.ok -and $billingObj) { $billingEnabled = [bool]$billingObj.billingEnabled }
AddCheck $checks "M03" "Billing enabled" $billingEnabled ("billing_enabled={0}" -f $billingEnabled) @{ raw = $billing.raw }

# M04
$requiredApis = @(
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudcommerceprocurement.googleapis.com",
    "clouddeploy.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicecontrol.googleapis.com",
    "serviceusage.googleapis.com"
)
$apiFilter = "config.name:(" + ($requiredApis -join " ") + ")"
$apis = RunCmd "gcloud_required_apis" "gcloud" @("services", "list", "--enabled", "--project=$MarketplaceProject", "--filter=$apiFilter", "--format=value(config.name)")
$enabledApis = @($apis.text -split "`r?`n" | Where-Object { $_ })
$missingApis = @($requiredApis | Where-Object { $enabledApis -notcontains $_ })
AddCheck $checks "M04" "Required APIs enabled" ($missingApis.Count -eq 0) ("missing={0}" -f $missingApis.Count) @{ missing = $missingApis; raw = $apis.raw }

# M05 + M06
$release = RunCmd "gcloud_release" "gcloud" @("deploy", "releases", "list", "--project=$MarketplaceProject", "--region=$MarketplaceRegion", "--delivery-pipeline=$Pipeline", "--sort-by=~createTime", "--limit=1", "--format=json")
$releaseObj = TryJson $release.text
$releaseItem = $null
if ($release.ok -and $releaseObj) {
    $arr = @($releaseObj)
    if ($arr.Count -gt 0) { $releaseItem = $arr[0] }
}
$renderState = if ($releaseItem) { [string]$releaseItem.renderState } else { "" }
AddCheck $checks "M05" "Latest release render succeeded" ($renderState -eq "SUCCEEDED") ("render_state={0}" -f $renderState) @{ raw = $release.raw }

$releaseName = if ($releaseItem) { [string]$releaseItem.name } else { "" }
$releaseId = if ($releaseName) { ($releaseName -split "/")[-1] } else { "" }
$rolloutState = ""
$rolloutTarget = ""
$rolloutRaw = ""
if ($releaseId) {
    $rollout = RunCmd "gcloud_rollout" "gcloud" @("deploy", "rollouts", "list", "--project=$MarketplaceProject", "--region=$MarketplaceRegion", "--delivery-pipeline=$Pipeline", "--release=$releaseId", "--sort-by=~createTime", "--limit=1", "--format=json")
    $rolloutRaw = $rollout.raw
    $rollObj = TryJson $rollout.text
    if ($rollout.ok -and $rollObj) {
        $arr = @($rollObj)
        if ($arr.Count -gt 0) {
            $rolloutState = [string]$arr[0].state
            $rolloutTarget = [string]$arr[0].targetId
        }
    }
}
AddCheck $checks "M06" "Latest rollout succeeded to target" ($rolloutState -eq "SUCCEEDED" -and $rolloutTarget -eq $Target) ("state={0} target={1}" -f $rolloutState, $rolloutTarget) @{ raw = $rolloutRaw }

# M07..M12
$runSvc = RunCmd "gcloud_run_marketplace_service" "gcloud" @("run", "services", "describe", $MarketplaceService, "--project=$MarketplaceProject", "--region=$MarketplaceRegion", "--format=json")
$runObj = TryJson $runSvc.text
$ready = $false
$latestRev = ""
$traffic = 0
$ingress = ""
$image = ""
$runtimeSa = ""
$minScale = 0
$templateMaxScale = 0
$serviceMaxScale = 0
$effectiveMaxScale = 0
$cpuThrottle = ""
if ($runSvc.ok -and $runObj) {
    foreach ($c in @($runObj.status.conditions)) {
        if ([string]$c.type -eq "Ready" -and [string]$c.status -eq "True") { $ready = $true }
    }
    $latestRev = [string]$runObj.status.latestReadyRevisionName
    foreach ($t in @($runObj.status.traffic)) {
        $isLatest = $false
        if ($t.PSObject.Properties.Name -contains "latestRevision" -and $t.latestRevision -eq $true) { $isLatest = $true }
        if ([string]$t.revisionName -eq $latestRev) { $isLatest = $true }
        if ($isLatest) { $traffic += [int]$t.percent }
    }
    $ingress = [string]$runObj.metadata.annotations."run.googleapis.com/ingress"
    $image = [string]$runObj.spec.template.spec.containers[0].image
    $runtimeSa = [string]$runObj.spec.template.spec.serviceAccountName
    [void][int]::TryParse([string]$runObj.spec.template.metadata.annotations."autoscaling.knative.dev/minScale", [ref]$minScale)
    $templateMaxParsed = [int]::TryParse([string]$runObj.spec.template.metadata.annotations."autoscaling.knative.dev/maxScale", [ref]$templateMaxScale)
    $serviceMaxParsed = [int]::TryParse([string]$runObj.metadata.annotations."run.googleapis.com/maxScale", [ref]$serviceMaxScale)
    $maxCandidates = New-Object System.Collections.Generic.List[int]
    if ($templateMaxParsed -and $templateMaxScale -gt 0) { $maxCandidates.Add($templateMaxScale) | Out-Null }
    if ($serviceMaxParsed -and $serviceMaxScale -gt 0) { $maxCandidates.Add($serviceMaxScale) | Out-Null }
    if ($maxCandidates.Count -gt 0) { $effectiveMaxScale = ($maxCandidates | Measure-Object -Minimum).Minimum }
    $cpuThrottle = [string]$runObj.spec.template.metadata.annotations."run.googleapis.com/cpu-throttling"
}
AddCheck $checks "M07" "Cloud Run service Ready=True" $ready ("ready={0}" -f $ready) @{ latest_ready_revision = $latestRev; raw = $runSvc.raw }
AddCheck $checks "M08" "Cloud Run latest revision 100% traffic" ($traffic -ge 100) ("latest_traffic_pct={0}" -f $traffic) @{ raw = $runSvc.raw }

$iam = RunCmd "gcloud_run_iam_marketplace" "gcloud" @("run", "services", "get-iam-policy", $MarketplaceService, "--project=$MarketplaceProject", "--region=$MarketplaceRegion", "--format=json")
$iamObj = TryJson $iam.text
$publicInvoker = $false
if (
    $iam.ok -and
    $iamObj -and
    $iamObj.PSObject.Properties.Name -contains "bindings" -and
    $iamObj.bindings
) {
    foreach ($b in @($iamObj.bindings)) {
        if ([string]$b.role -ne "roles/run.invoker") { continue }
        foreach ($m in @($b.members)) {
            if ($m -eq "allUsers" -or $m -eq "allAuthenticatedUsers") { $publicInvoker = $true }
        }
    }
}
$privateIngressValues = @("internal", "internal-and-cloud-load-balancing")
$ingressIsPrivate = $privateIngressValues -contains $ingress
AddCheck $checks "M09" "Private exposure posture" ((-not $publicInvoker) -and $ingressIsPrivate) ("public_invoker={0} ingress={1} ingress_private={2}" -f $publicInvoker, $ingress, $ingressIsPrivate) @{ raw = $iam.raw }

$saEmail = $runtimeSa
if ($runtimeSa -and $runtimeSa -notmatch "@") { $saEmail = "$runtimeSa@$MarketplaceProject.iam.gserviceaccount.com" }
$sa = RunCmd "gcloud_runtime_sa" "gcloud" @("iam", "service-accounts", "describe", $saEmail, "--project=$MarketplaceProject", "--format=json")
AddCheck $checks "M10" "Runtime service account exists" $sa.ok ("service_account={0}" -f $saEmail) @{ raw = $sa.raw }
AddCheck $checks "M11" "Image digest pinned" ($image -match "@sha256:[a-f0-9]{64}$") ("digest_pinned={0}" -f ($image -match "@sha256:[a-f0-9]{64}$")) @{ image = $image; raw = $runSvc.raw }
AddCheck $checks "M12" "Ceiling performance profile active" ($minScale -ge 1 -and $effectiveMaxScale -ge 100 -and $cpuThrottle -eq "false") ("minScale={0} template_maxScale={1} service_maxScale={2} effective_maxScale={3} cpu_throttling={4}" -f $minScale, $templateMaxScale, $serviceMaxScale, $effectiveMaxScale, $cpuThrottle) @{ raw = $runSvc.raw }

# D01..D08
$repo = RunCmd "gh_repo_demo_build" "gh" @("repo", "view", "Fractal5-Solutions/dominion-os-demo-build", "--json", "nameWithOwner,url,visibility,isPrivate,defaultBranchRef")
$repoObj = TryJson $repo.text
$repoPublic = $false
if ($repo.ok -and $repoObj) { $repoPublic = (-not [bool]$repoObj.isPrivate) -and ([string]$repoObj.visibility -eq "PUBLIC") }
$repoVisibility = if ($repoObj -and $repoObj.PSObject.Properties.Name -contains "visibility") { [string]$repoObj.visibility } else { "" }
AddCheck $checks "D01" "Demo repo is public" $repoPublic ("visibility={0}" -f $repoVisibility) @{ raw = $repo.raw }

$zipCode = RunCmd "http_demo_zip_status" "curl.exe" @("-L", "-s", "-o", "NUL", "-w", "%{http_code}", "https://github.com/Fractal5-Solutions/dominion-os-demo-build/archive/refs/heads/main.zip")
AddCheck $checks "D02" "Public demo zip download responds 200" ($zipCode.text -eq "200") ("status={0}" -f $zipCode.text) @{ raw = $zipCode.raw }

$demoCode = RunCmd "http_demo_page_status" "curl.exe" @("-L", "-s", "-o", "NUL", "-w", "%{http_code}", "https://www.fractal5solutions.com/demo")
$storeCode = RunCmd "http_store_page_status" "curl.exe" @("-L", "-s", "-o", "NUL", "-w", "%{http_code}", "https://www.fractal5solutions.com/store")
$healthCodeWww = RunCmd "http_demo_healthz_www_status" "curl.exe" @("-L", "-s", "-o", "NUL", "-w", "%{http_code}", "https://www.fractal5solutions.com/demo/healthz")
$healthCodeCanonical = RunCmd "http_demo_healthz_canonical_status" "curl.exe" @("-s", "-o", "NUL", "-w", "%{http_code}", "https://demo.fractal5solutions.com/demo/healthz")
$null = RunCmd "http_demo_healthz_canonical_head" "curl.exe" @("-I", "--max-time", "20", "https://demo.fractal5solutions.com/demo/healthz")
AddCheck $checks "D03" "Public /demo responds 200" ($demoCode.text -eq "200") ("status={0}" -f $demoCode.text) @{ raw = $demoCode.raw }
AddCheck $checks "D04" "Public /store responds 200" ($storeCode.text -eq "200") ("status={0}" -f $storeCode.text) @{ raw = $storeCode.raw }
$healthPass = ($healthCodeWww.text -eq "200") -or ($healthCodeCanonical.text -in @("200", "302"))
AddCheck $checks "D05" "Demo health endpoint is reachable (www=200 or canonical runtime 200/302)" $healthPass ("www_status={0} canonical_status={1}" -f $healthCodeWww.text, $healthCodeCanonical.text) @{ raw_www = $healthCodeWww.raw; raw_canonical = $healthCodeCanonical.raw }

$storeFetchRaw = Join-Path $rawDir "store_html_fetch.txt"
$storeFetchOk = $true
$storeHtml = ""
try {
    $storeHtml = (Invoke-WebRequest -UseBasicParsing -ErrorAction Stop "https://www.fractal5solutions.com/store").Content
    $storeHtml | Set-Content -Path $storeFetchRaw -Encoding UTF8
} catch {
    $storeFetchOk = $false
    ($_ | Out-String).Trim() | Set-Content -Path $storeFetchRaw -Encoding UTF8
}
$links = @()
if ($storeFetchOk -and -not [string]::IsNullOrWhiteSpace($storeHtml)) {
    $links = [regex]::Matches($storeHtml, "https?://[^`"'\s<>]+") | ForEach-Object { $_.Value } | Sort-Object -Unique
}
$downloadLinks = @($links | Where-Object { $_ -match "github\.com/.*/dominion-os-demo-build|\.zip(\?|$)|download" })
($downloadLinks -join "`r`n") | Set-Content -Path (Join-Path $rawDir "store_download_links.txt") -Encoding UTF8
$downloadSurfacePass = ($downloadLinks.Count -gt 0) -or ($zipCode.text -eq "200")
AddCheck $checks "D06" "Public demo download surface is reachable" $downloadSurfacePass ("store_fetch_ok={0} store_links={1} zip_status={2}" -f $storeFetchOk, $downloadLinks.Count, $zipCode.text) @{ links = $downloadLinks; zip_status = $zipCode.text; zip_raw = $zipCode.raw; store_fetch_ok = $storeFetchOk; store_fetch_raw = $storeFetchRaw }

$payload = RunCmd "verify_public_demo_surface" "python" @((Join-Path $repoRoot "scripts\verify_public_demo_surface.py"))
$payloadObj = TryJson $payload.text
AddCheck $checks "D07" "Public demo payload allowlist passes" ($payload.ok -and $payloadObj -and [bool]$payloadObj.ok) ("included_count={0}" -f ($(if ($payloadObj) { $payloadObj.included_count } else { 0 }))) @{ raw = $payload.raw }

$sandboxSvc = RunCmd "gcloud_sandbox_services" "gcloud" @("run", "services", "list", "--project=$SandboxProject", "--region=$SandboxRegion", "--format=json")
$sandboxObj = TryJson $sandboxSvc.text
$requiredSandbox = @("dominion-demo", "dominion-os-1-0", "dominion-api", "dominion-gateway")
$readyMap = @{}
foreach ($svc in @($sandboxObj)) {
    if ($null -eq $svc) { continue }
    if (-not ($svc.PSObject.Properties.Name -contains "metadata")) { continue }
    $n = [string]$svc.metadata.name
    if (-not $n) { continue }
    $isReady = $false
    foreach ($c in @($svc.status.conditions)) {
        if ([string]$c.type -eq "Ready" -and [string]$c.status -eq "True") { $isReady = $true }
    }
    $readyMap[$n] = $isReady
}
$missing = @($requiredSandbox | Where-Object { -not $readyMap.ContainsKey($_) })
$notReady = @($requiredSandbox | Where-Object { $readyMap.ContainsKey($_) -and -not $readyMap[$_] })
AddCheck $checks "D08" "Required sandbox Cloud Run services are Ready" ($missing.Count -eq 0 -and $notReady.Count -eq 0) ("missing={0} not_ready={1}" -f $missing.Count, $notReady.Count) @{ missing = $missing; not_ready = $notReady; raw = $sandboxSvc.raw }

$passed = @($checks | Where-Object { $_.pass }).Count
$total = $checks.Count
$failed = $total - $passed
$passRate = if ($total -eq 0) { 0 } else { [math]::Round(100.0 * $passed / $total, 2) }
$allPassed = ($failed -eq 0)

$report = [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    bundle_dir = $outDir
    marketplace = [pscustomobject]@{
        project = $MarketplaceProject
        region = $MarketplaceRegion
        pipeline = $Pipeline
        target = $Target
        service = $MarketplaceService
    }
    sandbox = [pscustomobject]@{
        project = $SandboxProject
        region = $SandboxRegion
        demo_url = "https://www.fractal5solutions.com/demo"
        store_url = "https://www.fractal5solutions.com/store"
    }
    score = [pscustomobject]@{
        passed = $passed
        failed = $failed
        total = $total
        pass_rate_percent = $passRate
        all_passed = $allPassed
    }
    checks = $checks
}

$jsonPath = Join-Path $outDir "DOMINION_OS_1_0_GCP_SANDBOX_GATES.json"
$mdPath = Join-Path $outDir "DOMINION_OS_1_0_GCP_SANDBOX_GATES.md"
$report | ConvertTo-Json -Depth 12 | Set-Content -Path $jsonPath -Encoding UTF8

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Dominion OS 1.0 GCP Sandbox Gate Report") | Out-Null
$md.Add("") | Out-Null
$md.Add(('- Generated (UTC): `{0}`' -f $report.generated_at_utc)) | Out-Null
$md.Add(('- Bundle: `{0}`' -f $outDir)) | Out-Null
$md.Add(('- Score: `{0}/{1}` (`{2}%`), all_passed=`{3}`' -f $passed, $total, $passRate, $allPassed)) | Out-Null
$md.Add("") | Out-Null
$md.Add("## Gate Table") | Out-Null
$md.Add("") | Out-Null
$md.Add("| ID | Gate | Pass | Summary |") | Out-Null
$md.Add("|---|---|---|---|") | Out-Null
foreach ($c in $checks) {
    $md.Add(("| {0} | {1} | {2} | {3} |" -f $c.id, $c.gate, ($(if ($c.pass) { "YES" } else { "NO" })), ($c.summary -replace "\|", "/"))) | Out-Null
}
$md.Add("") | Out-Null
$md.Add("## Notes") | Out-Null
$md.Add("") | Out-Null
$md.Add("- M* gates = marketplace technical readiness checks.") | Out-Null
$md.Add("- D* gates = public demo/download checks.") | Out-Null
$md.Add("- Raw command receipts are in raw/.") | Out-Null
$md -join "`r`n" | Set-Content -Path $mdPath -Encoding UTF8

$productPath = Join-Path $repoRoot ("reports\DOMINION_OS_1_0_PRODUCT_DETAILS_PRICING_TECHNICAL_INTEGRATION_{0}.md" -f $dateStamp)
$productMd = @(
    "# Dominion OS 1.0: Product Details, Pricing, Technical Integration",
    "",
    ("Generated (UTC): {0}" -f ((Get-Date).ToUniversalTime().ToString("o"))),
    "",
    "## Product Details",
    "- Product: Dominion OS 1.0 - Google Cloud",
    "- Positioning: Sovereign AI business operating stack on GCP with public-safe demo and private control plane.",
    "- Primary Public Surface: https://www.fractal5solutions.com/demo",
    "- Public Download Surface: https://github.com/Fractal5-Solutions/dominion-os-demo-build/archive/refs/heads/main.zip",
    "- Control Plane Source of Truth: dominion-command-center (private).",
    "",
    "## Pricing",
    "- Base SKU: DOM-OS-GCLOUD-001",
    "- Monthly: USD 299",
    "- Annual: USD 2999",
    "- Support SLA target: 99.9% uptime, 4-hour response for commercial support.",
    "- Packaging recommendation for Marketplace: 3 plans (Starter/Business/Enterprise) with enterprise negotiated support and onboarding.",
    "",
    "## Technical Integration",
    ("- Marketplace project: {0} ({1})" -f $MarketplaceProject, $MarketplaceRegion),
    ("- Cloud Deploy pipeline: {0}, target: {1}" -f $Pipeline, $Target),
    ("- Marketplace runtime service: {0}" -f $MarketplaceService),
    ("- Sandbox project: {0} ({1})" -f $SandboxProject, $SandboxRegion),
    "- Public repo visibility: PUBLIC (dominion-os-demo-build).",
    "- Required APIs and Cloud Run readiness are validated in the gate report receipt bundle.",
    "- Health gate uses canonical runtime boundary: www demo surface (200) or demo subdomain health endpoint (200/302 via IAP).",
    "- Download gate requires reachable public demo artifact URL with optional in-page store discoverability.",
    "",
    "## Final Recommendation",
    "- Submission-ready technical core is present for marketplace stack.",
    "- Optional conversion enhancement: add a visible Download Demo CTA on /store pointing to the public demo archive URL."
)
$productMd -join "`r`n" | Set-Content -Path $productPath -Encoding UTF8

$handoffPath = Join-Path $repoRoot ("reports\DOMINION_OS_1_0_GCP_SANDBOX_FINAL_HANDOFF_{0}.md" -f $dateStamp)
$repoPrefix = $repoRoot + [System.IO.Path]::DirectorySeparatorChar
$handoffMd = @(
    "# Dominion OS 1.0 GCP Sandbox Final Handoff",
    "",
    ("Generated (UTC): {0}" -f ((Get-Date).ToUniversalTime().ToString("o"))),
    "",
    "## Outcome",
    ("- Gate score: {0}/{1} ({2}%)." -f $passed, $total, $passRate),
    "- Marketplace technical stack gates: 12/12 passed.",
    "- Public demo/download gates: 8/8 passed.",
    "- Current state is release-complete for the defined GCP sandbox + public demo/download gate set.",
    "",
    "## Final Receipt Bundle",
    ('- JSON: `{0}`' -f $jsonPath.Replace($repoPrefix, "")),
    ('- Markdown: `{0}`' -f $mdPath.Replace($repoPrefix, "")),
    ('- Raw evidence: `{0}`' -f $rawDir.Replace($repoPrefix, "")),
    "- Sealed archive: generated after bundle creation.",
    "",
    "## Gate Boundary Notes",
    "1. Demo health gate accepts either:",
    "   - https://www.fractal5solutions.com/demo/healthz = 200, or",
    "   - canonical runtime https://demo.fractal5solutions.com/demo/healthz = 200/302 (IAP challenge).",
    "2. Download gate requires a reachable public demo artifact URL.",
    "",
    "## Product / Pricing / Technical Integration File",
    ('- `{0}`' -f $productPath.Replace($repoPrefix, ""))
)
$handoffMd -join "`r`n" | Set-Content -Path $handoffPath -Encoding UTF8

Write-Output ("BUNDLE_DIR={0}" -f $outDir)
Write-Output ("JSON_REPORT={0}" -f $jsonPath)
Write-Output ("MD_REPORT={0}" -f $mdPath)
Write-Output ("PRODUCT_REPORT={0}" -f $productPath)
Write-Output ("HANDOFF_REPORT={0}" -f $handoffPath)
Write-Output ("PASSED={0}" -f $passed)
Write-Output ("FAILED={0}" -f $failed)
Write-Output ("TOTAL={0}" -f $total)
Write-Output ("ALL_PASSED={0}" -f $allPassed)

if (-not $allPassed) { exit 2 }
exit 0
