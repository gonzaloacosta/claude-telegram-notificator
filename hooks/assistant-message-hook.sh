#!/bin/bash
# ABOUTME: Claude Code hook script that triggers after assistant message.
# ABOUTME: Sends notification to Telegram with assistant's response and summary.

# This script is called by Claude Code after an assistant message
# - STDIN: Contains JSON metadata with transcript_path to the JSONL conversation file

# Configuration
API_URL="${CLAUDE_TELEGRAM_API_URL:-http://localhost:9999}"
PROJECT_PATH="${CLAUDE_PROJECT_PATH:-$(pwd)}"
PROJECT_NAME="$(basename "$PROJECT_PATH")"
MAX_PREVIEW_LENGTH=800  # Maximum characters to send to Telegram

# Read the input from stdin
INPUT=$(cat)

# Return the original input unchanged (must happen before background task)
echo "$INPUT"

# Check if input is JSON metadata (contains transcript_path)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    # Not JSON metadata or file doesn't exist, skip
    exit 0
fi

# Read the last line from the JSONL file (the latest assistant message)
LAST_MESSAGE=$(tail -n 1 "$TRANSCRIPT_PATH")

# Extract the message content from the JSON
# The content is in message.content[] array, we want text blocks
ASSISTANT_MESSAGE=$(echo "$LAST_MESSAGE" | jq -r '
    if .message.content then
        .message.content[] |
        select(.type == "text") |
        .text
    else
        empty
    end
' 2>/dev/null | head -c 10000)

# Only send notification if message is substantial
if [ -z "$ASSISTANT_MESSAGE" ] || [ ${#ASSISTANT_MESSAGE} -lt 50 ]; then
    exit 0
fi

# Extract smart summary from Claude's response
# Look for tool usage, file changes, and actions

# Extract tools used (looking for common patterns)
TOOLS_FOUND=$(echo "$ASSISTANT_MESSAGE" | grep -oE "(Read|Write|Edit|Bash|Grep|Glob|WebFetch|Task)" | sort -u | tr '\n' ', ' | sed 's/,$//')

# Count files mentioned (basic heuristic)
FILES_COUNT=$(echo "$ASSISTANT_MESSAGE" | grep -oE "\.(py|js|sh|json|yaml|md|txt|sql)" | wc -l | tr -d ' ')

# Create a preview of the message (first N chars, truncate at word boundary)
MESSAGE_PREVIEW="${ASSISTANT_MESSAGE:0:$MAX_PREVIEW_LENGTH}"
if [ ${#ASSISTANT_MESSAGE} -gt $MAX_PREVIEW_LENGTH ]; then
    # Truncate at last complete word
    MESSAGE_PREVIEW="${MESSAGE_PREVIEW% *}..."
fi

# Build context object
CONTEXT_JSON=$(jq -n \
    --argjson message_length "${#ASSISTANT_MESSAGE}" \
    --arg tools_used "$TOOLS_FOUND" \
    --argjson files_mentioned "$FILES_COUNT" \
    '{
        message_length: $message_length,
        tools_used: $tools_used,
        files_mentioned: $files_mentioned
    }')

# Send to API (non-blocking, properly detached)
# Use jq to properly escape JSON values
(JSON_PAYLOAD=$(jq -n \
    --arg hook_type "assistant-message" \
    --arg project_path "$PROJECT_PATH" \
    --arg project_name "$PROJECT_NAME" \
    --arg message_preview "$MESSAGE_PREVIEW" \
    --argjson context "$CONTEXT_JSON" \
    '{
        hook_type: $hook_type,
        project_path: $project_path,
        project_name: $project_name,
        message: $message_preview,
        requires_response: false,
        context: $context
    }')

curl -s -X POST "${API_URL}/hooks/event" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" > /dev/null 2>&1 &)

# Exit successfully
exit 0
