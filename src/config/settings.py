# ABOUTME: Configuration settings for the Claude-Telegram notificator using pydantic-settings.
# ABOUTME: Manages environment variables, project-specific configs, and feature flags.

from pathlib import Path
from typing import Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables and .env file."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Server settings
    api_host: str = Field(default="0.0.0.0", description="API server host")
    api_port: int = Field(default=8000, description="API server port")
    api_reload: bool = Field(default=False, description="Enable auto-reload in dev")

    # Telegram settings
    telegram_bot_token: str = Field(
        description="Telegram Bot API token from @BotFather"
    )
    telegram_chat_id: Optional[str] = Field(
        default=None, description="Default Telegram chat ID for notifications"
    )

    # Redis settings (optional for PoC)
    redis_host: str = Field(default="localhost", description="Redis host")
    redis_port: int = Field(default=6379, description="Redis port")
    redis_db: int = Field(default=0, description="Redis database number")
    redis_enabled: bool = Field(
        default=False, description="Enable Redis for state management"
    )

    # Feature flags
    enable_notifications: bool = Field(
        default=True, description="Master switch for notifications"
    )
    response_timeout: int = Field(
        default=300, description="Timeout in seconds to wait for Telegram response"
    )

    # Project settings
    projects_config_path: Path = Field(
        default=Path.home() / ".claude-telegram" / "projects.json",
        description="Path to projects configuration file",
    )

    def get_api_url(self) -> str:
        """Get the full API URL."""
        return f"http://{self.api_host}:{self.api_port}"


# Global settings instance
settings = Settings()
