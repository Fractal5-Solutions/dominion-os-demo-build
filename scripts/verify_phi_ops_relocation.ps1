[CmdletBinding()]
param(
    [string]$TargetRoot = 'D:\phi-ops',
    [string]$ReportPath,
    [switch]$InitializeContinuityLayout,
    [switch]$InitializeFullLayout
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-Array {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    if ($null -eq $InputObject) {
        return @()
    }

    return @($InputObject)
}

function Join-PortablePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$ChildPath
    )

    $trimmedBase = $BasePath.TrimEnd('\', '/')
    $normalizedChild = $ChildPath -replace '[\\/]+', '\'
    return [System.IO.Path]::Combine($trimmedBase, $normalizedChild)
}

function Get-DirectorySizeBytes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return 0
    }

    $items = Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue
    if (-not $items) {
        return 0
    }

    return ($items | Measure-Object -Property Length -Sum).Sum
}

function Get-PathRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            Path          = $Path
            Exists        = $false
            ItemType      = $null
            SizeBytes     = 0
            LastWriteTime = $null
        }
    }

    $item = Get-Item -LiteralPath $Path -Force
    $size = if ($item.PSIsContainer) { Get-DirectorySizeBytes -Path $Path } else { $item.Length }

    return [pscustomobject]@{
        Path          = $item.FullName
        Exists        = $true
        ItemType      = if ($item.PSIsContainer) { 'Directory' } else { 'File' }
        SizeBytes     = $size
        LastWriteTime = $item.LastWriteTime
    }
}

function Get-DriveRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriveLetter
    )

    try {
        $drive = Get-PSDrive -Name $DriveLetter -PSProvider FileSystem -ErrorAction Stop
        return [pscustomobject]@{
            Drive       = $drive.Name + ':'
            Root        = $drive.Root
            UsedGB      = [math]::Round($drive.Used / 1GB, 2)
            FreeGB      = [math]::Round($drive.Free / 1GB, 2)
            TotalGB     = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
            Exists      = $true
        }
    }
    catch {
        return [pscustomobject]@{
            Drive       = $DriveLetter + ':'
            Root        = $null
            UsedGB      = $null
            FreeGB      = $null
            TotalGB     = $null
            Exists      = $false
        }
    }
}

function Get-ResolvedMatches {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Patterns
    )

    $results = foreach ($pattern in $Patterns) {
        Get-ChildItem -Path $pattern -Force -ErrorAction SilentlyContinue
    }

    if (-not $results) {
        return @()
    }

    return $results | Sort-Object FullName -Unique
}

function Get-CandidateRecords {
    param(
        [object[]]$Items
    )

    $records = New-Object System.Collections.Generic.List[object]
    if ($null -eq $Items) {
        return @($records)
    }

    foreach ($item in $Items) {
        if ($null -ne $item -and $null -ne $item.FullName) {
            $records.Add((Get-PathRecord -Path $item.FullName))
        }
    }
    return @($records)
}

