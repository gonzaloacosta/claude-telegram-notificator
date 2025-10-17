# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Python-based notification system that bridges Claude Code with Telegram. It allows users to receive real-time notifications from Claude on their phones and respond to prompts remotely. The architecture is designed to start locally but expand to cloud deployments.

## Tech Stack

- **Backend**: FastAPI (async REST API)
- **Bot**: python-telegram-bot (Telegram Bot API)
- **State Management**: Redis (optional, for production)
- **Package Manager**: uv (modern Python package manager)
- **Containerization**: Docker + Docker Compose
- **Data Validation**: Pydantic v2

## Development Commands

### Local Development

```bash
# Install dependencies
uv sync

# Run the server (development mode with reload)
uv run uvicorn src.api.app:app --reload --host 0.0.0.0 --port 8000

# Run the server (production mode)
uv run python -m src.main

# Install Claude hooks
./hooks/install-hooks.sh

# Run tests
uv run pytest

# Run tests with coverage
uv run pytest --cov=src --cov-report=html

# Format code
uv run ruff format .

# Lint code
uv run ruff check .

# Fix linting issues
uv run ruff check . --fix
```

### Docker Deployment

```bash
# Build and start services
docker-compose up -d

# View logs
docker-compose logs -f notificator

# Stop services
docker-compose down

# Rebuild after code changes
docker-compose up -d --build

# Check service health
curl http://localhost:8000/health
```

## Architecture

### Core Components

1. **FastAPI Server** (`src/api/app.py`)
   - Receives hook events from Claude Code
   - Manages project configurations
   - Coordinates between Claude and Telegram

2. **Telegram Bot** (`src/bot/telegram_bot.py`)
   - Sends notifications to users
   - Receives responses (yes/no/custom)
   - Manages conversation state

3. **Configuration System** (`src/config/`)
   - `settings.py`: Environment-based configuration (Pydantic Settings)
   - `projects.py`: Per-project notification management

4. **Data Models** (`src/models/events.py`)
   - `HookEvent`: Events from Claude hooks
   - `TelegramResponse`: Responses from Telegram users
   - `HookResponse`: Responses back to Claude

5. **Claude Hooks** (`hooks/`)
   - Bash scripts that integrate with Claude Code
   - Call FastAPI endpoints on specific events

### Data Flow

```
Claude Hook → FastAPI Endpoint → Check Project Config → Send to Telegram → Wait for Response → Return to Claude
```

### Key Design Patterns

- **Async/Await**: All I/O operations are async for performance
- **Dependency Injection**: FastAPI's DI system for clean architecture
- **Settings Management**: Environment variables with Pydantic Settings
- **Futures for Response Handling**: asyncio.Future objects track pending responses
- **JSON Config Files**: Simple file-based project configuration

## Code Organization

```
src/
├── api/          # FastAPI routes and application setup
├── bot/          # Telegram bot logic and handlers
├── config/       # Configuration management
│   ├── settings.py    # Environment config
│   └── projects.py    # Project-specific config
└── models/       # Pydantic models for type safety
    └── events.py      # Event and response models

hooks/            # Claude Code integration scripts
├── user-prompt-submit-hook.sh
├── assistant-message-hook.sh
└── install-hooks.sh

tests/            # Test suite (pytest)
```

## Important Implementation Details

### Configuration Management

Projects are stored in `~/.claude-telegram/projects.json` with this structure:
```json
{
  "/path/to/project": {
    "name": "Project Name",
    "enabled": true,
    "telegram_chat_id": null,
    "project_path": "/path/to/project"
  }
}
```

### Hook Integration

Claude Code hooks are bash scripts that:
1. Read data from stdin (e.g., user prompt)
2. Send HTTP POST to the FastAPI server
3. Return the original data unchanged

The hooks use environment variables:
- `CLAUDE_TELEGRAM_API_URL`: API endpoint (default: http://localhost:8000)
- `CLAUDE_PROJECT_PATH`: Current project path
- `CLAUDE_HOOK_TYPE`: Type of hook being triggered

### Response Flow

For interactive responses:
1. API creates a unique `session_id`
2. Sends message to Telegram with inline buttons
3. Creates an `asyncio.Future` to track response
4. Waits up to `RESPONSE_TIMEOUT` seconds
5. Returns response or timeout to Claude

### State Management

Current PoC uses in-memory state (dict of Futures). For production with multiple instances, Redis will store:
- Pending response sessions
- Message queue for async processing
- Shared configuration cache

## Extension Points

### Adding New Hooks

1. Create a new hook script in `hooks/`:
   ```bash
   #!/bin/bash
   # New hook logic here
   curl -X POST "${API_URL}/hooks/event" -d '{...}'
   ```

2. Add corresponding handler in `src/api/app.py` if needed

3. Install the hook with `install-hooks.sh`

### Cloud Deployment

The architecture supports cloud deployment by:
1. Running FastAPI + Bot on cloud server
2. Changing `CLAUDE_TELEGRAM_API_URL` in hooks to point to cloud
3. Using Redis for distributed state
4. Adding authentication for remote API calls

For cloud, add these environment variables:
```env
REDIS_ENABLED=true
REDIS_HOST=redis.your-cloud.com
API_HOST=0.0.0.0  # Listen on all interfaces
```

### Adding Web UI

A React + Vite + Tailwind UI would:
1. Call FastAPI endpoints for project management
2. Display notification history
3. Configure per-project settings
4. View statistics

The API already has CORS middleware configured for this.

## Testing Strategy

- **Unit Tests**: Test individual functions and classes
- **Integration Tests**: Test API endpoints with mocked Telegram
- **E2E Tests**: Test full flow from hook to Telegram and back

Mock the Telegram bot in tests to avoid real API calls.

## Common Development Tasks

### Adding a New API Endpoint

1. Add route handler in `src/api/app.py`
2. Create Pydantic models in `src/models/` if needed
3. Add tests in `tests/test_api.py`
4. Update API documentation

### Modifying Notification Format

Edit `src/bot/telegram_bot.py` in `send_notification()` method to customize message formatting.

### Changing Project Config Storage

Currently uses JSON file. To use SQLite or database:
1. Modify `src/config/projects.py`
2. Keep the same interface (`ProjectsManager` class)
3. Update initialization in `src/api/app.py`

## Environment Setup

Required environment variables (see `.env.example`):
- `TELEGRAM_BOT_TOKEN`: From @BotFather
- `TELEGRAM_CHAT_ID`: From `/start` command with bot

Optional but recommended:
- `API_PORT`: Default 8000
- `ENABLE_NOTIFICATIONS`: Master switch
- `RESPONSE_TIMEOUT`: Default 300 seconds

## Debugging Tips

1. **Check service health**: `curl http://localhost:8000/health`
2. **View bot status**: Send `/status` to Telegram bot
3. **Test hooks manually**: `echo "test" | ~/.claude/hooks/user-prompt-submit-hook`
4. **Check project config**: `cat ~/.claude-telegram/projects.json`
5. **View logs**: `docker-compose logs -f` or check console output

## Future Enhancements

The codebase is designed to support:
- Multiple Telegram chats (one per project)
- Custom notification templates
- Rich interactive responses from Telegram
- Notification history and search
- Statistics and analytics
- Role-based access control for teams
- Webhook mode for Telegram (vs. polling)
