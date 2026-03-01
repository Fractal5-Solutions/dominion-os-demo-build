#!/bin/bash
echo "🔧 PHI Quick Validation & Repair"
echo "================================="

# Check repository state
echo "📊 Repository Status:"
echo "  Clean working tree: $(git status --porcelain | wc -l) files"
echo "  Commits ahead: $(git log --oneline origin/sovereign-power-mode-max..HEAD 2>/dev/null | wc -l || echo "unknown")"

# Check required files
echo ""
echo "📁 Required Files:"
files=("README.md" "LICENSE" "requirements.txt")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file"
    fi
done

# Check PHI workflows
echo ""
echo "⚙️ PHI Workflows:"
workflows=(".github/workflows/phi-autonomous-sync.yml" ".github/workflows/security.yml")
for wf in "${workflows[@]}"; do
    if [ -f "$wf" ]; then
        echo "  ✅ $(basename "$wf")"
    else
        echo "  ❌ $(basename "$wf")"
    fi
done

# Check enterprise configs
echo ""
echo "🏢 Enterprise Configs:"
configs=(".github/codeql-config.yml" ".github/enterprise-config.yml" ".github/dependabot.yml")
for cfg in "${configs[@]}"; do
    if [ -f "$cfg" ]; then
        echo "  ✅ $(basename "$cfg")"
    else
        echo "  ⚠️ $(basename "$cfg")"
    fi
done

echo ""
echo "🎯 Quick validation complete!"
