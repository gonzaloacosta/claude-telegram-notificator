#!/bin/bash
# ABOUTME: Claude Code hook script that triggers after assistant message.
# ABOUTME: Sends notification to Telegram with assistant's response summary.

# This script is called by Claude Code after an assistant message
# - STDIN: Contains the assistant's message content

# Configuration
API_URL="${CLAUDE_TELEGRAM_API_URL:-http://localhost:8000}"
PROJECT_PATH="${CLAUDE_PROJECT_PATH:-$(pwd)}"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

# Read the assistant message from stdin
ASSISTANT_MESSAGE=$(cat)

# Only send notification if message is substantial
if [ ${#ASSISTANT_MESSAGE} -lt 50 ]; then
    echo "$ASSISTANT_MESSAGE"
    exit 0
fi

# Prepare notification message
MESSAGE="💬 Claude responded in project: **${PROJECT_NAME}**\n\nResponse preview: ${ASSISTANT_MESSAGE:0:200}..."

# Send to API (non-blocking)
curl -s -X POST "${API_URL}/hooks/event" \
    -H "Content-Type: application/json" \
    -d "{
        \"hook_type\": \"assistant-message\",
        \"project_path\": \"${PROJECT_PATH}\",
        \"project_name\": \"${PROJECT_NAME}\",
        \"message\": \"${MESSAGE}\",
        \"requires_response\": false,
        \"context\": {
            \"message_length\": ${#ASSISTANT_MESSAGE}
        }
    }" &

# Return the original message unchanged
echo "$ASSISTANT_MESSAGE"
