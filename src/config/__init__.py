# ABOUTME: Configuration module exports for easy imports.
# ABOUTME: Provides centralized access to settings and project management.

from src.config.projects import ProjectsManager, projects_manager
from src.config.settings import Settings, settings

__all__ = ["Settings", "settings", "ProjectsManager", "projects_manager"]
