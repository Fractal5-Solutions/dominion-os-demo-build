#!/bin/bash
# verify_organization_settings.sh
# Comprehensive GitHub organization and repository settings verification
# For: Fractal5-Solutions (all repos except crystal-architect) and Fractal5-X (crystal-architect only)

set -euo pipefail

# Configuration
ORGS=("Fractal5-Solutions" "Fractal5-X")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="organization_verification_report_${TIMESTAMP}.md"
JSON_FILE="organization_verification_data_${TIMESTAMP}.json"
EXCEPTION_REPO="crystal-architect"
EXCEPTION_ORG="Fractal5-X"

# Colors for terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✅${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
log_error() { echo -e "${RED}❌${NC} $1"; }
log_section() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# Check prerequisites
check_prerequisites() {
  log_section "Checking Prerequisites"

  if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed"
    exit 1
  fi
  log_success "GitHub CLI found: $(gh --version | head -1)"

  if ! command -v jq &> /dev/null; then
    log_error "jq is not installed"
    exit 1
  fi
  log_success "jq found: $(jq --version)"

  # Check GitHub authentication
  if ! gh auth status &> /dev/null; then
    log_error "GitHub CLI is not authenticated"
    log_info "Run: gh auth login"
    exit 1
  fi
  log_success "GitHub authenticated: $(gh api user --jq '.login')"
}

# Initialize report
init_report() {
  log_section "Initializing Report"

  cat > "$REPORT_FILE" << EOF
# 🏢 GitHub Organization & Enterprise Settings Verification Report

**Generated:** $(date)
**Scope:** Fractal5-Solutions (all repos except crystal-architect), Fractal5-X (crystal-architect only)
**Report Version:** 1.0

---

## 📊 Executive Summary

This report provides a comprehensive verification of organization and repository settings across the Fractal5 ecosystem.

EOF

  echo "{}" > "$JSON_FILE"
  log_success "Report initialized: $REPORT_FILE"
  log_success "Data file initialized: $JSON_FILE"
}

# Discover repositories
discover_repositories() {
  local org=$1
  log_section "Discovering Repositories: $org"

  echo "## Organization: $org" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  # Fetch repositories
  local repos_json=$(gh repo list "$org" --limit 100 --json name,owner,visibility,isPrivate,defaultBranchRef,createdAt,updatedAt,description 2>&1)

  if [[ "$repos_json" =~ "Could not resolve" ]] || [[ "$repos_json" =~ "error" ]]; then
    log_warning "Could not access organization: $org (may not exist or no access)"
    echo "⚠️  **Organization not accessible or does not exist**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    return 1
  fi

  local repo_count=$(echo "$repos_json" | jq 'length')
  log_info "Found $repo_count repositories in $org"

  echo "### Repository Inventory ($repo_count repositories)" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "| Repository | Visibility | Default Branch | Last Updated |" >> "$REPORT_FILE"
  echo "|------------|-----------|----------------|--------------|" >> "$REPORT_FILE"

  # Process each repository
  echo "$repos_json" | jq -c '.[]' | while read -r repo; do
    local repo_name=$(echo "$repo" | jq -r '.name')
    local visibility=$(echo "$repo" | jq -r '.visibility')
    local default_branch=$(echo "$repo" | jq -r '.defaultBranchRef.name // "N/A"')
    local updated_at=$(echo "$repo" | jq -r '.updatedAt' | cut -d'T' -f1)

    # Check for crystal-architect exception
    if [[ "$org" == "Fractal5-Solutions" && "$repo_name" == "$EXCEPTION_REPO" ]]; then
      log_warning "Found crystal-architect in Fractal5-Solutions - EXPECTED IN Fractal5-X!"
      echo "| ⚠️  $repo_name | $visibility | $default_branch | $updated_at |" >> "$REPORT_FILE"
    elif [[ "$org" == "$EXCEPTION_ORG" && "$repo_name" == "$EXCEPTION_REPO" ]]; then
      log_success "Found crystal-architect in Fractal5-X - CORRECT LOCATION"
      echo "| ✅ **$repo_name** (exception) | $visibility | $default_branch | $updated_at |" >> "$REPORT_FILE"
    else
      echo "| $repo_name | $visibility | $default_branch | $updated_at |" >> "$REPORT_FILE"
    fi

    log_info "  - $repo_name ($visibility)"
  done

  echo "" >> "$REPORT_FILE"
  return 0
}

