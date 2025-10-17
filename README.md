# Claude-Telegram Notificator

Get real-time notifications from Claude Code on your phone via Telegram! This tool bridges Claude Code with Telegram, allowing you to monitor Claude's activity and even respond to prompts from your mobile device.

## Features

- **Real-time Notifications**: Get instant notifications when Claude processes your prompts
- **Per-Project Control**: Enable/disable notifications for specific projects
- **Interactive Responses**: Respond to Claude prompts directly from Telegram (Yes/No/Custom)
- **Easy Setup**: Simple installation with Docker or local Python environment
- **Expandable Architecture**: Designed to scale from local laptop to cloud deployment
- **Privacy-Focused**: All data stays on your machine (unless you choose to deploy to cloud)

## Architecture

```
┌──────────────┐
│ Claude Code  │
│ (Hooks)      │
└──────┬───────┘
       │ HTTP
       v
┌──────────────┐
│ FastAPI      │
│ Server       │
└──────┬───────┘
       │
       v
┌──────────────┐
│ Telegram Bot │
└──────┬───────┘
       │
       v
┌──────────────┐
│ Your Phone   │
└──────────────┘
```

## Quick Start

### Prerequisites

- Python 3.10+ (for local development)
- Docker & Docker Compose (for containerized deployment)
- A Telegram account
- Claude Code installed

### 1. Create Your Telegram Bot

1. Open Telegram and find [@BotFather](https://t.me/BotFather)
2. Send \`/newbot\` and follow the instructions
3. Save the bot token you receive
4. Start a chat with your new bot
5. Send \`/start\` to get your chat ID

### 2. Clone and Configure

\`\`\`bash
git clone https://github.com/gonzaloacosta/claude-telegram-notificator.git
cd claude-telegram-notificator
cp .env.example .env
nano .env
\`\`\`

### 3. Choose Your Deployment Method

#### Option A: Docker Compose (Recommended)

\`\`\`bash
docker-compose up -d
docker-compose logs -f notificator
\`\`\`

#### Option B: Local Development with uv

\`\`\`bash
uv sync
uv run python -m src.main
\`\`\`

### 4. Install Claude Hooks

\`\`\`bash
./hooks/install-hooks.sh
\`\`\`

### 5. Test It Out

1. Open Claude Code in any project
2. Type a prompt and send it
3. Check your Telegram - you should receive a notification!

## Usage

### Managing Projects

\`\`\`bash
# List all projects
curl http://localhost:8000/projects

# Add a project
curl -X POST "http://localhost:8000/projects/add?project_path=/path/to/project&name=MyProject"

# Disable/Enable notifications
curl -X POST "http://localhost:8000/projects/%2Fpath%2Fto%2Fproject/disable"
curl -X POST "http://localhost:8000/projects/%2Fpath%2Fto%2Fproject/enable"
\`\`\`

### Telegram Commands

- \`/start\` - Get your chat ID and bot information
- \`/status\` - Check bot status and pending responses

## Development

\`\`\`bash
# Run tests
uv run pytest

# Format and lint
uv run ruff format .
uv run ruff check .
\`\`\`

## License

MIT License