function Initialize-ContinuityLayout {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $folders = @(
        $Root,
        (Join-PortablePath $Root 'repos'),
        (Join-PortablePath $Root 'workspaces'),
        (Join-PortablePath $Root 'vscode'),
        (Join-PortablePath $Root 'backups'),
        (Join-PortablePath $Root 'exports'),
        (Join-PortablePath $Root 'logs'),
        (Join-PortablePath $Root 'temp'),
        (Join-PortablePath $Root 'continuity'),
        (Join-PortablePath $Root 'reports'),
        (Join-PortablePath $Root 'repos\dominion-os-demo-build'),
        (Join-PortablePath $Root 'repos\dominion-command-center')
    )

    foreach ($folder in $folders) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

function Get-RequiredRelativePaths {
    $rootPaths = @(
        '',
        'repos',
        'workspaces',
        'vscode',
        'backups',
        'exports',
        'logs',
        'temp',
        'continuity',
        'reports'
    )

    $repoPaths = @(
        'repos\dominion-os-demo-build',
        'repos\dominion-command-center'
    )

    $demoBuildPaths = @(
        'repos\dominion-os-demo-build\backups',
        'repos\dominion-os-demo-build\commercial',
        'repos\dominion-os-demo-build\command-center',
        'repos\dominion-os-demo-build\data',
        'repos\dominion-os-demo-build\demo',
        'repos\dominion-os-demo-build\deployments',
        'repos\dominion-os-demo-build\grafana-dashboards',
        'repos\dominion-os-demo-build\monitoring',
        'repos\dominion-os-demo-build\oauth_server',
        'repos\dominion-os-demo-build\orchestrator',
        'repos\dominion-os-demo-build\products',
        'repos\dominion-os-demo-build\reports',
        'repos\dominion-os-demo-build\scripts',
        'repos\dominion-os-demo-build\store',
        'repos\dominion-os-demo-build\systemd',
        'repos\dominion-os-demo-build\telemetry',
        'repos\dominion-os-demo-build\tests',
        'repos\dominion-os-demo-build\widget_service'
    )

    $commandCenterPaths = @(
        'repos\dominion-command-center\billing-service',
        'repos\dominion-command-center\chatgpt-gateway',
        'repos\dominion-command-center\demo',
        'repos\dominion-command-center\scripts',
        'repos\dominion-command-center\sidecar',
        'repos\dominion-command-center\src',
        'repos\dominion-command-center\web'
    )

    return @($rootPaths + $repoPaths + $demoBuildPaths + $commandCenterPaths)
}

function Initialize-FullLayout {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $paths = Get-RequiredRelativePaths
    foreach ($relativePath in $paths) {
        $targetPath = if ([string]::IsNullOrWhiteSpace($relativePath)) {
            $Root
        }
        else {
            Join-PortablePath $Root $relativePath
        }

        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    }
}

function Get-TargetIndicators {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        return [pscustomobject]@{
            GitDirs              = @()
            GitHubDirs           = @()
            VscodeDirs           = @()
            WorkspaceFiles       = @()
            DominionNamedFolders = @()
            RootChildren         = @()
        }
    }

    $allDirectories = Get-ChildItem -Path (Join-Path $Root '*') -Directory -Recurse -Force -ErrorAction SilentlyContinue
    $workspaceFiles = Get-ChildItem -Path (Join-Path $Root '*') -File -Recurse -Force -Filter '*.code-workspace' -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
    $gitDirs = $allDirectories |
        Where-Object { $_.Name -eq '.git' } |
        Select-Object -ExpandProperty FullName
    $githubDirs = $allDirectories |
        Where-Object { $_.Name -eq '.github' } |
        Select-Object -ExpandProperty FullName
    $vscodeDirs = $allDirectories |
        Where-Object { $_.Name -eq '.vscode' } |
        Select-Object -ExpandProperty FullName
    $dominionFolders = $allDirectories |
        Where-Object { $_.Name -like 'dominion*' -or $_.Name -like 'phi*' } |
        Select-Object -First 50 -ExpandProperty FullName

    $rootChildren = Get-ChildItem -LiteralPath $Root -Force -ErrorAction SilentlyContinue |
        Select-Object -First 20 -ExpandProperty FullName

    return [pscustomobject]@{
        GitDirs              = @($gitDirs)
        GitHubDirs           = @($githubDirs)
        VscodeDirs           = @($vscodeDirs)
        WorkspaceFiles       = @($workspaceFiles)
        DominionNamedFolders = @($dominionFolders)
        RootChildren         = @($rootChildren)
    }
}

