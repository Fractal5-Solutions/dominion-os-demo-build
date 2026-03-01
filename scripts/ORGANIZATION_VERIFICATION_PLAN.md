# 🏢 GitHub Organization & Enterprise Settings Verification Plan

**Generated:** February 28, 2026
**Scope:** All repositories across Fractal5-Solutions and Fractal5-X organizations
**Exception:** crystal-architect (Fractal5-X only)

---

## 📋 Executive Summary

This plan provides a systematic approach to verify and confirm organization and enterprise-level settings across all GitHub repositories. The goal is to ensure consistent configuration, security posture, and governance across the Fractal5 ecosystem.

### Organizations in Scope:
1. **Fractal5-Solutions** - Primary organization (all repos except crystal-architect)
2. **Fractal5-X** - Secondary organization (crystal-architect only)

---

## 🎯 Phase 1: Repository Discovery & Mapping

### 1.1 Identify All Repositories

**Fractal5-Solutions Repositories:**
```bash
# List all repos in Fractal5-Solutions organization
gh repo list Fractal5-Solutions --limit 100 --json name,owner,visibility,isPrivate,defaultBranch,createdAt,updatedAt
```

**Known Repositories:**
- ✅ dominion-os-demo-build (current repo)
- dominion-api
- dominion-command-center
- dominion-os
- dominion-phi-ui
- [Additional repos to be discovered]

**Fractal5-X Repositories:**
```bash
# List all repos in Fractal5-X organization
gh repo list Fractal5-X --limit 100 --json name,owner,visibility,isPrivate,defaultBranch,createdAt,updatedAt
```

**Known Repositories:**
- ✅ crystal-architect (EXCEPTION - remains in Fractal5-X)
- [Additional repos to be discovered]

### 1.2 Create Repository Inventory

Generate a comprehensive inventory with:
- Repository name
- Organization owner
- Visibility (public/private/internal)
- Default branch
- Last update timestamp
- Access level
- Active collaborators
- Branch protection rules
- Webhook configurations

**Output File:** `REPOSITORY_INVENTORY.json`

---

## 🔍 Phase 2: Organization Settings Verification

### 2.1 Fractal5-Solutions Organization Audit

#### Organization Profile
```bash
# Get organization details
gh api orgs/Fractal5-Solutions --jq '{
  login,
  name,
  description,
  email,
  location,
  blog,
  two_factor_requirement_enabled,
  has_organization_projects,
  has_repository_projects,
  members_can_create_repositories,
  members_can_create_public_repositories,
  members_can_create_private_repositories,
  members_can_create_internal_repositories,
  members_can_fork_private_repositories,
  web_commit_signoff_required,
  default_repository_permission,
  members_can_create_pages,
  members_can_create_public_pages,
  members_can_create_private_pages
}'
```

#### Security Settings
**Check for:**
- ✅ Two-factor authentication requirement
- ✅ SSH key management
- ✅ Security policies
- ✅ Secret scanning enabled
- ✅ Dependabot alerts enabled
- ✅ Code scanning enabled
- ✅ Advanced Security features

#### Member & Team Management
```bash
# List organization members
gh api orgs/Fractal5-Solutions/members --jq '.[].login'

# List teams
gh api orgs/Fractal5-Solutions/teams --jq '.[] | {name, slug, privacy, permission}'

# Check team access to repositories
gh api orgs/Fractal5-Solutions/teams/{team_slug}/repos
```

#### Repository Defaults
- Default repository visibility
- Default branch name (main vs master)
- Default branch protection
- Default license
- Default .gitignore templates
- Code review requirements

### 2.2 Fractal5-X Organization Audit

Perform the same checks as 2.1 for Fractal5-X organization, with special attention to crystal-architect repository settings.

---

## 🔐 Phase 3: Repository-Level Settings Verification

### 3.1 Security Configuration

For each repository, verify:

