#!/bin/bash
# ABOUTME: Installation script to set up Claude Code hooks for Telegram notifications.
# ABOUTME: Copies hook scripts to the appropriate location and makes them executable.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="${HOME}/.claude/hooks"

echo "🔧 Installing Claude-Telegram Notificator hooks..."

# Create hooks directory if it doesn't exist
mkdir -p "${HOOKS_DIR}"

# Copy hook scripts
echo "📋 Copying hook scripts..."
cp "${SCRIPT_DIR}/user-prompt-submit-hook.sh" "${HOOKS_DIR}/user-prompt-submit-hook"
cp "${SCRIPT_DIR}/assistant-message-hook.sh" "${HOOKS_DIR}/assistant-message-hook"

# Make scripts executable
chmod +x "${HOOKS_DIR}/user-prompt-submit-hook"
chmod +x "${HOOKS_DIR}/assistant-message-hook"

echo "✅ Hooks installed successfully!"
echo ""
echo "Installed hooks:"
echo "  - ${HOOKS_DIR}/user-prompt-submit-hook"
echo "  - ${HOOKS_DIR}/assistant-message-hook"
echo ""
echo "To use project-specific hooks, copy these files to:"
echo "  <your-project>/.claude/hooks/"
echo ""
echo "To uninstall, simply delete the hook files from ${HOOKS_DIR}"
