#!/bin/bash
# ABOUTME: Claude Code hook script that triggers before user prompt submission.
# ABOUTME: Sends notification to Telegram about the prompt being sent to Claude.

# This script is called by Claude Code with the following environment:
# - CLAUDE_HOOK_TYPE: The type of hook
# - CLAUDE_PROJECT_PATH: Path to the current project
# - STDIN: Contains the prompt content

# Configuration
API_URL="${CLAUDE_TELEGRAM_API_URL:-http://localhost:9999}"
PROJECT_PATH="${CLAUDE_PROJECT_PATH:-$(pwd)}"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

# Read the prompt from stdin
PROMPT=$(cat)

# Return the original prompt unchanged (must happen before background task)
echo "$PROMPT"

# Only send notification if prompt is substantial (more than 10 chars)
if [ ${#PROMPT} -lt 10 ]; then
  exit 0
fi

# Send to API (non-blocking, properly detached)
# Use jq to properly escape JSON values
(JSON_PAYLOAD=$(jq -n \
    --arg hook_type "user-prompt-submit" \
    --arg project_path "$PROJECT_PATH" \
    --arg project_name "$PROJECT_NAME" \
    --argjson prompt_length "${#PROMPT}" \
    '{
        hook_type: $hook_type,
        project_path: $project_path,
        project_name: $project_name,
        message: "",
        requires_response: false,
        context: {
            prompt_length: $prompt_length
        }
    }')

curl -s -X POST "${API_URL}/hooks/event" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" > /dev/null 2>&1 &)

# Exit successfully
exit 0
