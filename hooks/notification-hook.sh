#!/bin/bash
# ABOUTME: Claude Code hook script that triggers on notification events.
# ABOUTME: Sends notification to Telegram when Claude shows a notification.

# This script is called by Claude Code on notification events
# - STDIN: Contains the notification message content

# Configuration
API_URL="${CLAUDE_TELEGRAM_API_URL:-http://localhost:9999}"
PROJECT_PATH="${CLAUDE_PROJECT_PATH:-$(pwd)}"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

# Read the notification from stdin
NOTIFICATION=$(cat)

# Return the original notification unchanged (must happen before background task)
echo "$NOTIFICATION"

# Only send to Telegram if notification is substantial
if [ ${#NOTIFICATION} -lt 5 ]; then
    exit 0
fi

# Send to API (non-blocking, properly detached)
# Use jq to properly escape JSON values
(JSON_PAYLOAD=$(jq -n \
    --arg hook_type "notification" \
    --arg project_path "$PROJECT_PATH" \
    --arg project_name "$PROJECT_NAME" \
    --arg notification_text "$NOTIFICATION" \
    '{
        hook_type: $hook_type,
        project_path: $project_path,
        project_name: $project_name,
        message: $notification_text,
        requires_response: false,
        context: {}
    }')

curl -s -X POST "${API_URL}/hooks/event" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" > /dev/null 2>&1 &)

# Exit successfully
exit 0
