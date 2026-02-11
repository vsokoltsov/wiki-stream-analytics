import asyncio
import json
import logging
import os
from typing import Optional

import aiohttp
from aiokafka import AIOKafkaProducer
from producer.settings import get_producer_settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("wiki-producer")

# SSE_URL = os.getenv("WIKI_SSE_URL", "https://stream.wikimedia.org/v2/stream/recentchange")
# BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:29092")
# TOPIC = os.getenv("KAFKA_TOPIC", "recentchange_raw")

# USER_AGENT = os.getenv(
#     "WIKI_USER_AGENT",
#     "wiki-stream-analytics/0.1 (https://github.com/vsokoltsov; contact: you@example.com)"
# )

async def main() -> None:
    settings = get_producer_settings()
    producer = AIOKafkaProducer(bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS)
    await producer.start()
    logger.info("Producer started. SSE=%s topic=%s", settings.WIKI_SSE_URL, settings.KAFKA_TOPIC)

    last_event_id: Optional[str] = None
    backoff = 1  # seconds, exponential up to max

    try:
        timeout = aiohttp.ClientTimeout(total=None, sock_connect=30, sock_read=None)

        while True:
            headers = {
                "Accept": "text/event-stream",
                "User-Agent": settings.WIKI_USER_AGENT,
            }
            if last_event_id:
                headers["Last-Event-ID"] = last_event_id

            try:
                async with aiohttp.ClientSession(timeout=timeout, headers=headers) as session:
                    async with session.get(settings.WIKI_SSE_URL) as resp:
                        if resp.status == 403:
                            body = await resp.text()
                            raise RuntimeError(f"403 Forbidden (UA issue). Body: {body[:300]}")
                        resp.raise_for_status()

                        logger.info("Connected to SSE (status=%s). Waiting for events...", resp.status)
                        backoff = 1  # reset backoff on successful connect

                        current_id: Optional[str] = None
                        event_count = 0

                        while True:
                            raw = await resp.content.readline()
                            if not raw:
                                # server closed connection
                                raise ConnectionError("SSE connection closed")

                            line = raw.decode("utf-8", errors="ignore").strip()
                            if not line:
                                # end of event block
                                current_id = None
                                continue

                            # Example lines:
                            # id: 12345
                            # data: {...json...}
                            if line.startswith("id:"):
                                current_id = line[3:].strip() or None
                                continue

                            if line.startswith("data:"):
                                payload = line[5:].strip()
                                if not payload:
                                    continue

                                try:
                                    obj = json.loads(payload)
                                except Exception:
                                    continue

                                if current_id:
                                    last_event_id = current_id

                                print(raw)
                                # print(payload)
                                await producer.send_and_wait(settings.KAFKA_TOPIC, payload.encode("utf-8"))

                                event_count += 1
                                if event_count <= 3:
                                    logger.info("Sample event #%d keys=%s $schema=%s",
                                                event_count, list(obj.keys())[:10], obj.get("$schema"))

            except asyncio.CancelledError:
                raise
            except Exception as e:
                logger.warning("Stream failed (%s). Reconnecting in %ss...", e, backoff)
                await asyncio.sleep(backoff)
                backoff = min(backoff * 2, 30)

    finally:
        await producer.stop()

if __name__ == "__main__":
    asyncio.run(main())