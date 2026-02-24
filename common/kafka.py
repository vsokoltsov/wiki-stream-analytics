import os
import ssl
import asyncio
from typing import Optional, Dict, Any

import google.auth
from google.auth.transport.requests import Request as GoogleAuthRequest

from aiokafka import AIOKafkaProducer
from aiokafka.abc import AbstractTokenProvider

from producer.settings import ProducerSettings


class GcpOauthBearerTokenProvider(AbstractTokenProvider):
    """
    aiokafka will call `token()` during SASL/OAUTHBEARER handshake.
    We must return a *fresh* access token string.
    """

    def __init__(self, principal_email: str, scopes: Optional[list[str]] = None):
        self._principal_email = principal_email
        self._scopes = scopes or ["https://www.googleapis.com/auth/cloud-platform"]

        # ADC credentials (refreshable in most environments: service account, workload identity, etc.)
        creds, _ = google.auth.default(scopes=self._scopes)
        self._creds = creds

        self._req = GoogleAuthRequest()

    async def token(self) -> str:
        # google-auth refresh is blocking -> do it in a thread
        await asyncio.to_thread(self._ensure_fresh)
        if not self._creds.token:
            raise RuntimeError("Failed to obtain GCP access token via ADC")
        return self._creds.token

    def _ensure_fresh(self) -> None:
        # `valid`/`expired` semantics are handled by google-auth
        if not self._creds.valid or self._creds.expired:
            self._creds.refresh(self._req)

    def extensions(self) -> Dict[str, Any]:
        # Same as: sasl.oauthbearer.extensions=principal=...
        return {"principal": self._principal_email}


def build_producer(settings: ProducerSettings) -> AIOKafkaProducer:
    mode = (getattr(settings, "KAFKA_MODE", None) or os.getenv("KAFKA_MODE", "PLAINTEXT")).upper()

    if mode == "PLAINTEXT":
        return AIOKafkaProducer(
            bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
        )

    if mode == "GCP_OAUTH":
        ssl_ctx = ssl.create_default_context()
        principal_email = settings.KAFKA_SASL_USERNAME  # email сервис-аккаунта (principal)
        if not principal_email:
            raise ValueError(f'KAFKA_SASL_USERNAME variable is empty: {settings.KAFKA_SASL_USERNAME}')
        token_provider = GcpOauthBearerTokenProvider(principal_email=principal_email)

        return AIOKafkaProducer(
            bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
            security_protocol="SASL_SSL",
            ssl_context=ssl_ctx,
            sasl_mechanism="OAUTHBEARER",
            sasl_oauth_token_provider=token_provider,
            # ВАЖНО: НЕ указывать sasl_plain_username/password при OAUTHBEARER
        )

    raise ValueError(f"Unknown KAFKA_MODE={mode}. Use PLAINTEXT or GCP_OAUTH.")