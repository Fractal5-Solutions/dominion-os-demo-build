# 🛡️ Enable Branch Protection for Crystal-Architect

This script enables branch protection on Crystal-Architect repository.

## Requirements

- GitHub CLI (`gh`) authenticated with token
- Write access to Fractal5-X/Crystal-Architect

## Usage

```bash
chmod +x enable_crystal_architect_protection.sh
./enable_crystal_architect_protection.sh
```

## What This Does

Enables the following protection on the `main` branch:
- ✅ Required pull request reviews (1 approver)
- ✅ Dismiss stale reviews
- ✅ Require code owner reviews
- ✅ Enforce admins (no bypassing)
- ✅ Required linear history
- ✅ Block force pushes
- ✅ Block deletions
- ✅ Required conversation resolution

## Manual Alternative

```bash
export GH_TOKEN="your-token-here"

gh api -X PUT repos/Fractal5-X/Crystal-Architect/branches/main/protection \
  --input - <<'EOF'
{
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "enforce_admins": true,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
EOF
```

## Verification

After running, verify protection is enabled:

```bash
gh api repos/Fractal5-X/Crystal-Architect/branches/main/protection | jq '.required_pull_request_reviews'
```

Should return protection settings (not 404).
