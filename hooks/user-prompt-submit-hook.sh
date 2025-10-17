#!/bin/bash
# ABOUTME: Claude Code hook script that triggers before user prompt submission.
# ABOUTME: Sends notification to Telegram about the prompt being sent to Claude.

# This script is called by Claude Code with the following environment:
# - CLAUDE_HOOK_TYPE: The type of hook
# - CLAUDE_PROJECT_PATH: Path to the current project
# - STDIN: Contains the prompt content

# Configuration
API_URL="${CLAUDE_TELEGRAM_API_URL:-http://localhost:8000}"
PROJECT_PATH="${CLAUDE_PROJECT_PATH:-$(pwd)}"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

# Read the prompt from stdin
PROMPT=$(cat)

# Only send notification if prompt is substantial (more than 10 chars)
if [ ${#PROMPT} -lt 10 ]; then
  echo "$PROMPT"
  exit 0
fi

# Prepare notification message
MESSAGE="📝 New prompt submitted in project: **${PROJECT_NAME}**\n\nPrompt preview: ${PROMPT:0:200}..."

# Send to API (non-blocking, don't wait for response)
curl -s -X POST "${API_URL}/hooks/event" \
  -H "Content-Type: application/json" \
  -d "{
        \"hook_type\": \"user-prompt-submit\",
        \"project_path\": \"${PROJECT_PATH}\",
        \"project_name\": \"${PROJECT_NAME}\",
        \"message\": \"${MESSAGE}\",
        \"requires_response\": false,
        \"context\": {
            \"prompt_length\": ${#PROMPT}
        }
    }" &

# Return the original prompt unchanged
echo "$PROMPT"
