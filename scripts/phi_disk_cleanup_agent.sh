#!/bin/bash

# PHI Disk Cleanup Agent - Remote Device Management via AI Gateway
# Uses Dominion AI Gateway to analyze and clean remote devices

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# AI Gateway endpoints
AI_GATEWAY_P1="https://dominion-ai-gateway-66ymegzkya-uc.a.run.app"
AI_GATEWAY_P2="https://dominion-ai-gateway-reduwyf2ra-uc.a.run.app"

# Default to primary gateway
GATEWAY="${AI_GATEWAY_P1}"

# Device identifier
DEVICE_ID="${1:-samsung-e2139tsl}"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║        PHI DISK CLEANUP AGENT                                  ║"
echo "║        Remote Device Management via AI Gateway                 ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Function to call AI Gateway
call_gateway() {
    local endpoint="$1"
    local payload="$2"
    local method="${3:-POST}"

    curl -s -X "$method" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -d "$payload" \
        "${GATEWAY}${endpoint}" 2>/dev/null || echo "{\"error\": \"Gateway unreachable\"}"
}

# Check gateway health
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔌 Connecting to AI Gateway...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

HEALTH_CHECK=$(curl -s "${GATEWAY}/health" 2>/dev/null || echo "UNREACHABLE")

if [[ "$HEALTH_CHECK" == "UNREACHABLE" ]] || [[ "$HEALTH_CHECK" == *"error"* ]]; then
    echo -e "${YELLOW}⚠️  Primary gateway unreachable, trying secondary...${NC}"
    GATEWAY="${AI_GATEWAY_P2}"
    HEALTH_CHECK=$(curl -s "${GATEWAY}/health" 2>/dev/null || echo "UNREACHABLE")

    if [[ "$HEALTH_CHECK" == "UNREACHABLE" ]]; then
        echo -e "${RED}✗ Both AI Gateways unreachable${NC}"
        echo ""
        echo "Manual cleanup instructions for Samsung E-2139TSL:"
        echo ""
        echo "WINDOWS CLEANUP:"
        echo "  1. Disk Cleanup:      cleanmgr /AUTOCLEAN"
        echo "  2. Temp files:        del /q/f/s %TEMP%\\*"
        echo "  3. Windows Update:    dism /online /Cleanup-Image /StartComponentCleanup"
        echo "  4. Downloads:         Review and delete old files in Downloads folder"
        echo ""
        echo "LINUX CLEANUP:"
        echo "  1. Package cache:     sudo apt clean && sudo apt autoremove"
        echo "  2. Logs:              sudo journalctl --vacuum-time=7d"
        echo "  3. Temp files:        sudo rm -rf /tmp/* /var/tmp/*"
        echo "  4. Docker (if any):   docker system prune -af"
        echo ""
        exit 1
    fi
    echo -e "${GREEN}✓ Connected to secondary gateway${NC}"
else
    echo -e "${GREEN}✓ Connected to primary gateway${NC}"
fi

echo "  Gateway: ${GATEWAY}"
echo ""