#### Branch Protection Rules
```bash
# Check default branch protection
gh api repos/{owner}/{repo}/branches/{branch}/protection --jq '{
  required_status_checks,
  enforce_admins,
  required_pull_request_reviews: {
    dismiss_stale_reviews,
    require_code_owner_reviews,
    required_approving_review_count,
    require_last_push_approval
  },
  restrictions,
  required_linear_history,
  allow_force_pushes,
  allow_deletions,
  block_creations,
  required_conversation_resolution,
  lock_branch,
  allow_fork_syncing
}'
```

**Expected Settings:**
- ✅ Require pull request before merging
- ✅ Require approvals (minimum: 1)
- ✅ Dismiss stale reviews on new commits
- ✅ Require status checks to pass
- ✅ Require conversation resolution
- ✅ Do not allow bypassing the above settings
- ⚠️  Allow force pushes: DISABLED
- ⚠️  Allow deletions: DISABLED

#### Security Features
```bash
# Check security settings
gh api repos/{owner}/{repo} --jq '{
  security_and_analysis: {
    secret_scanning,
    secret_scanning_push_protection,
    dependabot_security_updates,
    advanced_security
  },
  visibility,
  private,
  has_issues,
  has_projects,
  has_wiki,
  has_downloads,
  archived,
  disabled,
  allow_forking,
  web_commit_signoff_required
}'
```

**Required Security Settings:**
- ✅ Secret scanning: ENABLED
- ✅ Push protection: ENABLED
- ✅ Dependabot alerts: ENABLED
- ✅ Dependabot security updates: ENABLED
- ✅ Code scanning: ENABLED (if GitHub Advanced Security)
- ✅ Web commit signoff: REQUIRED

### 3.2 Access Control & Permissions

#### Collaborator Audit
```bash
# List direct collaborators
gh api repos/{owner}/{repo}/collaborators --jq '.[] | {login, permissions, role_name}'

# List team access
gh api repos/{owner}/{repo}/teams --jq '.[] | {name, slug, permission}'
```

#### Deploy Keys
```bash
# List deploy keys
gh api repos/{owner}/{repo}/keys --jq '.[] | {id, title, read_only, created_at}'
```

#### Webhooks
```bash
# List webhooks
gh api repos/{owner}/{repo}/hooks --jq '.[] | {id, name, active, events, config: {url, content_type}}'
```

### 3.3 Repository Settings Consistency

**Verify Consistency Across Repos:**
- Default branch naming convention
- Branch protection rules uniformity
- Security features enabled consistently
- Naming conventions (lowercase, hyphens)
- README.md presence and quality
- LICENSE file presence
- CODEOWNERS file presence
- Contributing guidelines
- Security policy (SECURITY.md)

---

## 🌐 Phase 4: Enterprise Settings Verification

### 4.1 Enterprise-Level Policies

If using GitHub Enterprise, verify:

#### Policy Configuration
```bash
# Get enterprise policies (requires enterprise admin access)
gh api enterprises/{enterprise}/settings --jq '{
  two_factor_required_enabled,
  private_mode,
  github_pages_enabled,
  github_connect_enabled,
  dependabot_updates_enabled,
  advanced_security_enabled_for_new_repositories
}'
```

#### Licensing & Seats
- Total licensed seats
- Seats in use
- Advanced Security seat usage
- Copilot seat assignments

#### Audit Log Review
```bash
# Export audit log for compliance
gh api enterprises/{enterprise}/audit-log --jq '.[] | {
  action,
  actor,
  created_at,
  repo,
  org
}' > enterprise_audit_log.json
```

### 4.2 Compliance & Governance

**Verify Compliance With:**
- SOC 2 requirements
- ISO 27001 standards
- GDPR data handling
- Industry-specific regulations
- Internal security policies

---

## 📊 Phase 5: Automated Verification Script

### 5.1 Comprehensive Verification Script

