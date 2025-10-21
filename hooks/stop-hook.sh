#!/bin/bash
# ABOUTME: Claude Code hook script that triggers when Claude stops or encounters an error.
# ABOUTME: Sends notification to Telegram when Claude stops processing.

# This script is called by Claude Code on stop events
# - STDIN: Contains the stop reason or error message

# Configuration
API_URL="${CLAUDE_TELEGRAM_API_URL:-http://localhost:9999}"
PROJECT_PATH="${CLAUDE_PROJECT_PATH:-$(pwd)}"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

# Read the stop reason from stdin
STOP_REASON=$(cat)

# Return the original message unchanged (must happen before background task)
echo "$STOP_REASON"

# Prepare notification message
if [ -z "$STOP_REASON" ]; then
    MESSAGE="⏸️ Claude stopped in **${PROJECT_NAME}**"
else
    MESSAGE="⏸️ Claude stopped in **${PROJECT_NAME}**\n\nReason: ${STOP_REASON}"
fi

# Send to API (non-blocking, properly detached)
# Use jq to properly escape JSON values
(JSON_PAYLOAD=$(jq -n \
    --arg hook_type "stop" \
    --arg project_path "$PROJECT_PATH" \
    --arg project_name "$PROJECT_NAME" \
    --arg message "$MESSAGE" \
    --arg stop_reason "$STOP_REASON" \
    '{
        hook_type: $hook_type,
        project_path: $project_path,
        project_name: $project_name,
        message: $message,
        requires_response: false,
        context: {
            stop_reason: $stop_reason
        }
    }')

curl -s -X POST "${API_URL}/hooks/event" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" > /dev/null 2>&1 &)

# Exit successfully
exit 0
