from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict

class ProducerSettings(BaseSettings):
    WIKI_SSE_URL: str = "https://stream.wikimedia.org/v2/stream/recentchange"
    KAFKA_BOOTSTRAP_SERVERS: str = "kafka:9092"
    KAFKA_TOPIC: str = "recentchange_raw"
    WIKI_USER_AGENT: str

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
    )

@lru_cache(maxsize=1)
def get_producer_settings() -> ProducerSettings:
    return ProducerSettings()