# ABOUTME: FastAPI application for receiving Claude hook events and managing notifications.
# ABOUTME: Provides REST endpoints for hooks, project management, and health checks.

import logging
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from src.bot import telegram_bot
from src.config import projects_manager, settings
from src.models import HookEvent, HookResponse, ResponseType

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle (startup/shutdown)."""
    # Startup
    logger.info("Starting Claude-Telegram Notificator API")
    await telegram_bot.start()
    logger.info(f"API listening on {settings.api_host}:{settings.api_port}")
    yield
    # Shutdown
    logger.info("Shutting down API")
    await telegram_bot.stop()


# Create FastAPI app
app = FastAPI(
    title="Claude-Telegram Notificator",
    description="API for managing Claude Code notifications via Telegram",
    version="0.1.0",
    lifespan=lifespan,
)

# Add CORS middleware for future web UI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "service": "claude-telegram-notificator",
        "version": "0.1.0",
        "status": "running",
    }


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "bot_running": telegram_bot.is_running,
        "notifications_enabled": settings.enable_notifications,
    }


@app.post("/hooks/event", response_model=HookResponse)
async def receive_hook_event(event: HookEvent):
    """
    Receive a hook event from Claude Code and send to Telegram.

    This is the main endpoint called by Claude hooks.
    """
    logger.info(f"Received hook event: {event.hook_type} from {event.project_path}")

    # Check if notifications are enabled for this project
    if not projects_manager.is_project_enabled(event.project_path):
        logger.info(f"Notifications disabled for project: {event.project_path}")
        return HookResponse(
            success=True,
            response_type=ResponseType.NO,
            message="Notifications disabled for this project",
        )

    # Get chat ID for the project
    chat_id = projects_manager.get_chat_id(event.project_path)
    if not chat_id:
        logger.error("No Telegram chat ID configured")
        raise HTTPException(
            status_code=500,
            detail="No Telegram chat ID configured. Run /start with the bot.",
        )

    # Generate session ID if needed
    session_id = event.session_id or str(uuid.uuid4())

    try:
        # Send notification to Telegram
        telegram_response = await telegram_bot.send_notification(
            chat_id=chat_id,
            message=event.message,
            session_id=session_id,
            requires_response=event.requires_response,
        )

        # If no response required, return success
        if not event.requires_response or not telegram_response:
            return HookResponse(
                success=True,
                response_type=ResponseType.YES,
                message="Notification sent",
            )

        # Return the user's response
        return HookResponse(
            success=True,
            response_type=telegram_response.response_type,
            message=telegram_response.message,
        )

    except Exception as e:
        logger.error(f"Error sending notification: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/projects")
async def list_projects():
    """List all configured projects."""
    return {
        "projects": [
            {
                "path": project.project_path,
                "name": project.name,
                "enabled": project.enabled,
                "chat_id": project.telegram_chat_id,
            }
            for project in projects_manager.projects.values()
        ]
    }


@app.post("/projects/add")
async def add_project(project_path: str, name: str, enabled: bool = True):
    """Add a new project configuration."""
    projects_manager.add_project(project_path, name, enabled)
    return {"success": True, "message": f"Project '{name}' added"}


@app.post("/projects/{project_path:path}/enable")
async def enable_project(project_path: str):
    """Enable notifications for a project."""
    projects_manager.enable_project(project_path)
    return {"success": True, "message": f"Project enabled: {project_path}"}


@app.post("/projects/{project_path:path}/disable")
async def disable_project(project_path: str):
    """Disable notifications for a project."""
    projects_manager.disable_project(project_path)
    return {"success": True, "message": f"Project disabled: {project_path}"}


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
