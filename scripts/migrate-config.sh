#!/bin/bash
# Migration script for config.yaml to support multiple Git providers
# This script maintains backward compatibility while adding new structure

set -e

CONFIG_FILE="config.yaml"
BACKUP_FILE="config.yaml.backup"

echo "CNOE Reference Implementation - Configuration Migration Script"
echo "=============================================================="

# Create backup
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "✅ Backup created: $BACKUP_FILE"
else
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Check if new format already exists
if grep -q "git_providers:" "$CONFIG_FILE"; then
    echo "ℹ️  Configuration already uses new format"
    exit 0
fi

echo "🔄 Migrating configuration to new multi-provider format..."

# Extract existing repo configuration
if ! yq eval '.repo' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "❌ Unable to find existing repo configuration"
    exit 1
fi

REPO_URL=$(yq eval '.repo.url' "$CONFIG_FILE")
REPO_REVISION=$(yq eval '.repo.revision' "$CONFIG_FILE")
REPO_BASEPATH=$(yq eval '.repo.basepath' "$CONFIG_FILE")

echo "📖 Extracted existing configuration:"
echo "   URL: $REPO_URL"
echo "   Revision: $REPO_REVISION"
echo "   Base Path: $REPO_BASEPATH"

# Create new configuration structure
echo "🏗️  Creating new git_providers structure..."

# Add git_providers section
yq eval ".git_providers.github.enabled = true" -i "$CONFIG_FILE"
yq eval ".git_providers.github.repo.url = \"$REPO_URL\"" -i "$CONFIG_FILE"
yq eval ".git_providers.github.repo.revision = \"$REPO_REVISION\"" -i "$CONFIG_FILE"
yq eval ".git_providers.github.repo.basepath = \"$REPO_BASEPATH\"" -i "$CONFIG_FILE"
yq eval ".git_providers.github.integration_type = \"github_app\"" -i "$CONFIG_FILE"

# Add Bitbucket configuration (disabled by default)
yq eval ".git_providers.bitbucket.enabled = false" -i "$CONFIG_FILE"
yq eval ".git_providers.bitbucket.repo.url = \"\"" -i "$CONFIG_FILE"
yq eval ".git_providers.bitbucket.repo.revision = \"main\"" -i "$CONFIG_FILE"
yq eval ".git_providers.bitbucket.repo.basepath = \"packages\"" -i "$CONFIG_FILE"
yq eval ".git_providers.bitbucket.integration_type = \"app_password\"" -i "$CONFIG_FILE"
yq eval ".git_providers.bitbucket.workspace = \"\"" -i "$CONFIG_FILE"
yq eval ".git_providers.bitbucket.server_url = \"https://bitbucket.org\"" -i "$CONFIG_FILE"

# Add primary Git provider setting
yq eval ".primary_git_provider = \"github\"" -i "$CONFIG_FILE"

# Add comment about backward compatibility
cat >> "$CONFIG_FILE" << 'EOF'

# Backward compatibility - will be deprecated in future versions
# Please use git_providers configuration above
EOF

echo "✅ Migration completed successfully!"
echo "📁 Original configuration backed up to: $BACKUP_FILE"
echo "🔧 New configuration structure created with GitHub as primary provider"
echo ""
echo "To enable Bitbucket support:"
echo "1. Set git_providers.bitbucket.enabled = true"
echo "2. Configure git_providers.bitbucket.workspace"
echo "3. Set git_providers.bitbucket.repo.url"
echo "4. Run ./scripts/create-config-secrets.sh"
echo ""
echo "Migration complete! 🎉"