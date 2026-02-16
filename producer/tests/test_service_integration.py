import asyncio
import json
import pytest
from aiokafka import AIOKafkaProducer, AIOKafkaConsumer
from aiokafka.structs import TopicPartition
from testcontainers.kafka import KafkaContainer

from producer.service import WikipediaProducerService
from producer.wiki_client import WikiClient
from producer.tests.sse_stub_server import run_sse_stub

TOPIC = "recentchange_raw_integration"

SAMPLE_PAYLOAD = {
    "$schema": "/mediawiki/recentchange/1.0.0",
    "meta": {"domain": "vi.wikipedia.org", "id": "test-request-1"},
    "id": 136897154,
    "type": "log",
    "user": "IntegrationTest",
}


def _create_topic(kafka_container, topic: str) -> None:
    """Create topic inside the Kafka container."""
    res = kafka_container.exec(
        [
            "kafka-topics",
            "--bootstrap-server",
            "localhost:9092",
            "--create",
            "--if-not-exists",
            "--topic",
            topic,
            "--partitions",
            "1",
            "--replication-factor",
            "1",
        ]
    )
    if res.exit_code != 0:
        raise RuntimeError(f"Failed to create topic {topic}: {res.output.decode()}")


@pytest.fixture(scope="session")
def kafka_container():
    with KafkaContainer(image="confluentinc/cp-kafka:7.6.1") as kafka:
        yield kafka


@pytest.fixture
def bootstrap_servers(kafka_container):
    return kafka_container.get_bootstrap_server()


@pytest.mark.asyncio
@pytest.mark.integration
async def test_service_connects_to_sse_stub_and_publishes_to_kafka(
    kafka_container, bootstrap_servers
):
    """Service reads from SSE stub and publishes to Kafka; consumer verifies the message."""
    _create_topic(kafka_container, TOPIC)

    # 1. Stub SSE: one event (id + data) then stream ends
    events = [("event-1", json.dumps(SAMPLE_PAYLOAD))]
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
            result = await service.run(last_event_id=None)
        finally:
            await producer.stop()
    finally:
        await runner.cleanup()

    assert result == "event-1"

    # 2. Consume and verify (same pattern as working roundtrip test)
    tp = TopicPartition(TOPIC, 0)
    consumer = AIOKafkaConsumer(
        bootstrap_servers=bootstrap_servers,
        auto_offset_reset="earliest",
    )
    await consumer.start()
    consumer.assign([tp])
    await consumer.seek_to_beginning(tp)
    try:
        msg = await asyncio.wait_for(consumer.getone(tp), timeout=10.0)
        assert msg.value is not None
        payload = json.loads(msg.value.decode("utf-8"))
        assert payload["$schema"] == SAMPLE_PAYLOAD["$schema"]
        assert payload["id"] == SAMPLE_PAYLOAD["id"]
        assert payload["user"] == SAMPLE_PAYLOAD["user"]
    finally:
        await consumer.stop()
