import os
import ssl
from aiokafka import AIOKafkaProducer
from producer.token_provider import GcpAdcTokenProvider, GcpAccessToken
from producer.settings import get_producer_settings, ProducerSettings

def build_producer(settings: ProducerSettings) -> AIOKafkaProducer:
    mode = (
        getattr(settings, "KAFKA_MODE", None) or os.getenv("KAFKA_MODE", "PLAINTEXT")
    ).upper()

    if mode == "PLAINTEXT":
        return AIOKafkaProducer(
            bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        )

    if mode == "GCP_OAUTH":
        ssl_ctx = ssl.create_default_context()
        token = GcpAccessToken().get()
        principal_email = settings.KAFKA_SASL_USERNAME

        return AIOKafkaProducer(
            bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
            security_protocol="SASL_SSL",
            ssl_context=ssl_ctx,
            sasl_mechanism="PLAIN",
            sasl_oauth_token_provider=GcpAdcTokenProvider(),
            sasl_plain_username=principal_email,
            sasl_plain_password=token,
        )

    raise ValueError(f"Unknown KAFKA_MODE={mode}. Use PLAINTEXT or GCP_OAUTH.")