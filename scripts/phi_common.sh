#!/bin/bash
# PHI Common Utilities Library
# Source this file in scripts for consistent functions and styling
# Usage: source "$(dirname "$0")/phi_common.sh"

# Exit on any error
set -euo pipefail

# ============================================================================
# COLOR DEFINITIONS
# ============================================================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Get script name without path
SCRIPT_NAME=$(basename "${BASH_SOURCE[1]}")

# Log with timestamp
log() {
    echo -e "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] $1"
}

# Log to file and stdout
log_file() {
    local message="$1"
    local log_file="${2:-/tmp/phi.log}"
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] [$SCRIPT_NAME] $message" | tee -a "$log_file"
}

# Success message
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Warning message
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Error message
error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

# Info message
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Debug message (only if DEBUG=true)
debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "${CYAN}[DEBUG] $1${NC}"
    fi
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

# Setup error trap
setup_error_trap() {
    trap 'handle_error $? $LINENO' ERR
}

# Error handler
handle_error() {
    local exit_code=$1
    local line_number=$2
    error "Script failed at line $line_number with exit code $exit_code"
    exit "$exit_code"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Require command or exit
require_command() {
    if ! command_exists "$1"; then
        error "Required command not found: $1"
        exit 1
    fi
}

# Check if GCP is authenticated
check_gcp_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
        error "GCP authentication required. Run: gcloud auth login"
        return 1
    fi
    return 0
}

# Verify environment variable is set
require_env() {
    local var_name="$1"
    if [ -z "${!var_name:-}" ]; then
        error "Required environment variable not set: $var_name"
        exit 1
    fi
}

# ============================================================================
# GCP HELPER FUNCTIONS
# ============================================================================

# Get current GCP project
get_current_project() {
    gcloud config get-value project 2>/dev/null || echo ""
}

# Set GCP project safely
set_project() {
    local project="$1"
    gcloud config set project "$project" --quiet 2>&1 | grep -v environment || true
}

# Get Cloud Run service URL
get_service_url() {
    local service_name="$1"
    local project="${2:-$(get_current_project)}"
    local region="${3:-us-central1}"

    gcloud run services describe "$service_name" \
        --project="$project" \
        --region="$region" \
        --format="value(status.url)" 2>/dev/null || echo ""
}

# ============================================================================
# BANNER FUNCTIONS
# ============================================================================

# Print centered banner
print_banner() {
    local text="$1"
    local width="${2:-70}"
    local border_char="${3:-=}"

    echo ""
    printf "%${width}s\n" | tr ' ' "$border_char"
    printf "%*s\n" $(((${#text} + width) / 2)) "$text"
    printf "%${width}s\n" | tr ' ' "$border_char"
    echo ""
}

# Print simple header
print_header() {
    local text="$1"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$text${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        debug "Created directory: $dir"
    fi
}

# Backup file with timestamp
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d-%H%M%S)"
        cp "$file" "$backup"
        info "Backup created: $backup"
        echo "$backup"
    fi
}

# Wait with spinner
wait_with_spinner() {
    local pid=$1
    local message="${2:-Processing}"
    local delay=0.1
    local spinstr='|/-\'

    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c] %s" "$spinstr" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "    \r"
}

# Confirm action
confirm() {
    local message="${1:-Are you sure?}"
    local default="${2:-n}"

    if [ "$default" = "y" ]; then
        local prompt="$message [Y/n]: "
    else
        local prompt="$message [y/N]: "
    fi

    read -p "$prompt" -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]] || ([ -z "$REPLY" ] && [ "$default" = "y" ]); then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# TELEMETRY FUNCTIONS
# ============================================================================

# Write to telemetry file
write_telemetry() {
    local key="$1"
    local value="$2"
    local telemetry_dir="${TELEMETRY_DIR:-/workspaces/dominion-os-demo-build/telemetry}"
    local telemetry_file="$telemetry_dir/$(date +%Y%m%d).json"

    ensure_dir "$telemetry_dir"

    # Append to daily telemetry file
    echo "{\"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\", \"key\": \"$key\", \"value\": \"$value\"}" >> "$telemetry_file"
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Setup error handling
setup_error_trap

# Print debug info if DEBUG=true
debug "PHI Common Utilities loaded"
debug "Script: $SCRIPT_NAME"
debug "PID: $$"
