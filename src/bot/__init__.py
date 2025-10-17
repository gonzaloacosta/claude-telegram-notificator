# ABOUTME: Bot module exports for Telegram bot functionality.
# ABOUTME: Provides global bot instance for application-wide access.

from src.bot.telegram_bot import TelegramBot, telegram_bot

__all__ = ["TelegramBot", "telegram_bot"]
