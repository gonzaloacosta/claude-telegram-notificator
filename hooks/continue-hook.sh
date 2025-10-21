#!/bin/bash
# ABOUTME: Interactive Claude Code hook for testing response flow with Telegram.
# ABOUTME: Sends a question to Telegram with context and waits for Yes/No response.

# This script demonstrates the interactive response mechanism.
# It BLOCKS and waits for user input from Telegram (up to 5 minutes).
#
# Usage:
#   # Simple question
#   ./continue-hook.sh
#
#   # With custom question
#   echo "Deploy to production?" | ./continue-hook.sh
#
#   # With context about what's being approved
#   CLAUDE_CONTEXT="Created 3 files, modified API" ./continue-hook.sh
#
#   # With detailed context
#   CLAUDE_LAST_ACTION="Refactored database" \
#   CLAUDE_TOOLS_USED="Edit, Write, Bash" \
#   CLAUDE_FILES_CHANGED="schema.sql, api.py" \
#   ./continue-hook.sh
#
# Environment Variables:
#   CLAUDE_CONTEXT - Brief summary of what's being approved
#   CLAUDE_LAST_ACTION - Description of last action
#   CLAUDE_TOOLS_USED - Comma-separated list of tools used
#   CLAUDE_FILES_CHANGED - Files that were modified
#
# Returns:
#   Exit 0 if user clicks Yes
#   Exit 1 if user clicks No or timeout

# Configuration
API_URL="${CLAUDE_TELEGRAM_API_URL:-http://localhost:9999}"
PROJECT_PATH="${CLAUDE_PROJECT_PATH:-$(pwd)}"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

# Read the question from stdin, or use default
if [ -t 0 ]; then
    # stdin is a terminal (no pipe), use default message
    QUESTION="Continue with this action?"
else
    # stdin has data piped to it
    QUESTION=$(cat)
fi

# Use default if empty
if [ -z "$QUESTION" ]; then
    QUESTION="Continue with this action?"
fi

# Build context information
CONTEXT_INFO=""

# Add simple context if provided
if [ -n "$CLAUDE_CONTEXT" ]; then
    CONTEXT_INFO="$CLAUDE_CONTEXT"
fi

# Or build from detailed context
if [ -n "$CLAUDE_LAST_ACTION" ] || [ -n "$CLAUDE_TOOLS_USED" ] || [ -n "$CLAUDE_FILES_CHANGED" ]; then
    CONTEXT_INFO=""

    if [ -n "$CLAUDE_LAST_ACTION" ]; then
        CONTEXT_INFO="${CONTEXT_INFO}Action: ${CLAUDE_LAST_ACTION}\n"
    fi

    if [ -n "$CLAUDE_TOOLS_USED" ]; then
        CONTEXT_INFO="${CONTEXT_INFO}Tools: ${CLAUDE_TOOLS_USED}\n"
    fi

    if [ -n "$CLAUDE_FILES_CHANGED" ]; then
        CONTEXT_INFO="${CONTEXT_INFO}Files: ${CLAUDE_FILES_CHANGED}\n"
    fi
fi

# Generate a unique session ID
SESSION_ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "session-$$-$RANDOM")

# Build the full message with context
FULL_MESSAGE="$QUESTION"
if [ -n "$CONTEXT_INFO" ]; then
    FULL_MESSAGE="$QUESTION\n\n📋 Context:\n$CONTEXT_INFO"
fi

echo "📋 Sending question to Telegram: $QUESTION" >&2
if [ -n "$CONTEXT_INFO" ]; then
    echo "📄 With context included" >&2
fi
echo "⏳ Waiting for response (timeout: 5 minutes)..." >&2

# Send to API and WAIT for response (synchronous call)
# Use jq to properly escape JSON values
JSON_PAYLOAD=$(jq -n \
    --arg hook_type "custom" \
    --arg project_path "$PROJECT_PATH" \
    --arg project_name "$PROJECT_NAME" \
    --arg message "$FULL_MESSAGE" \
    --arg session_id "$SESSION_ID" \
    --arg context_info "$CONTEXT_INFO" \
    '{
        hook_type: $hook_type,
        project_path: $project_path,
        project_name: $project_name,
        message: $message,
        requires_response: true,
        session_id: $session_id,
        context: {
            interactive: true,
            context_summary: $context_info
        }
    }')

# Make the API call and capture response
RESPONSE=$(curl -s -X POST "${API_URL}/hooks/event" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")

# Check if curl succeeded
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to connect to API at $API_URL" >&2
    exit 2
fi

# Parse the response
RESPONSE_TYPE=$(echo "$RESPONSE" | jq -r '.response_type // "error"')
SUCCESS=$(echo "$RESPONSE" | jq -r '.success // false')

# Check if API call was successful
if [ "$SUCCESS" != "true" ]; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error // "Unknown error"')
    echo "❌ API Error: $ERROR_MSG" >&2
    exit 2
fi

# Handle the response
case "$RESPONSE_TYPE" in
    "yes")
        echo "✅ User responded: YES" >&2
        echo "Continuing..."
        exit 0
        ;;
    "no")
        echo "❌ User responded: NO" >&2
        echo "Cancelled by user"
        exit 1
        ;;
    "timeout")
        echo "⏱️  Response timeout - no answer received" >&2
        echo "Cancelled due to timeout"
        exit 1
        ;;
    "custom")
        CUSTOM_MSG=$(echo "$RESPONSE" | jq -r '.message // ""')
        echo "💬 User responded: $CUSTOM_MSG" >&2
        echo "$CUSTOM_MSG"
        exit 0
        ;;
    *)
        echo "❓ Unknown response type: $RESPONSE_TYPE" >&2
        exit 2
        ;;
esac
