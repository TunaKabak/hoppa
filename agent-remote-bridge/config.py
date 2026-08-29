import os
from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field


class BridgeSettings(BaseSettings):
    """Configuration settings for Remote Agent Bridge."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    TELEGRAM_BOT_TOKEN: str = Field(
        default="",
        description="Telegram bot token obtained from @BotFather",
    )
    GEMINI_API_KEY: str = Field(
        default="",
        description="Gemini API Key for autonomous code writing and tool execution",
    )
    ALLOWED_USER_ID: str | int = Field(
        default="",
        description="Allowed Telegram User ID(s), single int or comma-separated",
    )
    AGENT_WORKING_DIR: str = Field(
        default=str(Path(__file__).resolve().parent.parent),
        description="Root working directory of the Hoppa workspace",
    )
    COMMAND_TIMEOUT: int = Field(
        default=300,
        description="Timeout in seconds for running commands",
    )
    LOG_LEVEL: str = Field(
        default="INFO",
        description="Logging level",
    )

    @property
    def allowed_user_ids(self) -> set[int]:
        """Parse ALLOWED_USER_ID into a set of integers."""
        if isinstance(self.ALLOWED_USER_ID, int):
            return {self.ALLOWED_USER_ID} if self.ALLOWED_USER_ID > 0 else set()

        raw = str(self.ALLOWED_USER_ID).strip()
        if not raw:
            return set()

        ids: set[int] = set()
        for item in raw.split(","):
            cleaned = item.strip().strip('"').strip("'")
            if cleaned.isdigit():
                ids.add(int(cleaned))
        return ids

    @property
    def is_configured(self) -> bool:
        """Check if essential configuration is present."""
        token = self.TELEGRAM_BOT_TOKEN.strip().strip('"').strip("'")
        return bool(
            token
            and token != "1. ADIMDA ALDIĞINIZ TOKEN"
            and "YOUR_TELEGRAM_BOT_TOKEN" not in token
        )


settings = BridgeSettings()