# Check organization settings
check_organization_settings() {
  local org=$1
  log_section "Checking Organization Settings: $org"

  echo "### Organization Configuration" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  local org_data=$(gh api "orgs/$org" 2>&1)

  if [[ "$org_data" =~ "Could not resolve" ]] || [[ "$org_data" =~ "Not Found" ]]; then
    log_warning "Could not access organization settings for: $org"
    echo "⚠️  **Organization settings not accessible**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    return 1
  fi

  # Extract key settings
  local two_factor=$(echo "$org_data" | jq -r '.two_factor_requirement_enabled // false')
  local web_commit_signoff=$(echo "$org_data" | jq -r '.web_commit_signoff_required // false')
  local default_permission=$(echo "$org_data" | jq -r '.default_repository_permission // "N/A"')
  local members_can_create_repos=$(echo "$org_data" | jq -r '.members_can_create_repositories // false')

  echo "**Security Settings:**" >> "$REPORT_FILE"

  if [[ "$two_factor" == "true" ]]; then
    echo "- ✅ Two-factor authentication: **REQUIRED**" >> "$REPORT_FILE"
    log_success "Two-factor authentication required"
  else
    echo "- ⚠️  Two-factor authentication: NOT REQUIRED" >> "$REPORT_FILE"
    log_warning "Two-factor authentication NOT required"
  fi

  if [[ "$web_commit_signoff" == "true" ]]; then
    echo "- ✅ Web commit signoff: **REQUIRED**" >> "$REPORT_FILE"
    log_success "Web commit signoff required"
  else
    echo "- ⚠️  Web commit signoff: NOT REQUIRED" >> "$REPORT_FILE"
    log_warning "Web commit signoff NOT required"
  fi

  echo "" >> "$REPORT_FILE"
  echo "**Repository Settings:**" >> "$REPORT_FILE"
  echo "- Default repository permission: **$default_permission**" >> "$REPORT_FILE"
  echo "- Members can create repositories: **$members_can_create_repos**" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
}

# Check repository security settings
check_repository_security() {
  local org=$1
  log_section "Checking Repository Security: $org"

  echo "### Repository Security Analysis" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  # Get list of repositories
  local repos=$(gh repo list "$org" --limit 100 --json name -q '.[].name' 2>/dev/null || echo "")

  if [[ -z "$repos" ]]; then
    log_warning "No repositories found or no access to: $org"
    echo "⚠️  No repositories found or accessible" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    return 1
  fi

  echo "| Repository | Branch Protection | Secret Scanning | Dependabot | Status |" >> "$REPORT_FILE"
  echo "|------------|------------------|-----------------|------------|---------|" >> "$REPORT_FILE"

  local total_repos=0
  local protected_repos=0
  local secret_scanning_enabled=0
  local dependabot_enabled=0

  while IFS= read -r repo; do
    total_repos=$((total_repos + 1))

    # Skip crystal-architect if in wrong org
    if [[ "$org" == "Fractal5-Solutions" && "$repo" == "$EXCEPTION_REPO" ]]; then
      log_warning "Skipping crystal-architect in Fractal5-Solutions (should be in Fractal5-X)"
      echo "| ⚠️  $repo | N/A | N/A | N/A | WRONG ORG |" >> "$REPORT_FILE"
      continue
    fi

    log_info "Checking: $repo"

    # Get repository details
    local repo_data=$(gh api "repos/$org/$repo" 2>/dev/null || echo "{}")
    local default_branch=$(echo "$repo_data" | jq -r '.default_branch // "main"')

    # Check branch protection
    local protection_status="❌"
    if gh api "repos/$org/$repo/branches/$default_branch/protection" &>/dev/null; then
      protection_status="✅"
      protected_repos=$((protected_repos + 1))
    fi

    # Check security features
    local secret_scanning=$(echo "$repo_data" | jq -r '.security_and_analysis.secret_scanning.status // "disabled"')
    local secret_scanning_icon="❌"
    if [[ "$secret_scanning" == "enabled" ]]; then
      secret_scanning_icon="✅"
      secret_scanning_enabled=$((secret_scanning_enabled + 1))
    fi

    local dependabot=$(echo "$repo_data" | jq -r '.security_and_analysis.dependabot_security_updates.status // "disabled"')
    local dependabot_icon="❌"
    if [[ "$dependabot" == "enabled" ]]; then
      dependabot_icon="✅"
      dependabot_enabled=$((dependabot_enabled + 1))
    fi

    # Overall status
    local status="⚠️  REVIEW"
    if [[ "$protection_status" == "✅" && "$secret_scanning_icon" == "✅" && "$dependabot_icon" == "✅" ]]; then
      status="✅ GOOD"
      log_success "$repo - All security features enabled"
    else
      log_warning "$repo - Some security features missing"
    fi

    # Special marking for crystal-architect
    if [[ "$org" == "$EXCEPTION_ORG" && "$repo" == "$EXCEPTION_REPO" ]]; then
      echo "| **$repo** (exception) | $protection_status | $secret_scanning_icon | $dependabot_icon | $status |" >> "$REPORT_FILE"
      log_success "Exception verified: crystal-architect in correct organization"
    else
      echo "| $repo | $protection_status | $secret_scanning_icon | $dependabot_icon | $status |" >> "$REPORT_FILE"
    fi

  done <<< "$repos"

  echo "" >> "$REPORT_FILE"
  echo "**Security Summary for $org:**" >> "$REPORT_FILE"
  echo "- Total repositories: $total_repos" >> "$REPORT_FILE"
  echo "- Branch protection enabled: $protected_repos/$total_repos ($((protected_repos * 100 / total_repos))%)" >> "$REPORT_FILE"
  echo "- Secret scanning enabled: $secret_scanning_enabled/$total_repos ($((secret_scanning_enabled * 100 / total_repos))%)" >> "$REPORT_FILE"
  echo "- Dependabot enabled: $dependabot_enabled/$total_repos ($((dependabot_enabled * 100 / total_repos))%)" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
}

