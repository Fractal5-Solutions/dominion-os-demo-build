#!/bin/bash
###############################################################################
# Dev Container Post-Create Script
# Runs once after the container is created
###############################################################################

set -e

echo "🚀 PHI Dev Container - Post Create Setup"
echo "========================================="

cd /workspaces/dominion-os-demo-build

# Setup Python virtual environment
if [ ! -d ".venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip setuptools wheel
    
    # Install requirements if they exist
    if [ -f "requirements.txt" ]; then
        echo "Installing Python dependencies..."
        pip install -r requirements.txt
    fi
    
    if [ -f "scripts/requirements.txt" ]; then
        echo "Installing script dependencies..."
        pip install -r scripts/requirements.txt
    fi
else
    echo "✓ Virtual environment already exists"
fi

# Setup directories
echo "Creating directory structure..."
mkdir -p scripts/logs
mkdir -p scripts/telemetry
mkdir -p scripts/backups
mkdir -p exports
mkdir -p data

# Set permissions
chmod +x scripts/*.sh 2>/dev/null || true

# Initialize git hooks if not present
if [ -d ".git" ] && [ ! -f ".git/hooks/pre-commit" ]; then
    echo "Setting up git hooks..."
    # You can add pre-commit hooks here
fi

echo "✅ Post-create setup complete!"
