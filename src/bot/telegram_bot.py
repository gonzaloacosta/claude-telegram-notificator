# ABOUTME: Telegram bot implementation for sending notifications and receiving user responses.
# ABOUTME: Uses python-telegram-bot library with async support for real-time communication.

import asyncio
import logging
import time
from typing import Dict, Optional

from telegram import InlineKeyboardButton, InlineKeyboardMarkup, Update
from telegram.ext import Application, CallbackQueryHandler, CommandHandler, ContextTypes

from src.config import settings
from src.models import ResponseType, TelegramResponse

logger = logging.getLogger(__name__)


class TelegramBot:
    """Manages Telegram bot for sending notifications and receiving responses."""

    def __init__(self):
        self.app: Optional[Application] = None
        self.pending_responses: Dict[str, asyncio.Future] = {}
        self.is_running = False

    async def start(self) -> None:
        """Start the Telegram bot."""
        if self.is_running:
            logger.warning("Bot is already running")
            return

        self.app = Application.builder().token(settings.telegram_bot_token).build()

        # Add handlers
        self.app.add_handler(CommandHandler("start", self._handle_start))
        self.app.add_handler(CommandHandler("status", self._handle_status))
        self.app.add_handler(CallbackQueryHandler(self._handle_button_response))

        # Start the bot
        await self.app.initialize()
        await self.app.start()
        await self.app.updater.start_polling()
        self.is_running = True
        logger.info("Telegram bot started successfully")

    async def stop(self) -> None:
        """Stop the Telegram bot."""
        if not self.is_running or not self.app:
            return

        await self.app.updater.stop()
        await self.app.stop()
        await self.app.shutdown()
        self.is_running = False
        logger.info("Telegram bot stopped")

    async def _handle_start(
        self, update: Update, context: ContextTypes.DEFAULT_TYPE
    ) -> None:
        """Handle /start command."""
        if not update.message:
            return

        chat_id = update.message.chat_id
        await update.message.reply_text(
            f"👋 Hello! I'm your Claude Code notificator.\n\n"
            f"Your chat ID is: `{chat_id}`\n\n"
            f"Add this to your .env file:\n"
            f"```\nTELEGRAM_CHAT_ID={chat_id}\n```",
            parse_mode="Markdown",
        )

    async def _handle_status(
        self, update: Update, context: ContextTypes.DEFAULT_TYPE
    ) -> None:
        """Handle /status command."""
        if not update.message:
            return

        pending_count = len(self.pending_responses)
        await update.message.reply_text(
            f"🤖 Claude-Telegram Notificator Status\n\n"
            f"✅ Bot is running\n"
            f"📬 Pending responses: {pending_count}\n"
            f"🔔 Notifications: {'Enabled' if settings.enable_notifications else 'Disabled'}"
        )

    async def _handle_button_response(
        self, update: Update, context: ContextTypes.DEFAULT_TYPE
    ) -> None:
        """Handle button click responses."""
        query = update.callback_query
        if not query or not query.data:
            return

        await query.answer()

        # Parse callback data: "session_id:response_type"
        parts = query.data.split(":", 1)
        if len(parts) != 2:
            return

        session_id, response_value = parts

        # Determine response type
        if response_value == "yes":
            response_type = ResponseType.YES
            message = None
        elif response_value == "no":
            response_type = ResponseType.NO
            message = None
        else:
            response_type = ResponseType.CUSTOM
            message = response_value

        # Create response object
        response = TelegramResponse(
            response_type=response_type,
            message=message,
            session_id=session_id,
            timestamp=time.time(),
        )

        # Resolve the pending future if exists
        if session_id in self.pending_responses:
            future = self.pending_responses[session_id]
            if not future.done():
                future.set_result(response)

        # Update message
        emoji = "✅" if response_type == ResponseType.YES else "❌"
        await query.edit_message_text(
            f"{emoji} Response received: {response_type.value}"
        )

    async def send_notification(
        self,
        chat_id: str,
        message: str,
        session_id: Optional[str] = None,
        requires_response: bool = False,
    ) -> Optional[TelegramResponse]:
        """
        Send a notification to Telegram.

        Args:
            chat_id: Telegram chat ID to send to
            message: Message text to send (already formatted)
            session_id: Optional session ID for tracking responses
            requires_response: Whether to wait for user response

        Returns:
            TelegramResponse if requires_response=True, None otherwise
        """
        if not self.app:
            raise RuntimeError("Bot is not started")

        # Create inline keyboard if response is required
        reply_markup = None
        if requires_response and session_id:
            keyboard = [
                [
                    InlineKeyboardButton("✅ Yes", callback_data=f"{session_id}:yes"),
                    InlineKeyboardButton("❌ No", callback_data=f"{session_id}:no"),
                ]
            ]
            reply_markup = InlineKeyboardMarkup(keyboard)

        # Send message
        await self.app.bot.send_message(
            chat_id=chat_id,
            text=message,
            reply_markup=reply_markup,
            parse_mode="Markdown",
        )

        logger.info(f"Sent notification to chat {chat_id}")

        # Wait for response if required
        if requires_response and session_id:
            return await self._wait_for_response(session_id)

        return None

    async def _wait_for_response(self, session_id: str) -> TelegramResponse:
        """
        Wait for a user response with timeout.

        Args:
            session_id: Session ID to wait for

        Returns:
            TelegramResponse object
        """
        # Create a future for this response
        future: asyncio.Future = asyncio.Future()
        self.pending_responses[session_id] = future

        try:
            # Wait for response with timeout
            response = await asyncio.wait_for(future, timeout=settings.response_timeout)
            return response
        except asyncio.TimeoutError:
            logger.warning(f"Response timeout for session {session_id}")
            return TelegramResponse(
                response_type=ResponseType.TIMEOUT,
                message=None,
                session_id=session_id,
                timestamp=time.time(),
            )
        finally:
            # Clean up
            self.pending_responses.pop(session_id, None)


# Global bot instance
telegram_bot = TelegramBot()