function Get-SourceResidue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DriveLetter
    )

    $patterns = @(
        "$DriveLetter`:\Users\*\AppData\Roaming\Code",
        "$DriveLetter`:\Users\*\AppData\Roaming\Code - Insiders",
        "$DriveLetter`:\Users\*\AppData\Roaming\Code\User\workspaceStorage",
        "$DriveLetter`:\Users\*\AppData\Roaming\Code\CachedData",
        "$DriveLetter`:\Users\*\AppData\Roaming\Code\CachedExtensionVSIXs",
        "$DriveLetter`:\Users\*\AppData\Local\Programs\Microsoft VS Code",
        "$DriveLetter`:\Users\*\AppData\Local\Programs\Cursor",
        "$DriveLetter`:\Users\*\AppData\Local\Code",
        "$DriveLetter`:\Users\*\AppData\Local\Temp\vscode*",
        "$DriveLetter`:\Users\*\AppData\Local\Temp\code*",
        "$DriveLetter`:\Users\*\AppData\Local\GitHubDesktop",
        "$DriveLetter`:\Users\*\AppData\Roaming\GitHub Desktop",
        "$DriveLetter`:\Users\*\AppData\Local\GitHubCLI",
        "$DriveLetter`:\Users\*\AppData\Local\Programs\Git",
        "$DriveLetter`:\Users\*\AppData\Local\Microsoft\WinGet\Packages\Microsoft.VisualStudioCode*",
        "$DriveLetter`:\Users\*\source\repos",
        "$DriveLetter`:\Users\*\Documents\GitHub",
        "$DriveLetter`:\Users\*\Documents\GitRepos",
        "$DriveLetter`:\Users\*\Documents\GitHub Desktop",
        "$DriveLetter`:\Users\*\Desktop\GitHub*",
        "$DriveLetter`:\Users\*\Desktop\dominion*",
        "$DriveLetter`:\Users\*\Documents\dominion*",
        "$DriveLetter`:\Users\*\Downloads\GitHub*",
        "$DriveLetter`:\Users\*\Downloads\dominion*"
    )

    try {
        $matches = @(Get-ResolvedMatches -Patterns $patterns)
        return @(Get-CandidateRecords -Items $matches)
    }
    catch {
        return @()
    }
}

function Get-BackupEvidence {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $backupFolders = @(
        (Join-PortablePath $Root 'backup'),
        (Join-PortablePath $Root 'backups'),
        (Join-PortablePath $Root 'archive'),
        (Join-PortablePath $Root 'archives'),
        (Join-PortablePath $Root 'exports'),
        (Join-PortablePath $Root 'continuity')
    ) | Where-Object { Test-Path -LiteralPath $_ }

    $backupFiles = foreach ($folder in $backupFolders) {
        Get-ChildItem -LiteralPath $folder -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '\.(zip|7z|tar|gz|bak|vhd|vhdx)$' }
    }

    $latestBackup = $backupFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    return [pscustomobject]@{
        BackupFolders = @($backupFolders)
        BackupFileCount = @($backupFiles).Count
        LatestBackup = if ($latestBackup) { $latestBackup.FullName } else { $null }
        LatestBackupTime = if ($latestBackup) { $latestBackup.LastWriteTime } else { $null }
    }
}

function Resolve-FirstExistingPath {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $Candidates[0]
}

function Get-LayoutCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string[]]$Candidates,
        [string]$Kind = 'Directory'
    )

    $resolvedPath = Resolve-FirstExistingPath -Candidates $Candidates
    $record = Get-PathRecord -Path $resolvedPath
    $kindMatches = (-not $record.Exists) -or ($record.ItemType -eq $Kind)

    return [pscustomobject]@{
        Name = $Name
        Kind = $Kind
        Candidates = @($Candidates)
        Path = $record.Path
        Exists = ($record.Exists -and $kindMatches)
        ItemType = $record.ItemType
        SizeBytes = $record.SizeBytes
        LastWriteTime = $record.LastWriteTime
    }
}

