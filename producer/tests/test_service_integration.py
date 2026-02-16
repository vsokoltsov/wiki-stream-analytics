import asyncio
import json
import pytest
from aiokafka import AIOKafkaProducer, AIOKafkaConsumer
from testcontainers.kafka import KafkaContainer

from producer.service import WikipediaProducerService
from producer.wiki_client import WikiClient
from producer.tests.sse_stub_server import run_sse_stub

# Sample event matching your format
SSE_EVENT_JSON = json.dumps(
    {
        "$schema": "/mediawiki/recentchange/1.0.0",
        "meta": {"domain": "vi.wikipedia.org", "id": "test-request-1"},
        "id": 136897154,
        "type": "log",
        "user": "IntegrationTest",
    }
)

TOPIC = "recentchange_raw_integration"


@pytest.fixture(scope="session")
def kafka_container():
    with KafkaContainer(image="confluentinc/cp-kafka:7.6.1") as kafka:
        yield kafka


@pytest.fixture
def bootstrap_servers(kafka_container):
    return kafka_container.get_bootstrap_server()


@pytest.mark.asyncio
@pytest.mark.integration
async def test_service_connects_to_sse_and_publishes_to_kafka(bootstrap_servers):
    # 1. Stub SSE server: one event then stream ends (connection closes)
    events = [("event-1", SSE_EVENT_JSON)]
    runner, port = await run_sse_stub(events)
    try:
        sse_url = f"http://127.0.0.1:{port}/stream"
        client = WikiClient(
            url=sse_url,
            user_agent="IntegrationTest/1.0",
            timeout=5,
        )
        producer = AIOKafkaProducer(bootstrap_servers=bootstrap_servers)
        await producer.start()
        try:
            service = WikipediaProducerService(
                topic_name=TOPIC,
                producer=producer,
                client=client,
            )
            # 2. Run service (will read one event, then get empty line -> ConnectionError -> return)
            result = await service.run(last_event_id=None)
        finally:
            await producer.stop()
    finally:
        await runner.cleanup()

    # 3. Consume and verify message in Kafka
    consumer = AIOKafkaConsumer(
        TOPIC,
        bootstrap_servers=bootstrap_servers,
        auto_offset_reset="earliest",
    )
    await consumer.start()
    try:
        msg = await asyncio.wait_for(consumer.getone(), timeout=5.0)
        assert msg.value is not None, "expected message value"
        payload = json.loads(msg.value.decode("utf-8"))
        assert payload["$schema"] == "/mediawiki/recentchange/1.0.0"
        assert payload["id"] == 136897154
        assert payload["user"] == "IntegrationTest"
    finally:
        await consumer.stop()

    assert result == "event-1"  # no id line before our single data line
