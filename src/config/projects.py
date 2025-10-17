# ABOUTME: Project configuration management for enabling/disabling notifications per project.
# ABOUTME: Supports per-project chat IDs and feature toggles for future expansion.

import json
from pathlib import Path
from typing import Dict, Optional

from pydantic import BaseModel, Field

from src.config.settings import settings


class ProjectConfig(BaseModel):
    """Configuration for a specific project."""

    name: str = Field(description="Project name")
    enabled: bool = Field(default=True, description="Enable notifications for project")
    telegram_chat_id: Optional[str] = Field(
        default=None, description="Project-specific Telegram chat ID"
    )
    project_path: str = Field(description="Absolute path to project directory")


class ProjectsManager:
    """Manages project configurations for the notificator."""

    def __init__(self, config_path: Optional[Path] = None):
        self.config_path = config_path or settings.projects_config_path
        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        self.projects: Dict[str, ProjectConfig] = {}
        self.load()

    def load(self) -> None:
        """Load projects configuration from disk."""
        if self.config_path.exists():
            with open(self.config_path, "r") as f:
                data = json.load(f)
                self.projects = {
                    key: ProjectConfig(**value) for key, value in data.items()
                }
        else:
            self.projects = {}
            self.save()

    def save(self) -> None:
        """Save projects configuration to disk."""
        with open(self.config_path, "w") as f:
            data = {key: value.model_dump() for key, value in self.projects.items()}
            json.dump(data, f, indent=2)

    def get_project(self, project_path: str) -> Optional[ProjectConfig]:
        """Get configuration for a specific project."""
        return self.projects.get(project_path)

    def is_project_enabled(self, project_path: str) -> bool:
        """Check if notifications are enabled for a project."""
        project = self.get_project(project_path)
        if project is None:
            # Auto-enable new projects by default
            return settings.enable_notifications
        return project.enabled and settings.enable_notifications

    def add_project(self, project_path: str, name: str, enabled: bool = True) -> None:
        """Add or update a project configuration."""
        self.projects[project_path] = ProjectConfig(
            name=name, enabled=enabled, project_path=project_path
        )
        self.save()

    def disable_project(self, project_path: str) -> None:
        """Disable notifications for a project."""
        if project_path in self.projects:
            self.projects[project_path].enabled = False
            self.save()

    def enable_project(self, project_path: str) -> None:
        """Enable notifications for a project."""
        if project_path in self.projects:
            self.projects[project_path].enabled = True
            self.save()

    def get_chat_id(self, project_path: str) -> Optional[str]:
        """Get the Telegram chat ID for a project (falls back to default)."""
        project = self.get_project(project_path)
        if project and project.telegram_chat_id:
            return project.telegram_chat_id
        return settings.telegram_chat_id


# Global projects manager instance
projects_manager = ProjectsManager()
