from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class IngestionSettings(BaseSettings):
    PROJECT_ID: str
    GCS_BUCKET: str
    PUBSUB_TOPIC: str
    PUBSUB_SUBSCRIPTION: str
    BQ_DATASET: str
    BQ_TABLE: str

    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )


@lru_cache(maxsize=1)
def get_ingestion_settings() -> IngestionSettings:
    return IngestionSettings()  # type: ignore[call-arg]
