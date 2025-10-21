# Claude Code Hooks Guide

## Overview

Claude Code supports a powerful hook system that allows you to run custom scripts at specific events during Claude's operation. This enables integration with external services like Telegram, logging systems, monitoring tools, and more.

## Hook Architecture

### How Hooks Work

1. **Event Triggers**: When specific events occur in Claude Code (e.g., user prompt, assistant message, notification)
2. **Matcher Evaluation**: Claude checks if the event matches configured patterns
3. **Hook Execution**: Matching hooks execute sequentially
4. **Data Flow**: Event data flows through stdin, hooks can process it, and must return it unchanged

### Hook Locations

Claude Code searches for hooks in two locations (in order):

1. **Project Hooks**: `<project-root>/.claude/hooks/` (project-specific)
2. **Global Hooks**: `~/.claude/hooks/` (applies to all projects)

### Configuration Files

Hooks are configured in:
- **Global Settings**: `~/.claude/settings.json`
- **Project Settings**: `<project-root>/.claude/settings.json`

## Available Hook Types

Claude Code supports the following hook event types:

### 1. `user-prompt-submit-hook`
**When**: Before a user's prompt is sent to Claude
**Input (stdin)**: The user's prompt text
**Use Cases**:
- Log user prompts
- Send notifications when questions are asked
- Track conversation starts
- Analyze prompt patterns

**Example**:
```json
{
  "hooks": {
    "user-prompt-submit-hook": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/user-prompt-submit-hook"
          }
        ]
      }
    ]
  }
}
```

### 2. `assistant-message-hook`
**When**: After Claude sends a response message
**Input (stdin)**: Claude's response text
**Use Cases**:
- Monitor Claude's responses
- Send notifications about completions
- Log responses for auditing
- Track conversation flow

**Example**:
```json
{
  "hooks": {
    "assistant-message-hook": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/assistant-message-hook"
          }
        ]
      }
    ]
  }
}
```

### 3. `Notification`
**When**: Claude shows a notification to the user
**Input (stdin)**: The notification message text
**Use Cases**:
- Forward Claude notifications to external systems
- Play sounds or show system notifications
- Log important events
- Alert team members

**Example**:
```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff"
          },
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/notification-hook"
          }
        ]
      }
    ]
  }
}
```

### 4. `Stop`
**When**: Claude stops processing or encounters an error
**Input (stdin)**: Stop reason or error message
**Use Cases**:
- Alert on errors or interruptions
- Monitor system health
- Track when Claude stops
- Debug issues

**Example**:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/stop-hook"
          }
        ]
      }
    ]
  }
}
```

## Hook Configuration Structure

### Basic Structure

```json
{
  "hooks": {
    "<hook-type>": [
      {
        "matcher": "<regex-pattern>",
        "hooks": [
          {
            "type": "command",
            "command": "<shell-command>"
          }
        ]
      }
    ]
  }
}
```

### Fields Explained

- **`<hook-type>`**: The event type (e.g., `Notification`, `Stop`, `user-prompt-submit-hook`)
- **`matcher`**: A regex pattern to filter which events trigger the hook
  - `".*"` matches all events
  - `"error.*"` matches events starting with "error"
  - `".*important.*"` matches events containing "important"
- **`type`**: Always `"command"` for shell commands
- **`command`**: The shell command to execute

### Multiple Hooks Per Event

You can configure multiple hooks for a single event. They execute in order:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "afplay /System/Library/Sounds/Glass.aiff"
          },
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/notification-hook"
          },
          {
            "type": "command",
            "command": "logger -t claude 'Notification received'"
          }
        ]
      }
    ]
  }
}
```

### Conditional Hooks with Matchers

Use different matchers to create conditional behavior:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": ".*error.*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/error-notification-hook"
          }
        ]
      },
      {
        "matcher": ".*success.*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/success-notification-hook"
          }
        ]
      }
    ]
  }
}
```

## Writing Hook Scripts

### Best Practices

1. **Always Return Input Unchanged**:
   ```bash
   INPUT=$(cat)
   echo "$INPUT"  # Return immediately
   # Then do your work...
   ```

2. **Use Background Processes for I/O**:
   ```bash
   # Return input first
   echo "$INPUT"

   # Run API calls in background
   (curl -X POST ... > /dev/null 2>&1 &)
   ```

3. **Proper JSON Escaping**:
   ```bash
   # Use jq for JSON construction
   JSON=$(jq -n --arg msg "$MESSAGE" '{message: $msg}')
   curl -d "$JSON" ...
   ```

4. **Environment Variables**:
   ```bash
   PROJECT_PATH="${CLAUDE_PROJECT_PATH:-$(pwd)}"
   PROJECT_NAME="$(basename "$PROJECT_PATH")"
   ```

5. **Error Handling**:
   ```bash
   set -e  # Exit on error (optional)
   # Or handle errors gracefully
   if ! curl ...; then
       logger -t claude "Hook failed"
   fi
   ```

### Template Hook Script

```bash
#!/bin/bash
# ABOUTME: Hook description line 1
# ABOUTME: Hook description line 2

