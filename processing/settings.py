from typing import Optional
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class ProcessingSettings(BaseSettings):
    KAFKA_BOOTSTRAP_SERVERS: str = "kafka:9092"
    KAFKA_TOPIC: str = "recentchange_raw"
    KAFKA_MODE: str
    KAFKA_SASL_USERNAME_PROCESSING: Optional[str] = None
    GCS_BUCKET: str
    KAFKA_GROUP_ID: str

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )


@lru_cache(maxsize=1)
def get_processing_settings() -> ProcessingSettings:
    return ProcessingSettings()  # type: ignore[call-arg]
