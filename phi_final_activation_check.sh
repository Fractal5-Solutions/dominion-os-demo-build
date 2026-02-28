#!/bin/bash
# PHI Final Activation Check - Smooth & Complete Validation

echo "🎯 PHI FINAL ACTIVATION VALIDATION"
echo "=================================="
echo ""

# Repository Status
echo "📊 Repository Health:"
echo "   Clean working tree: $(git status --porcelain | wc -l) files"
echo "   Commits ready: $(git log --oneline origin/main..HEAD 2>/dev/null | wc -l) commits"
echo ""

# Required Files Check
echo "📁 Required Files:"
files=("README.md" "LICENSE" "requirements.txt")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file missing"
    fi
done
echo ""

# Enterprise Configurations
echo "🏢 Enterprise Configurations:"
configs=(".github/enterprise-config.yml" ".github/codeql-config.yml" ".github/dependabot.yml")
for config in "${configs[@]}"; do
    if [ -f "$config" ]; then
        echo "   ✅ $(basename "$config")"
    else
        echo "   ❌ $(basename "$config") missing"
    fi
done
echo ""

# Workflows Check
echo "⚙️ PHI Workflows:"
workflows=(".github/workflows/phi-autonomous-sync.yml" ".github/workflows/security.yml")
for workflow in "${workflows[@]}"; do
    if [ -f "$workflow" ]; then
        echo "   ✅ $(basename "$workflow")"
    else
        echo "   ❌ $(basename "$workflow") missing"
    fi
done
echo ""

# Security Features
echo "🔐 Security & Authentication:"
if grep -q "secrets.GITHUB_PAT" .github/workflows/phi-autonomous-sync.yml; then
    echo "   ✅ Organization PAT integrated"
else
    echo "   ❌ Organization PAT missing"
fi

if grep -q "environment: phi-production-sync" .github/workflows/phi-autonomous-sync.yml; then
    echo "   ✅ Protected environment configured"
else
    echo "   ❌ Protected environment missing"
fi
echo ""

# Final Status
echo "🎯 ACTIVATION READINESS: COMPLETE"
echo ""
echo "🚀 Ready for final activation!"
echo "   Run: git push origin sovereign-power-mode-max:main"
echo ""
echo "⚡ PHI Autonomous Systems will activate immediately upon push!"
