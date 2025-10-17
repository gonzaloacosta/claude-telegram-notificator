# ABOUTME: Pydantic models for Claude hook events and Telegram responses.
# ABOUTME: Defines the data structures for communication between Claude, FastAPI, and Telegram.

from enum import Enum
from typing import Any, Dict, Optional

from pydantic import BaseModel, Field


class HookType(str, Enum):
    """Types of Claude hooks."""

    USER_PROMPT_SUBMIT = "user-prompt-submit"
    ASSISTANT_MESSAGE = "assistant-message"
    TOOL_USE = "tool-use"
    CUSTOM = "custom"


class ResponseType(str, Enum):
    """Types of responses from Telegram."""

    YES = "yes"
    NO = "no"
    CUSTOM = "custom"
    TIMEOUT = "timeout"


class HookEvent(BaseModel):
    """Event sent from Claude hook to the API."""

    hook_type: HookType = Field(description="Type of hook event")
    project_path: str = Field(description="Absolute path to the project")
    project_name: Optional[str] = Field(default=None, description="Project name")
    message: str = Field(description="Message to send to Telegram")
    context: Dict[str, Any] = Field(
        default_factory=dict, description="Additional context data"
    )
    requires_response: bool = Field(
        default=False, description="Whether to wait for user response"
    )
    session_id: Optional[str] = Field(
        default=None, description="Session ID for tracking conversations"
    )


class TelegramResponse(BaseModel):
    """Response received from Telegram user."""

    response_type: ResponseType = Field(description="Type of response")
    message: Optional[str] = Field(default=None, description="Custom message if any")
    session_id: str = Field(description="Session ID to match request")
    timestamp: float = Field(description="Unix timestamp of response")


class HookResponse(BaseModel):
    """Response sent back to Claude hook."""

    success: bool = Field(description="Whether the operation was successful")
    response_type: ResponseType = Field(description="Type of response received")
    message: Optional[str] = Field(default=None, description="Response message")
    error: Optional[str] = Field(default=None, description="Error message if any")
