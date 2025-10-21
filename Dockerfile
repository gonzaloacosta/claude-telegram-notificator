# ABOUTME: Multi-stage Dockerfile for building the Claude-Telegram notificator with uv.
# ABOUTME: Creates an optimized production image with minimal dependencies.

# Build stage
FROM ghcr.io/astral-sh/uv:python3.10-bookworm-slim as builder

WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies to a virtual environment
RUN uv sync --frozen --no-cache --no-dev

# Production stage
FROM python:3.10-slim-bookworm

# Install uv and curl for health checks
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash app

WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder /app/.venv /app/.venv

# Copy application code
COPY --chown=app:app src ./src
COPY --chown=app:app hooks ./hooks

# Create config directory
RUN mkdir -p /home/app/.claude-telegram && chown -R app:app /home/app/.claude-telegram

# Switch to non-root user
USER app

# Activate virtual environment
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONPATH="/app"

# Expose API port
EXPOSE 9999

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:9999/health || exit 1

# Run the application using uv (ensures venv is used)
CMD ["uv", "run", "python", "-m", "src.main"]