# Configuration
API_URL="${CLAUDE_TELEGRAM_API_URL:-http://localhost:9999}"
PROJECT_PATH="${CLAUDE_PROJECT_PATH:-$(pwd)}"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

# Read input from stdin
INPUT=$(cat)

# Return the original input unchanged (CRITICAL!)
echo "$INPUT"

# Only process if input is substantial
if [ ${#INPUT} -lt 10 ]; then
    exit 0
fi

# Prepare your message
MESSAGE="Your formatted message: ${INPUT:0:100}..."

# Send to external service (non-blocking)
(JSON_PAYLOAD=$(jq -n \
    --arg message "$MESSAGE" \
    --arg project "$PROJECT_NAME" \
    '{
        message: $message,
        project: $project
    }')

curl -s -X POST "${API_URL}/endpoint" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" > /dev/null 2>&1 &)
```

## Telegram Integration Hooks

This project includes hooks for Telegram integration:

### Installed Hooks

1. **`user-prompt-submit-hook`**: Notifies Telegram when you ask Claude a question
2. **`assistant-message-hook`**: Notifies Telegram when Claude responds
3. **`notification-hook`**: Forwards Claude notifications to Telegram
4. **`stop-hook`**: Alerts Telegram when Claude stops

### Installation

```bash
cd /path/to/claude-telegram-notificator
./hooks/install-hooks.sh
```

This copies all hook scripts to `~/.claude/hooks/` and makes them executable.

### Configuration

The hooks are already configured in your `~/.claude/settings.json`. Each hook:
- Reads event data from stdin
- Returns it unchanged to Claude
- Sends notification to FastAPI server (localhost:9999)
- FastAPI forwards to Telegram bot

### Environment Variables

- `CLAUDE_TELEGRAM_API_URL`: API endpoint (default: http://localhost:9999)
- `CLAUDE_PROJECT_PATH`: Current project path (set by Claude)
- `CLAUDE_HOOK_TYPE`: Hook type being triggered (set by Claude)

## Debugging Hooks

### Test a Hook Manually

```bash
echo "test message" | ~/.claude/hooks/notification-hook
```

### Check Hook Output

Remove `> /dev/null 2>&1` temporarily to see errors:

```bash
# Before (silent)
curl ... > /dev/null 2>&1 &

# After (shows errors)
curl ... &
```

### Verify Hook Installation

```bash
ls -lah ~/.claude/hooks/
```

Expected output:
```
-rwxr-xr-x  user  staff  notification-hook
-rwxr-xr-x  user  staff  stop-hook
-rwxr-xr-x  user  staff  user-prompt-submit-hook
-rwxr-xr-x  user  staff  assistant-message-hook
```

### Check Settings Configuration

```bash
cat ~/.claude/settings.json | jq '.hooks'
```

## Common Issues

### Hook Not Triggering

1. **Check matcher**: Ensure regex pattern matches your event
2. **Check permissions**: Hooks must be executable (`chmod +x`)
3. **Check location**: Hooks must be in `~/.claude/hooks/` or `<project>/.claude/hooks/`
4. **Check settings**: Verify JSON syntax in settings.json

### Hook Fails Silently

1. **Remove error suppression**: Remove `> /dev/null 2>&1`
2. **Add logging**: Use `logger -t claude "message"`
3. **Test manually**: Run hook script directly with test input

### JSON Errors

1. **Use jq**: Always use `jq` for JSON construction
2. **Escape properly**: Never embed variables directly in JSON strings
3. **Test JSON**: Validate with `echo "$JSON" | jq .`

## Advanced Use Cases

### Logging All Events

```bash
#!/bin/bash
INPUT=$(cat)
echo "$INPUT"

# Log to file
echo "$(date): $INPUT" >> ~/.claude/event-log.txt
```

### Conditional Notifications

```bash
#!/bin/bash
INPUT=$(cat)
echo "$INPUT"

# Only notify for long responses
if [ ${#INPUT} -gt 500 ]; then
    # Send notification
fi
```

### Multi-Service Integration

```bash
#!/bin/bash
INPUT=$(cat)
echo "$INPUT"

# Send to multiple services
(curl -X POST https://slack.com/api/... &)
(curl -X POST https://api.telegram.org/... &)
(curl -X POST https://discord.com/api/... &)
```

### Analytics and Metrics

```bash
#!/bin/bash
INPUT=$(cat)
echo "$INPUT"

# Track metrics
WORD_COUNT=$(echo "$INPUT" | wc -w)
curl -X POST https://metrics.example.com/api/track \
    -d "{\"event\": \"claude_response\", \"word_count\": $WORD_COUNT}"
```

## Summary

Claude Code hooks enable powerful integration with external systems. Key points:

1. **Hook Types**: `user-prompt-submit-hook`, `assistant-message-hook`, `Notification`, `Stop`
2. **Configuration**: JSON in `~/.claude/settings.json`
3. **Data Flow**: stdin → process → stdout (unchanged)
4. **Best Practices**: Return input immediately, use background processes, escape JSON with jq
5. **Telegram Integration**: This project provides ready-to-use hooks for Telegram notifications

For more information, see the [Claude Code documentation](https://docs.claude.com/en/docs/claude-code).
