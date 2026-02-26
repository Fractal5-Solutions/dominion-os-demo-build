#!/bin/bash
# PHI GCloud PAT Manager
# Stores and retrieves GitHub PAT from GCloud Secrets Manager
# Integrates with autonomous sync infrastructure

set -euo pipefail

PROJECT_ID="${GCLOUD_PROJECT:-dominion-core-prod}"
SECRET_NAME="github-pat"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════════════════"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Command: store
store_pat() {
    print_header "🔐 STORE GITHUB PAT IN GCLOUD SECRETS"

    echo "This will store your GitHub PAT securely in GCloud Secrets Manager"
    echo ""
    echo "Requirements:"
    echo "  • GitHub PAT (Classic or Fine-grained)"
    echo "  • Scopes: repo, workflow"
    echo "  • GCloud authentication (already done ✓)"
    echo ""

    # Check if secret already exists
    if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
        print_warning "Secret '$SECRET_NAME' already exists"
        echo ""
        read -p "Overwrite with new version? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            exit 0
        fi
    fi

    echo ""
    echo "Enter your GitHub PAT (input hidden):"
    read -s PAT_TOKEN
    echo ""

    # Validate token format
    if [[ "$PAT_TOKEN" =~ ^ghp_ ]] || [[ "$PAT_TOKEN" =~ ^github_pat_ ]]; then
        print_info "Token format validated: ${PAT_TOKEN:0:15}***"
    else
        print_error "Unrecognized token format (expected ghp_* or github_pat_*)"
        read -p "Continue anyway? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    echo ""
    print_info "Storing in GCloud Secrets Manager..."

    # Create or update secret
    if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
        # Add new version
        echo -n "$PAT_TOKEN" | gcloud secrets versions add "$SECRET_NAME" \
            --project="$PROJECT_ID" \
            --data-file=- 2>/dev/null
    else
        # Create new secret
        echo -n "$PAT_TOKEN" | gcloud secrets create "$SECRET_NAME" \
            --project="$PROJECT_ID" \
            --replication-policy="automatic" \
            --data-file=- 2>/dev/null
    fi

    if [ $? -eq 0 ]; then
        print_success "PAT stored successfully in GCloud Secrets"
        echo ""
        echo "Details:"
        echo "  • Project: $PROJECT_ID"
        echo "  • Secret: $SECRET_NAME"
        echo "  • Version: $(gcloud secrets versions list "$SECRET_NAME" --project="$PROJECT_ID" --limit=1 --format="value(name)" 2>/dev/null)"
        echo ""
        print_info "Run './scripts/phi_gcloud_pat_manager.sh retrieve' to use it"
    else
        print_error "Failed to store PAT in GCloud Secrets"
        exit 1
    fi
}

# Command: retrieve
retrieve_pat() {
    print_header "📥 RETRIEVE GITHUB PAT FROM GCLOUD SECRETS"

    # Check if secret exists
    if ! gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
        print_error "Secret '$SECRET_NAME' not found in project '$PROJECT_ID'"
        echo ""
        echo "Available secrets:"
        gcloud secrets list --project="$PROJECT_ID" --format="value(name)" 2>/dev/null || true
        echo ""
        print_info "Run './scripts/phi_gcloud_pat_manager.sh store' to create it"
        exit 1
    fi

    print_info "Retrieving PAT from GCloud Secrets..."

    # Retrieve latest version
    PAT_TOKEN=$(gcloud secrets versions access latest \
        --secret="$SECRET_NAME" \
        --project="$PROJECT_ID" 2>/dev/null)

    if [ -z "$PAT_TOKEN" ]; then
        print_error "Failed to retrieve PAT from GCloud Secrets"
        exit 1
    fi

    print_success "PAT retrieved successfully"
    echo ""
    echo "Token prefix: ${PAT_TOKEN:0:15}***"
    echo "Token length: ${#PAT_TOKEN} characters"
    echo ""

    # Configure using PHI automation
    print_info "Configuring with PHI automation..."
    echo ""

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/configure_pat.sh" ]; then
        "$SCRIPT_DIR/configure_pat.sh" "$PAT_TOKEN"
    else
        print_error "configure_pat.sh not found"
        echo "Manual configuration:"
        echo "  export GITHUB_TOKEN='$PAT_TOKEN'"
        exit 1
    fi
}

