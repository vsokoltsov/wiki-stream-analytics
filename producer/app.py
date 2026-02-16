import asyncio
import logging
from typing import Optional

from aiokafka import AIOKafkaProducer
from producer.settings import get_producer_settings
from producer.service import WikipediaProducerService
from producer.wiki_client import WikiClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("wiki-producer")


async def main() -> None:
    settings = get_producer_settings()
    client = WikiClient(
        url=settings.WIKI_SSE_URL,
        user_agent=settings.WIKI_USER_AGENT,
        timeout=settings.WIKI_DEFAULT_TIMEOUT,
    )
    producer = AIOKafkaProducer(bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS)
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