function Get-RequiredLayout {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $checks = @(
        (Get-LayoutCheck -Name 'phi-ops root' -Candidates @($Root)),
        (Get-LayoutCheck -Name 'repos root' -Candidates @((Join-PortablePath $Root 'repos'))),
        (Get-LayoutCheck -Name 'workspaces root' -Candidates @((Join-PortablePath $Root 'workspaces'))),
        (Get-LayoutCheck -Name 'vscode root' -Candidates @((Join-PortablePath $Root 'vscode'))),
        (Get-LayoutCheck -Name 'backups root' -Candidates @((Join-PortablePath $Root 'backups'))),
        (Get-LayoutCheck -Name 'exports root' -Candidates @((Join-PortablePath $Root 'exports'))),
        (Get-LayoutCheck -Name 'logs root' -Candidates @((Join-PortablePath $Root 'logs'))),
        (Get-LayoutCheck -Name 'temp root' -Candidates @((Join-PortablePath $Root 'temp'))),
        (Get-LayoutCheck -Name 'continuity root' -Candidates @((Join-PortablePath $Root 'continuity'))),
        (Get-LayoutCheck -Name 'reports root' -Candidates @((Join-PortablePath $Root 'reports')))
    )

    $demoBuildRootCandidates = @(
        (Join-PortablePath $Root 'repos\dominion-os-demo-build'),
        (Join-PortablePath $Root 'workspaces\dominion-os-demo-build'),
        (Join-PortablePath $Root 'dominion-os-demo-build')
    )
    $commandCenterRootCandidates = @(
        (Join-PortablePath $Root 'repos\dominion-command-center'),
        (Join-PortablePath $Root 'workspaces\dominion-command-center'),
        (Join-PortablePath $Root 'dominion-command-center')
    )

    $checks += Get-LayoutCheck -Name 'dominion-os-demo-build repo' -Candidates $demoBuildRootCandidates
    $checks += Get-LayoutCheck -Name 'dominion-command-center repo' -Candidates $commandCenterRootCandidates

    $demoBuildRoot = Resolve-FirstExistingPath -Candidates $demoBuildRootCandidates
    $commandCenterRoot = Resolve-FirstExistingPath -Candidates $commandCenterRootCandidates

    $demoBuildRequiredDirs = @(
        'backups',
        'commercial',
        'command-center',
        'data',
        'demo',
        'deployments',
        'grafana-dashboards',
        'monitoring',
        'oauth_server',
        'orchestrator',
        'products',
        'reports',
        'scripts',
        'store',
        'systemd',
        'telemetry',
        'tests',
        'widget_service'
    )

    foreach ($dir in $demoBuildRequiredDirs) {
        $checks += Get-LayoutCheck -Name ("demo-build/" + $dir) -Candidates @((Join-PortablePath $demoBuildRoot $dir))
    }

    $demoBuildRequiredFiles = @(
        'command_core.py',
        'docker-compose.yml',
        'docker-compose.production.yml',
        'phi-sovereign-workspace.code-workspace',
        'requirements.txt'
    )

    foreach ($file in $demoBuildRequiredFiles) {
        $checks += Get-LayoutCheck -Name ("demo-build/" + $file) -Candidates @((Join-PortablePath $demoBuildRoot $file)) -Kind 'File'
    }

    $commandCenterRequiredDirs = @(
        'billing-service',
        'chatgpt-gateway',
        'demo',
        'scripts',
        'sidecar',
        'src',
        'web'
    )

    foreach ($dir in $commandCenterRequiredDirs) {
        $checks += Get-LayoutCheck -Name ("dominion-command-center/" + $dir) -Candidates @((Join-PortablePath $commandCenterRoot $dir))
    }

    $commandCenterRequiredFiles = @(
        'src\main.py',
        'billing-service\app.py',
        'sidecar\app.py',
        'chatgpt-gateway\main.py',
        'demo\app.py'
    )

    foreach ($file in $commandCenterRequiredFiles) {
        $checks += Get-LayoutCheck -Name ("dominion-command-center/" + $file.Replace('\', '/')) -Candidates @((Join-PortablePath $commandCenterRoot $file)) -Kind 'File'
    }

    $missing = @($checks | Where-Object { -not $_.Exists })

    return [pscustomobject]@{
        RequiredChecks = @($checks)
        MissingChecks = $missing
        MissingCount = @($missing).Count
        TotalCount = @($checks).Count
        Complete = (@($missing).Count -eq 0)
    }
}

function New-Recommendations {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$TargetExists,
        [Parameter(Mandatory = $true)]
        [int]$SourceResidueCount,
        [Parameter(Mandatory = $true)]
        [bool]$TargetLooksActive,
        [Parameter(Mandatory = $true)]
        [bool]$BackupsPresent,
        [Parameter(Mandatory = $true)]
        [int]$MissingLayoutCount
    )

    $recommendations = New-Object System.Collections.Generic.List[string]

    if (-not $TargetExists) {
        $recommendations.Add('Create or mount D:\phi-ops before attempting relocation verification.')
    }

    if (-not $TargetLooksActive) {
        $recommendations.Add('Move active repositories, .vscode folders, and workspace files into D:\phi-ops so the target is the primary live root.')
    }

    if ($SourceResidueCount -gt 0) {
        $recommendations.Add('Remove or archive VS Code, Git, GitHub, and Dominion artifacts still detected on C: after verifying their D:\phi-ops copies.')
    }

    if (-not $BackupsPresent) {
        $recommendations.Add('Create a backup/continuity layout under D:\phi-ops\backups and validate scheduled backups before cleaning C:.')
    }

    if ($MissingLayoutCount -gt 0) {
        $recommendations.Add('Populate D:\phi-ops with the required repos and subfolders for dominion-os-demo-build and dominion-command-center before treating D: as the complete live root.')
    }

    if ($recommendations.Count -eq 0) {
        $recommendations.Add('No obvious relocation blockers were detected by this audit.')
    }

    return $recommendations
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
if (-not $ReportPath) {
    $tempRoot = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
    $ReportPath = Join-Path $tempRoot "phi_ops_relocation_audit_$timestamp.json"
}

$targetDriveLetter = ($TargetRoot.Substring(0, 1)).ToUpperInvariant()
$sourceDriveLetter = 'C'

if ($InitializeContinuityLayout) {
    Initialize-ContinuityLayout -Root $TargetRoot
}

if ($InitializeFullLayout) {
    Initialize-FullLayout -Root $TargetRoot
}

$targetRootRecord = Get-PathRecord -Path $TargetRoot
$targetDrive = Get-DriveRecord -DriveLetter $targetDriveLetter
$sourceDrive = Get-DriveRecord -DriveLetter $sourceDriveLetter
$targetIndicators = Get-TargetIndicators -Root $TargetRoot
$sourceResidue = Get-SourceResidue -DriveLetter $sourceDriveLetter
$backupEvidence = Get-BackupEvidence -Root $TargetRoot
$requiredLayout = Get-RequiredLayout -Root $TargetRoot

$targetLooksActive = (
    @($targetIndicators.GitDirs).Count +
    @($targetIndicators.GitHubDirs).Count +
    @($targetIndicators.VscodeDirs).Count +
    @($targetIndicators.WorkspaceFiles).Count
) -gt 0

$backupsPresent = (@($backupEvidence.BackupFolders).Count -gt 0) -or ($backupEvidence.BackupFileCount -gt 0)

$overallStatus = if (-not $targetRootRecord.Exists -or -not $targetDrive.Exists) {
    'FAIL'
}
elseif (@($sourceResidue).Count -gt 0 -or -not $targetLooksActive -or -not $backupsPresent) {
    'WARN'
}
elseif (-not $requiredLayout.Complete) {
    'WARN'
}
else {
    'PASS'
}

$recommendations = New-Recommendations `
    -TargetExists:$targetRootRecord.Exists `
    -SourceResidueCount (@($sourceResidue).Count) `
    -TargetLooksActive:$targetLooksActive `
    -BackupsPresent:$backupsPresent `
    -MissingLayoutCount $requiredLayout.MissingCount

$report = [ordered]@{
    generated_at = (Get-Date).ToString('o')
    computer_name = $env:COMPUTERNAME
    user_name = $env:USERNAME
    overall_status = $overallStatus
    target_root = $TargetRoot
    checks = [ordered]@{
        target_drive = $targetDrive
        source_drive = $sourceDrive
        target_root = $targetRootRecord
        target_looks_active = $targetLooksActive
        source_residue_count = @($sourceResidue).Count
        backups_present = $backupsPresent
        required_layout_complete = $requiredLayout.Complete
        required_layout_missing_count = $requiredLayout.MissingCount
    }
    target_indicators = [ordered]@{
        git_dirs = @($targetIndicators.GitDirs)
        github_dirs = @($targetIndicators.GitHubDirs)
        vscode_dirs = @($targetIndicators.VscodeDirs)
        workspace_files = @($targetIndicators.WorkspaceFiles)
        dominion_named_folders = @($targetIndicators.DominionNamedFolders)
        root_children = @($targetIndicators.RootChildren)
    }
    source_residue = @($sourceResidue)
    backup_evidence = $backupEvidence
    required_layout = [ordered]@{
        complete = $requiredLayout.Complete
        total_checks = $requiredLayout.TotalCount
        missing_count = $requiredLayout.MissingCount
        checks = @($requiredLayout.RequiredChecks)
        missing = @($requiredLayout.MissingChecks)
    }
    recommendations = @($recommendations)
}

$reportDirectory = Split-Path -Parent $ReportPath
if ($reportDirectory -and -not (Test-Path -LiteralPath $reportDirectory)) {
    New-Item -ItemType Directory -Path $reportDirectory -Force | Out-Null
}

$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ReportPath -Encoding UTF8

Write-Host ''
Write-Host 'PHI Ops Relocation Audit'
Write-Host ('Status:            {0}' -f $overallStatus)
Write-Host ('Target root:       {0}' -f $TargetRoot)
Write-Host ('Target exists:     {0}' -f $targetRootRecord.Exists)
Write-Host ('Target looks live: {0}' -f $targetLooksActive)
Write-Host ('C: residue count:  {0}' -f @($sourceResidue).Count)
Write-Host ('Backups present:   {0}' -f $backupsPresent)
Write-Host ('Layout complete:   {0}' -f $requiredLayout.Complete)
Write-Host ('Missing folders:   {0}' -f $requiredLayout.MissingCount)
Write-Host ('Report:            {0}' -f $ReportPath)
Write-Host ''

if ($requiredLayout.MissingCount -gt 0) {
    Write-Host 'Missing D: layout items:'
    $requiredLayout.MissingChecks |
        Select-Object -First 25 |
        ForEach-Object {
            Write-Host (' - {0}: {1}' -f $_.Name, $_.Path)
        }
    Write-Host ''
}

if (@($sourceResidue).Count -gt 0) {
    Write-Host 'Top C: residue candidates:'
    $sourceResidue |
        Sort-Object SizeBytes -Descending |
        Select-Object -First 15 |
        ForEach-Object {
            Write-Host (' - {0} ({1} bytes)' -f $_.Path, $_.SizeBytes)
        }
    Write-Host ''
}

if (@($recommendations).Count -gt 0) {
    Write-Host 'Recommendations:'
    foreach ($recommendation in $recommendations) {
        Write-Host (' - {0}' -f $recommendation)
    }
}

if ($overallStatus -eq 'FAIL') {
    exit 2
}

if ($overallStatus -eq 'WARN') {
    exit 1
}

exit 0
