#!/bin/bash
# ABOUTME: Quick setup script for the Claude-Telegram notificator.
# ABOUTME: Automates environment setup and provides guided configuration.

set -e

echo "🚀 Claude-Telegram Notificator Setup"
echo "======================================"
echo ""

# Flag to track if we need to configure .env
CONFIGURE_ENV=true

# Check if .env exists
if [ -f .env ]; then
    echo "✅ .env file already exists"
    read -p "Do you want to reconfigure it? (y/N): " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env file"
        CONFIGURE_ENV=false
    else
        cp .env.example .env
        echo "✅ Created new .env file from template"
    fi
else
    cp .env.example .env
    echo "✅ Created .env file from template"
fi

# Only configure if needed
if [ "$CONFIGURE_ENV" = true ]; then
    echo ""
    echo "📝 Configuration Steps:"
    echo ""
    echo "1. Create a Telegram Bot:"
    echo "   - Open Telegram and find @BotFather"
    echo "   - Send: /newbot"
    echo "   - Follow instructions and save your bot token"
    echo ""
    echo "2. Get your Chat ID:"
    echo "   - Start a chat with your new bot"
    echo "   - Send: /start"
    echo "   - The bot will reply with your chat ID"
    echo ""

    read -p "Press Enter when you have your bot token and chat ID..."

    echo ""
    read -p "Enter your Telegram Bot Token: " bot_token
    read -p "Enter your Telegram Chat ID: " chat_id

    # Update .env file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=${bot_token}|" .env
        sed -i '' "s|TELEGRAM_CHAT_ID=.*|TELEGRAM_CHAT_ID=${chat_id}|" .env
    else
        # Linux
        sed -i "s|TELEGRAM_BOT_TOKEN=.*|TELEGRAM_BOT_TOKEN=${bot_token}|" .env
        sed -i "s|TELEGRAM_CHAT_ID=.*|TELEGRAM_CHAT_ID=${chat_id}|" .env
    fi

    echo ""
    echo "✅ .env file updated with your credentials"
fi
echo ""
echo "🔧 Choose your deployment method:"
echo "1) Docker Compose (recommended)"
echo "2) Local with uv"
echo ""
read -p "Enter choice (1 or 2): " choice

case $choice in
    1)
        echo ""
        echo "🐳 Starting with Docker Compose..."
        docker-compose up -d
        echo ""
        echo "✅ Service started! Check logs with:"
        echo "   docker-compose logs -f notificator"
        ;;
    2)
        echo ""
        echo "🐍 Setting up local environment..."
        if ! command -v uv &> /dev/null; then
            echo "❌ uv is not installed. Please install it first:"
            echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
            exit 1
        fi
        uv sync
        echo ""
        echo "✅ Dependencies installed! Start the server with:"
        echo "   uv run python -m src.main"
        ;;
    *)
        echo "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "🎣 Installing Claude hooks..."
./hooks/install-hooks.sh

echo ""
echo "✅ Setup complete!"
echo ""
echo "🎉 Next steps:"
echo "1. Open Claude Code in any project"
echo "2. Send a prompt"
echo "3. Check your Telegram for notifications!"
echo ""
echo "📚 For more information, see README.md"
