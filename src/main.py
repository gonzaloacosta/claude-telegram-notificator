# ABOUTME: Main entry point for running the FastAPI server with uvicorn.
# ABOUTME: Handles command-line arguments and server configuration.

import uvicorn

from src.config import settings


def main():
    """Run the FastAPI server."""
    uvicorn.run(
        "src.api.app:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=settings.api_reload,
        log_level="info",
    )


if __name__ == "__main__":
    main()