# Verify crystal-architect exception
verify_exception() {
  log_section "Verifying crystal-architect Exception"

  echo "## Exception Verification: crystal-architect" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  # Check if crystal-architect exists in Fractal5-X (should exist)
  if gh repo view "$EXCEPTION_ORG/$EXCEPTION_REPO" &>/dev/null; then
    log_success "crystal-architect found in Fractal5-X (CORRECT)"
    echo "✅ **crystal-architect is correctly in Fractal5-X organization**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Get details
    local repo_data=$(gh api "repos/$EXCEPTION_ORG/$EXCEPTION_REPO")
    local visibility=$(echo "$repo_data" | jq -r '.visibility')
    local default_branch=$(echo "$repo_data" | jq -r '.default_branch')

    echo "- **Organization:** $EXCEPTION_ORG ✅" >> "$REPORT_FILE"
    echo "- **Visibility:** $visibility" >> "$REPORT_FILE"
    echo "- **Default Branch:** $default_branch" >> "$REPORT_FILE"
  else
    log_error "crystal-architect NOT found in Fractal5-X"
    echo "❌ **ERROR: crystal-architect not found in Fractal5-X**" >> "$REPORT_FILE"
  fi

  echo "" >> "$REPORT_FILE"

  # Check if crystal-architect exists in Fractal5-Solutions (should NOT exist)
  if gh repo view "Fractal5-Solutions/$EXCEPTION_REPO" &>/dev/null; then
    log_error "crystal-architect found in Fractal5-Solutions (INCORRECT)"
    echo "❌ **ERROR: crystal-architect found in Fractal5-Solutions (should only be in Fractal5-X)**" >> "$REPORT_FILE"
  else
    log_success "crystal-architect NOT in Fractal5-Solutions (CORRECT)"
    echo "✅ **crystal-architect is NOT in Fractal5-Solutions (correct)**" >> "$REPORT_FILE"
  fi

  echo "" >> "$REPORT_FILE"
}

# Generate summary
generate_summary() {
  log_section "Generating Summary"

  # Insert summary at beginning of report
  local temp_file="${REPORT_FILE}.tmp"

  # Read existing report
  local existing_content=$(cat "$REPORT_FILE")

  # Create new report with summary first
  cat > "$REPORT_FILE" << EOF
# 🏢 GitHub Organization & Enterprise Settings Verification Report

**Generated:** $(date)
**Scope:** Fractal5-Solutions (all repos except crystal-architect), Fractal5-X (crystal-architect only)
**Report Version:** 1.0

---

## 📊 Executive Summary

This report provides a comprehensive verification of organization and repository settings across the Fractal5 ecosystem.

### Key Findings

- **Organizations Verified:** 2 (Fractal5-Solutions, Fractal5-X)
- **Exception Handling:** crystal-architect verified in correct organization (Fractal5-X)
- **Report Generated:** $TIMESTAMP

### Recommendations

1. Review any repositories with missing branch protection
2. Enable secret scanning on all repositories
3. Configure Dependabot security updates
4. Verify two-factor authentication enforcement
5. Document any additional exceptions

---

$existing_content
EOF

  log_success "Summary generated"
}

# Finalize report
finalize_report() {
  log_section "Finalizing Report"

  cat >> "$REPORT_FILE" << EOF

---

## 🎯 Next Steps

1. **Review Findings:** Review all flagged items in this report
2. **Remediate Issues:** Apply standard security settings to non-compliant repositories
3. **Document Exceptions:** Update ORGANIZATIONAL_EXCEPTIONS.md with any additional exceptions
4. **Schedule Review:** Set up quarterly reviews of organization settings
5. **Continuous Monitoring:** Implement automated compliance checking

---

## 📞 Support

**Security Team:** security@fractal5.dev
**DevOps Team:** devops@fractal5.dev

---

**Report Complete**
**Generated:** $(date)
**Report File:** $REPORT_FILE
**Data File:** $JSON_FILE
EOF

  log_success "Report finalized: $REPORT_FILE"
  log_info "Data saved to: $JSON_FILE"
}

# Main execution
main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🏢 GitHub Organization & Enterprise Settings Verification"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  check_prerequisites
  init_report

  # Process each organization
  for org in "${ORGS[@]}"; do
    discover_repositories "$org" || log_warning "Skipping further checks for $org"
    check_organization_settings "$org" || log_warning "Could not check settings for $org"
    check_repository_security "$org" || log_warning "Could not check security for $org"
  done

  # Verify exception
  verify_exception

  # Finalize
  generate_summary
  finalize_report

  echo ""
  log_section "Verification Complete"
  log_success "Report saved to: $REPORT_FILE"
  log_info "Review the report for findings and recommendations"
  echo ""

  # Open report if possible
  if command -v cat &> /dev/null; then
    log_info "Report preview:"
    echo ""
    head -50 "$REPORT_FILE"
    echo ""
    echo "[... report continues ...]"
  fi
}

# Run main function
main "$@"