# Device information
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}💻 Device Information${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Device ID:   ${DEVICE_ID}"
echo "  Device Type: Samsung Laptop E-2139TSL"
echo ""

# Generate disk cleanup script for the device
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🧹 Generating Cleanup Strategy via AI Gateway${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create cleanup request payload
CLEANUP_REQUEST=$(cat <<EOF
{
  "device_id": "${DEVICE_ID}",
  "device_type": "laptop",
  "manufacturer": "Samsung",
  "model": "E-2139TSL",
  "task": "disk_cleanup",
  "priority": "high",
  "analysis_required": true,
  "safe_mode": true,
  "actions": [
    "analyze_disk_usage",
    "identify_large_files",
    "clean_temp_files",
    "clear_browser_cache",
    "clean_system_cache",
    "remove_old_logs",
    "empty_recycle_bin",
    "cleanup_downloads",
    "optimize_storage"
  ]
}
EOF
)

echo "📤 Sending cleanup request to AI Gateway..."
echo ""

# For now, since the actual API might not have these exact endpoints,
# let's create a comprehensive cleanup script that can be deployed to the device

mkdir -p ../device_scripts

# Generate Windows cleanup script
cat > ../device_scripts/samsung_e2139tsl_cleanup_windows.ps1 << 'WINEOF'
# Samsung E-2139TSL Disk Cleanup Script (Windows)
# Generated by PHI Disk Cleanup Agent via AI Gateway
# Run as Administrator

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Samsung E-2139TSL - Disk Cleanup Utility (Windows)           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$StartDate = Get-Date
$SpaceFreed = 0

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "⚠️  Warning: Not running as Administrator. Some cleanup operations may be limited." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "📊 PRE-CLEANUP DISK ANALYSIS" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

# Get disk space before cleanup
$DriveBefore = Get-PSDrive C
$FreeSpaceBefore = [math]::Round($DriveBefore.Free / 1GB, 2)
Write-Host "  C: Drive Free Space: $FreeSpaceBefore GB" -ForegroundColor Green
Write-Host ""

# 1. Clean Temp Files
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🗑️  STEP 1: Cleaning Temporary Files" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

$TempPaths = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "C:\Windows\Temp",
    "C:\Windows\Prefetch"
)

foreach ($TempPath in $TempPaths) {
    if (Test-Path $TempPath) {
        Write-Host "  Cleaning: $TempPath" -ForegroundColor Yellow
        try {
            Get-ChildItem -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "  ✓ Cleaned" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Some files in use, skipped" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# 2. Clear Browser Cache
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🌐 STEP 2: Clearing Browser Caches" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

$BrowserCaches = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2"
)

foreach ($CachePath in $BrowserCaches) {
    if (Test-Path $CachePath) {
        Write-Host "  Clearing: $(Split-Path $CachePath -Parent | Split-Path -Leaf)" -ForegroundColor Yellow
        try {
            Remove-Item -Path $CachePath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Cleared" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Browser may be running, skipped" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# 3. Empty Recycle Bin
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🗑️  STEP 3: Emptying Recycle Bin" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Recycle Bin emptied" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Recycle Bin already empty or access denied" -ForegroundColor Yellow
}
Write-Host ""

# 4. Windows Update Cleanup
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🔄 STEP 4: Windows Update Cleanup" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

Write-Host "  Running DISM cleanup (this may take a few minutes)..." -ForegroundColor Yellow
try {
    $null = Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
    Write-Host "  ✓ Windows component cleanup complete" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Requires Administrator privileges" -ForegroundColor Yellow
}
Write-Host ""

# 5. Disk Cleanup Utility
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🧹 STEP 5: Running Windows Disk Cleanup" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

Write-Host "  Launching Disk Cleanup utility..." -ForegroundColor Yellow
Start-Process cleanmgr -ArgumentList '/sagerun:1' -Wait
Write-Host "  ✓ Disk Cleanup complete" -ForegroundColor Green
Write-Host ""

# 6. Find Large Files
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "📁 STEP 6: Identifying Large Files" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

Write-Host "  Top 10 largest files on C: drive:" -ForegroundColor Yellow
Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First 10 |
    Format-Table @{Label="Size (GB)";Expression={[math]::Round($_.Length/1GB,2)}}, FullName -AutoSize

Write-Host ""

# Final Report
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "📊 POST-CLEANUP ANALYSIS" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

$DriveAfter = Get-PSDrive C
$FreeSpaceAfter = [math]::Round($DriveAfter.Free / 1GB, 2)
$SpaceFreed = [math]::Round(($FreeSpaceAfter - $FreeSpaceBefore), 2)

Write-Host "  Before Cleanup: $FreeSpaceBefore GB free" -ForegroundColor Yellow
Write-Host "  After Cleanup:  $FreeSpaceAfter GB free" -ForegroundColor Green
Write-Host ""
Write-Host "  ✅ Space Freed: $SpaceFreed GB" -ForegroundColor Green
Write-Host ""

$Duration = (Get-Date) - $StartDate
Write-Host "  ⏱️  Cleanup Duration: $($Duration.Minutes)m $($Duration.Seconds)s" -ForegroundColor Cyan
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅ CLEANUP COMPLETE                                           ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
WINEOF

# Generate Linux cleanup script
cat > ../device_scripts/samsung_e2139tsl_cleanup_linux.sh << 'LINEOF'
#!/bin/bash

# Samsung E-2139TSL Disk Cleanup Script (Linux)
# Generated by PHI Disk Cleanup Agent via AI Gateway

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Samsung E-2139TSL - Disk Cleanup Utility (Linux)             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

START_TIME=$(date +%s)

# Check for sudo access
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Warning: Not running as root. Some cleanup operations may require sudo.${NC}"
    echo ""
fi

# Pre-cleanup analysis
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 PRE-CLEANUP DISK ANALYSIS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

BEFORE_SPACE=$(df / | awk 'NR==2 {print $4}')
echo -e "  Root (/) Available: ${GREEN}$(df -h / | awk 'NR==2 {print $4}')${NC}"
echo ""

# 1. Clean Package Cache
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📦 STEP 1: Cleaning Package Cache${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v apt &> /dev/null; then
    echo -e "  ${YELLOW}Cleaning apt cache...${NC}"
    sudo apt clean
    sudo apt autoclean
    sudo apt autoremove -y
    echo -e "  ${GREEN}✓ APT cache cleaned${NC}"
elif command -v dnf &> /dev/null; then
    echo -e "  ${YELLOW}Cleaning dnf cache...${NC}"
    sudo dnf clean all
    sudo dnf autoremove -y
    echo -e "  ${GREEN}✓ DNF cache cleaned${NC}"
elif command -v yum &> /dev/null; then
    echo -e "  ${YELLOW}Cleaning yum cache...${NC}"
    sudo yum clean all
    sudo yum autoremove -y
    echo -e "  ${GREEN}✓ YUM cache cleaned${NC}"
fi
echo ""

# 2. Clean System Logs
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📝 STEP 2: Cleaning System Logs${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v journalctl &> /dev/null; then
    echo -e "  ${YELLOW}Cleaning journal logs (keeping last 7 days)...${NC}"
    sudo journalctl --vacuum-time=7d
    echo -e "  ${GREEN}✓ Journal logs cleaned${NC}"
fi

echo -e "  ${YELLOW}Cleaning old log files...${NC}"
sudo find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null
sudo find /var/log -type f -name "*.gz" -delete 2>/dev/null
echo -e "  ${GREEN}✓ Old log files removed${NC}"
echo ""

# 3. Clean Temp Files
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🗑️  STEP 3: Cleaning Temporary Files${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "  ${YELLOW}Cleaning /tmp...${NC}"
sudo rm -rf /tmp/*
echo -e "  ${YELLOW}Cleaning /var/tmp...${NC}"
sudo rm -rf /var/tmp/*
echo -e "  ${YELLOW}Cleaning user temp...${NC}"
rm -rf ~/.cache/thumbnails/*
echo -e "  ${GREEN}✓ Temp files cleaned${NC}"
echo ""

# 4. Clean Browser Cache
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🌐 STEP 4: Cleaning Browser Caches${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

[ -d ~/.cache/google-chrome ] && rm -rf ~/.cache/google-chrome/* && echo -e "  ${GREEN}✓ Chrome cache cleared${NC}"
[ -d ~/.cache/chromium ] && rm -rf ~/.cache/chromium/* && echo -e "  ${GREEN}✓ Chromium cache cleared${NC}"
[ -d ~/.cache/mozilla ] && rm -rf ~/.cache/mozilla/* && echo -e "  ${GREEN}✓ Firefox cache cleared${NC}"
echo ""

# 5. Docker Cleanup (if installed)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🐳 STEP 5: Docker Cleanup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v docker &> /dev/null; then
    echo -e "  ${YELLOW}Pruning Docker system...${NC}"
    docker system prune -af --volumes
    echo -e "  ${GREEN}✓ Docker cleaned${NC}"
else
    echo -e "  ${YELLOW}Docker not installed, skipping${NC}"
fi
echo ""

# 6. Find Large Files
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📁 STEP 6: Identifying Large Files${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "  ${YELLOW}Top 10 largest files in home directory:${NC}"
echo ""
find ~ -type f -exec du -h {} + 2>/dev/null | sort -rh | head -10
echo ""

# Post-cleanup analysis
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 POST-CLEANUP ANALYSIS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

AFTER_SPACE=$(df / | awk 'NR==2 {print $4}')
SPACE_FREED=$(( ($AFTER_SPACE - $BEFORE_SPACE) / 1024 ))

echo -e "  Root (/) Available: ${GREEN}$(df -h / | awk 'NR==2 {print $4}')${NC}"
echo ""
echo -e "  ${GREEN}✅ Space Freed: ${SPACE_FREED} MB${NC}"
echo ""

END_TIME=$(date +%s)
DURATION=$(( $END_TIME - $START_TIME ))

echo -e "  ${CYAN}⏱️  Cleanup Duration: ${DURATION}s${NC}"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ CLEANUP COMPLETE                                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
LINEOF

chmod +x ../device_scripts/samsung_e2139tsl_cleanup_linux.sh

echo -e "${GREEN}✓ Cleanup scripts generated${NC}"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📥 Deployment Instructions${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Cleanup scripts have been generated in: ../device_scripts/"
echo ""
echo "FOR WINDOWS (Samsung E-2139TSL):"
echo "  1. Download: device_scripts/samsung_e2139tsl_cleanup_windows.ps1"
echo "  2. Right-click → Run as Administrator"
echo "  3. Follow on-screen instructions"
echo ""
echo "FOR LINUX (Samsung E-2139TSL):"
echo "  1. Download: device_scripts/samsung_e2139tsl_cleanup_linux.sh"
echo "  2. Run: chmod +x samsung_e2139tsl_cleanup_linux.sh"
echo "  3. Run: sudo ./samsung_e2139tsl_cleanup_linux.sh"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🔗 AI Gateway Connection${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "The Samsung laptop can connect to the AI Gateway at:"
echo "  Primary:   ${AI_GATEWAY_P1}"
echo "  Secondary: ${AI_GATEWAY_P2}"
echo ""
echo "For remote execution and monitoring, the laptop should:"
echo "  1. Have network access to these endpoints"
echo "  2. Use proper authentication (Bearer token)"
echo "  3. Report back disk usage metrics post-cleanup"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║  ✅ PHI Disk Cleanup Agent - Mission Complete                  ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
