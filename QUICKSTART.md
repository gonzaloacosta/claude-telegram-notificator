# Quick Start Guide

This guide will get you up and running in 5 minutes!

## Prerequisites

- Telegram account
- Docker (or Python 3.10+ with uv)

## Step 1: Create Telegram Bot (2 minutes)

1. Open Telegram, search for **@BotFather**
2. Send: `/newbot`
3. Choose a name: `My Claude Notificator`
4. Choose a username: `my_claude_bot` (must end in `bot`)
5. **Save the token** you receive (looks like: `123456:ABC-DEF...`)
6. Click on your bot link and send: `/start`
7. **Save your chat ID** from the bot's response

## Step 2: Configure (1 minute)

```bash
# Clone and setup
git clone https://github.com/gonzaloacosta/claude-telegram-notificator.git
cd claude-telegram-notificator

# Run automated setup
./setup.sh
```

The setup script will:
- Create `.env` file
- Ask for your bot token and chat ID
- Let you choose Docker or local deployment
- Install Claude hooks automatically

## Step 3: Test (1 minute)

1. Open Claude Code in any project
2. Type a prompt: "Hello Claude!"
3. Send it
4. Check your Telegram - you should see a notification! 🎉

## Troubleshooting

**Not receiving notifications?**

```bash
# Check if service is running
curl http://localhost:8000/health

# View logs
docker-compose logs -f notificator  # for Docker
# OR check console output for local
```

**Hooks not working?**

```bash
# Verify installation
ls -la ~/.claude/hooks/

# Test manually
echo "test" | ~/.claude/hooks/user-prompt-submit-hook
```

**Need to change settings?**

Edit the `.env` file:
```bash
nano .env
# Change values, then restart:
docker-compose restart  # for Docker
# OR Ctrl+C and restart for local
```

## What's Next?

- Disable notifications for specific projects via API
- Check out the full README.md for advanced features
- Explore the CLAUDE.md for development details

## Getting Help

- Check README.md for detailed documentation
- Open an issue on GitHub
- Review logs for error messages