```bash
#!/bin/bash
# verify_organization_settings.sh

set -euo pipefail

ORGS=("Fractal5-Solutions" "Fractal5-X")
REPORT_FILE="organization_verification_report_$(date +%Y%m%d_%H%M%S).md"

echo "# GitHub Organization Settings Verification Report" > "$REPORT_FILE"
echo "**Generated:** $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

for org in "${ORGS[@]}"; do
  echo "## Organization: $org" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  # Get organization details
  echo "### Organization Settings" >> "$REPORT_FILE"
  gh api "orgs/$org" --jq '{
    two_factor_requirement_enabled,
    members_can_create_repositories,
    web_commit_signoff_required,
    default_repository_permission
  }' | jq -r 'to_entries | .[] | "- **\(.key)**: \(.value)"' >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  # List repositories
  echo "### Repositories" >> "$REPORT_FILE"
  repos=$(gh repo list "$org" --limit 100 --json name -q '.[].name')

  for repo in $repos; do
    # Skip crystal-architect if in Fractal5-Solutions
    if [[ "$org" == "Fractal5-Solutions" && "$repo" == "crystal-architect" ]]; then
      echo "⚠️  Skipping crystal-architect (belongs to Fractal5-X)" >> "$REPORT_FILE"
      continue
    fi

    # Flag crystal-architect in Fractal5-X
    if [[ "$org" == "Fractal5-X" && "$repo" == "crystal-architect" ]]; then
      echo "✅ **$repo** (EXCEPTION - correctly in Fractal5-X)" >> "$REPORT_FILE"
    else
      echo "- $repo" >> "$REPORT_FILE"
    fi

    # Check branch protection
    default_branch=$(gh api "repos/$org/$repo" --jq '.default_branch')
    protection_status=$(gh api "repos/$org/$repo/branches/$default_branch/protection" 2>/dev/null || echo "not_protected")

    if [[ "$protection_status" == "not_protected" ]]; then
      echo "  ⚠️  Branch protection: NOT ENABLED" >> "$REPORT_FILE"
    else
      echo "  ✅ Branch protection: ENABLED" >> "$REPORT_FILE"
    fi

    # Check security features
    security=$(gh api "repos/$org/$repo" --jq '.security_and_analysis')
    echo "  Security features:" >> "$REPORT_FILE"
    echo "$security" | jq -r 'to_entries | .[] | "    - \(.key): \(.value.status)"' >> "$REPORT_FILE"
  done

  echo "" >> "$REPORT_FILE"
done

echo "✅ Verification complete. Report saved to: $REPORT_FILE"
```

### 5.2 Continuous Monitoring Script

```bash
#!/bin/bash
# monitor_organization_compliance.sh

# Run daily to detect configuration drift
# Alert on: new repos, permission changes, security feature disablement

SLACK_WEBHOOK="${SLACK_WEBHOOK_URL}"
ALERT_EMAIL="security@fractal5.dev"

# Scan for non-compliant repositories
non_compliant_repos=()

for org in Fractal5-Solutions Fractal5-X; do
  repos=$(gh repo list "$org" --limit 100 --json name -q '.[].name')

  for repo in $repos; do
    # Check if secret scanning is enabled
    secret_scanning=$(gh api "repos/$org/$repo" --jq '.security_and_analysis.secret_scanning.status')

    if [[ "$secret_scanning" != "enabled" ]]; then
      non_compliant_repos+=("$org/$repo: secret_scanning disabled")
    fi

    # Check branch protection
    default_branch=$(gh api "repos/$org/$repo" --jq '.default_branch')
    gh api "repos/$org/$repo/branches/$default_branch/protection" &>/dev/null || \
      non_compliant_repos+=("$org/$repo: no branch protection on $default_branch")
  done
done

# Send alerts if non-compliant repos found
if [ ${#non_compliant_repos[@]} -gt 0 ]; then
  alert_message="⚠️  Non-compliant repositories detected:\n\n"
  for repo in "${non_compliant_repos[@]}"; do
    alert_message+="- $repo\n"
  done

  # Send to Slack
  curl -X POST "$SLACK_WEBHOOK" -H 'Content-Type: application/json' \
    -d "{\"text\":\"$alert_message\"}"

  # Send email (requires mail command)
  echo -e "$alert_message" | mail -s "GitHub Compliance Alert" "$ALERT_EMAIL"
fi
```

