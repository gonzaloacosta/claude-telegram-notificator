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
cp "${SCRIPT_DIR}/notification-hook.sh" "${HOOKS_DIR}/notification-hook"
cp "${SCRIPT_DIR}/stop-hook.sh" "${HOOKS_DIR}/stop-hook"
cp "${SCRIPT_DIR}/continue-hook.sh" "${HOOKS_DIR}/continue-hook"

# Make scripts executable
chmod +x "${HOOKS_DIR}/user-prompt-submit-hook"
chmod +x "${HOOKS_DIR}/assistant-message-hook"
chmod +x "${HOOKS_DIR}/notification-hook"
chmod +x "${HOOKS_DIR}/stop-hook"
chmod +x "${HOOKS_DIR}/continue-hook"

echo "✅ Hooks installed successfully!"
echo ""
echo "Installed hooks:"
echo "  - ${HOOKS_DIR}/user-prompt-submit-hook"
echo "  - ${HOOKS_DIR}/assistant-message-hook"
echo "  - ${HOOKS_DIR}/notification-hook"
echo "  - ${HOOKS_DIR}/stop-hook"
echo "  - ${HOOKS_DIR}/continue-hook (interactive testing)"
echo ""
echo "To use project-specific hooks, copy these files to:"
echo "  <your-project>/.claude/hooks/"
echo ""
echo "To uninstall, simply delete the hook files from ${HOOKS_DIR}"
