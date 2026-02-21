import os
import ssl
import asyncio
import logging
from typing import Optional

from aiokafka import AIOKafkaProducer
from producer.settings import get_producer_settings
from producer.service import WikipediaProducerService
from producer.wiki_client import WikiClient
from producer.token_provider import GcpAdcTokenProvider

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("wiki-producer")


def build_producer(settings) -> AIOKafkaProducer:
    mode = (
        getattr(settings, "KAFKA_MODE", None) or os.getenv("KAFKA_MODE", "PLAINTEXT")
    ).upper()

    if mode == "PLAINTEXT":
        return AIOKafkaProducer(
            bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        )

    if mode == "GCP_OAUTH":
        ssl_ctx = ssl.create_default_context()

        return AIOKafkaProducer(
            bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
            security_protocol="SASL_SSL",
            ssl_context=ssl_ctx,
            sasl_mechanism="OAUTHBEARER",
            sasl_oauth_token_provider=GcpAdcTokenProvider(),
        )

    raise ValueError(f"Unknown KAFKA_MODE={mode}. Use PLAINTEXT or GCP_OAUTH.")


async def main() -> None:
    settings = get_producer_settings()
    client = WikiClient(
        url=settings.WIKI_SSE_URL,
        user_agent=settings.WIKI_USER_AGENT,
        timeout=settings.WIKI_DEFAULT_TIMEOUT,
    )
    ssl_ctx = ssl.create_default_context()
    producer = AIOKafkaProducer(
        bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        security_protocol="SSL",
        ssl_context=ssl_ctx,
    )
    service = WikipediaProducerService(
        topic_name=settings.KAFKA_TOPIC, producer=producer, client=client
    )
    await producer.start()
    logger.info(
        "Producer started. SSE=%s topic=%s", settings.WIKI_SSE_URL, settings.KAFKA_TOPIC
    )

    last_event_id: Optional[str] = None
    backoff = 1  # seconds, exponential up to max
    attempts = 0
    max_attempts = 3

    try:
        while True:
            try:
                last_event_id: Optional[str] = await service.run(
                    last_event_id=last_event_id
                )
                backoff = 1
                attempts = 0
            except asyncio.CancelledError:
                raise
            except Exception as e:
                attempts += 1
                logger.warning(
                    "Stream failed (%s). Reconnecting in %ss... (attempt %d/%d)",
                    e,
                    backoff,
                    attempts,
                    max_attempts,
                )
                if attempts >= max_attempts:
                    raise RuntimeError(
                        f"Stream failed after {max_attempts} attempts. Last error: {e}"
                    ) from e
                await asyncio.sleep(backoff)
                backoff = min(backoff * 2, 30)
    finally:
        await producer.stop()


if __name__ == "__main__":
    asyncio.run(main())