# Command: status
check_status() {
    print_header "📊 GCLOUD SECRETS STATUS"

    echo "Project: $PROJECT_ID"
    echo "Account: $(gcloud config get-value account 2>/dev/null || echo 'Not set')"
    echo ""

    if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
        print_success "GitHub PAT secret exists"
        echo ""
        echo "Details:"
        gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" --format="table(name,createTime)" 2>/dev/null
        echo ""
        echo "Versions:"
        gcloud secrets versions list "$SECRET_NAME" --project="$PROJECT_ID" --format="table(name,state,createTime)" --limit=5 2>/dev/null
    else
        print_warning "GitHub PAT secret not found"
        echo ""
        print_info "Run './scripts/phi_gcloud_pat_manager.sh store' to create it"
    fi

    echo ""
    echo "All secrets in project:"
    gcloud secrets list --project="$PROJECT_ID" --format="table(name,createTime)" 2>/dev/null || true
}

# Command: auto-configure
auto_configure() {
    print_header "⚡ AUTO-CONFIGURE FROM GCLOUD SECRETS"

    echo "This will:"
    echo "  1. Retrieve PAT from GCloud Secrets"
    echo "  2. Configure git credentials globally"
    echo "  3. Enable autonomous push for all repositories"
    echo ""

    # Check if secret exists
    if ! gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
        print_error "No GitHub PAT found in GCloud Secrets"
        echo ""
        print_info "Setup required:"
        echo ""
        echo "1. Generate PAT: https://github.com/settings/tokens/new"
        echo "   Scopes: repo, workflow"
        echo ""
        echo "2. Store in GCloud:"
        echo "   ./scripts/phi_gcloud_pat_manager.sh store"
        echo ""
        echo "3. Re-run auto-configure"
        exit 1
    fi

    # Retrieve and configure
    retrieve_pat

    echo ""
    print_header "✅ AUTO-CONFIGURATION COMPLETE"

    echo "GitHub PAT configured from GCloud Secrets"
    echo ""
    echo "Current status:"
    echo "  • Token: Retrieved from $SECRET_NAME"
    echo "  • Scope: All 24 repositories"
    echo "  • Multi-repo monitor: Will detect within 60s"
    echo ""
    print_success "Autonomous push enabled!"
}

# Main
case "${1:-help}" in
    store)
        store_pat
        ;;
    retrieve)
        retrieve_pat
        ;;
    status)
        check_status
        ;;
    auto|auto-configure)
        auto_configure
        ;;
    help|--help|-h|*)
        print_header "🎯 PHI GCLOUD PAT MANAGER"

        echo "Manage GitHub PAT in GCloud Secrets Manager"
        echo ""
        echo "Commands:"
        echo "  store          Store new GitHub PAT in GCloud Secrets"
        echo "  retrieve       Retrieve and configure PAT from GCloud"
        echo "  auto-configure Retrieve and configure automatically"
        echo "  status         Check GCloud Secrets status"
        echo "  help           Show this help"
        echo ""
        echo "Examples:"
        echo "  # Store PAT in GCloud (one-time setup)"
        echo "  ./scripts/phi_gcloud_pat_manager.sh store"
        echo ""
        echo "  # Retrieve and configure PAT"
        echo "  ./scripts/phi_gcloud_pat_manager.sh auto-configure"
        echo ""
        echo "  # Check status"
        echo "  ./scripts/phi_gcloud_pat_manager.sh status"
        echo ""
        echo "Project: $PROJECT_ID"
        echo "Secret: $SECRET_NAME"
        ;;
esac
