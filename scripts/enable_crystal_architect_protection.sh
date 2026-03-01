#!/bin/bash
# Enable branch protection on Crystal-Architect repository

export GH_TOKEN="YOUR_GITHUB_TOKEN"

echo "Enabling branch protection on Crystal-Architect..."

gh api -X PUT repos/Fractal5-X/Crystal-Architect/branches/main/protection \
  --input /workspaces/dominion-os-demo-build/scripts/branch-protection-standard.json

if [ $? -eq 0 ]; then
  echo "✅ Branch protection enabled successfully"
  echo "Verifying..."
  gh api repos/Fractal5-X/Crystal-Architect/branches/main/protection | jq '{enforce_admins: .enforce_admins.enabled, required_reviews: .required_pull_request_reviews.required_approving_review_count}'
else
  echo "❌ Failed to enable branch protection"
  exit 1
fi