---

## 🔄 Phase 6: Standardization & Remediation

### 6.1 Apply Standard Configuration

For repositories missing required settings:

```bash
#!/bin/bash
# apply_standard_repo_settings.sh

OWNER="Fractal5-Solutions"
REPO="$1"

# Enable branch protection
gh api -X PUT "repos/$OWNER/$REPO/branches/main/protection" \
  -f required_status_checks='{"strict":true,"contexts":[]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":1}' \
  -f restrictions=null \
  -f required_linear_history=true \
  -f allow_force_pushes=false \
  -f allow_deletions=false \
  -f required_conversation_resolution=true

# Enable security features
gh api -X PATCH "repos/$OWNER/$REPO" \
  -f security_and_analysis='{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"},"dependabot_security_updates":{"status":"enabled"}}'

# Require signed commits
gh api -X PATCH "repos/$OWNER/$REPO" \
  -F web_commit_signoff_required=true

echo "✅ Standard settings applied to $OWNER/$REPO"
```

### 6.2 Create Missing Documentation

Ensure each repository has:
- README.md
- LICENSE
- SECURITY.md
- CONTRIBUTING.md
- CODE_OF_CONDUCT.md
- .github/CODEOWNERS
- .github/dependabot.yml
- .github/workflows/ (CI/CD)

---

## 📈 Phase 7: Reporting & Documentation

### 7.1 Generate Compliance Report

**Report Sections:**
1. **Executive Summary**
   - Total repositories scanned
   - Compliance percentage
   - Critical issues found
   - Remediation status

2. **Organization Overview**
   - Per-organization statistics
   - Member count
   - Team structure
   - Access patterns

3. **Security Posture**
   - Enabled security features
   - Vulnerability alerts
   - Secret scanning detections
   - Dependabot updates

4. **Branch Protection Analysis**
   - Protected branches count
   - Protection rule consistency
   - Bypassed protections

5. **Access Control Audit**
   - Collaborator access levels
   - Team permissions
   - Deploy keys inventory
   - Webhook configurations

6. **Non-Compliance Report**
   - Repositories requiring attention
   - Missing security features
   - Unprotected branches
   - Policy violations

### 7.2 Visualization Dashboard

Create a real-time dashboard showing:
- Organization health score
- Security compliance trends
- Repository activity heatmap
- Access control matrix
- Alert history

**Tools:**
- GitHub API + Custom dashboard
- Grafana + Prometheus
- DataDog / New Relic
- Custom PowerBI/Tableau dashboard

---

## 🎯 Phase 8: Exception Handling

### 8.1 crystal-architect Special Case

**Verification Checklist:**
- ✅ Confirm crystal-architect is in Fractal5-X organization
- ✅ Verify it does NOT appear in Fractal5-Solutions
- ✅ Check access permissions specific to crystal-architect
- ✅ Document reason for organizational exception
- ✅ Ensure security settings match other repos despite different org

**Commands:**
```bash
# Verify crystal-architect location
gh repo view Fractal5-X/crystal-architect --json owner,name,visibility

# Check if it incorrectly exists in Fractal5-Solutions
gh repo view Fractal5-Solutions/crystal-architect 2>&1 | grep -q "Could not resolve" && \
  echo "✅ crystal-architect correctly NOT in Fractal5-Solutions" || \
  echo "⚠️  WARNING: crystal-architect found in Fractal5-Solutions!"

# Verify security settings
gh api repos/Fractal5-X/crystal-architect --jq '.security_and_analysis'
```

### 8.2 Exception Documentation

Create `ORGANIZATIONAL_EXCEPTIONS.md` documenting:
- Repository: crystal-architect
- Organization: Fractal5-X (not Fractal5-Solutions)
- Reason: [To be documented]
- Approved by: [To be documented]
- Date: [To be documented]
- Review frequency: Quarterly

---

## 🚦 Phase 9: Execution Plan

### 9.1 Immediate Actions (Week 1)

**Day 1-2: Discovery**
- [ ] Run repository discovery for Fractal5-Solutions
- [ ] Run repository discovery for Fractal5-X
- [ ] Generate repository inventory
- [ ] Verify crystal-architect location

**Day 3-4: Analysis**
- [ ] Audit organization settings
- [ ] Check security features across all repos
- [ ] Review branch protection rules
- [ ] Analyze access control

**Day 5: Documentation**
- [ ] Generate compliance report
- [ ] Document exceptions
- [ ] Create remediation plan
- [ ] Present findings

### 9.2 Short-Term Actions (Week 2-4)

- [ ] Apply standard settings to non-compliant repos
- [ ] Create missing documentation files
- [ ] Configure branch protection rules
- [ ] Enable security features
- [ ] Set up continuous monitoring

### 9.3 Long-Term Actions (Month 2+)

- [ ] Implement automated compliance checking
- [ ] Set up alerting for policy violations
- [ ] Quarterly access reviews
- [ ] Annual security audits
- [ ] Update policies based on findings

---

## 📋 Verification Checklist

### Organization-Level
- [ ] Two-factor authentication enforced
- [ ] Organization profile complete
- [ ] Member permissions configured
- [ ] Team structure documented
- [ ] Repository creation policies set
- [ ] Default security settings applied

### Repository-Level
- [ ] All repos have branch protection
- [ ] Secret scanning enabled
- [ ] Dependabot alerts enabled
- [ ] Code scanning configured (if applicable)
- [ ] Web commit signoff required
- [ ] README.md present and updated
- [ ] LICENSE file present
- [ ] SECURITY.md present
- [ ] CODEOWNERS file configured

### Exception Handling
- [ ] crystal-architect in correct org (Fractal5-X)
- [ ] Exception documented
- [ ] Security settings verified
- [ ] Access control appropriate

### Compliance & Governance
- [ ] Audit log reviewed
- [ ] Access patterns analyzed
- [ ] Compliance report generated
- [ ] Remediation plan created
- [ ] Stakeholders notified

---

## 🛠️ Tools & Resources

### Required Tools
- GitHub CLI (`gh`)
- `jq` - JSON processing
- `curl` - API requests
- `bash` - Shell scripting
- Git - Version control

### GitHub Permissions Required
- Organization admin access (Fractal5-Solutions & Fractal5-X)
- Repository admin access (all repos)
- GitHub Enterprise admin (if applicable)
- Audit log access

### API Rate Limits
- Authenticated: 5,000 requests/hour
- GitHub Enterprise: Higher limits
- Use conditional requests to save quota
- Implement caching where possible

---

## 📞 Contact & Support

**Security Team:** security@fractal5.dev
**DevOps Team:** devops@fractal5.dev
**Compliance Team:** compliance@fractal5.dev

**Escalation Path:**
1. Repository owners
2. Team leads
3. Organization administrators
4. Security committee
5. Executive leadership

---

## 🎯 Success Criteria

**Verification Complete When:**
- ✅ 100% of repositories inventoried
- ✅ All organization settings documented
- ✅ Security compliance at 95%+ across all repos
- ✅ Branch protection rules standardized
- ✅ Access control audit complete
- ✅ Exception handling (crystal-architect) verified
- ✅ Compliance report generated and reviewed
- ✅ Automated monitoring in place
- ✅ Remediation plan for non-compliant items
- ✅ Stakeholder approval obtained

**Expected Outcomes:**
- Complete visibility into organization structure
- Consistent security posture across all repositories
- Clear documentation of settings and exceptions
- Automated compliance monitoring
- Reduced security risks
- Improved governance

---

**Plan Status:** READY FOR EXECUTION
**Estimated Duration:** 2-4 weeks
**Risk Level:** LOW (read-only verification initially)
**Next Step:** Run Phase 1 repository discovery

**To begin execution:**
```bash
cd /workspaces/dominion-os-demo-build/scripts
./verify_organization_settings.sh
```
