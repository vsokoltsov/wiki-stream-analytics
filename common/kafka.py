import asyncio
import base64
import datetime as dt
import json
import ssl
from typing import Any, Dict, Optional

import google.auth
from google.auth.transport.requests import Request as GoogleAuthRequest

from aiokafka import AIOKafkaProducer
from aiokafka.abc import AbstractTokenProvider

from producer.settings import ProducerSettings


def _b64url(s: str) -> str:
    # urlsafe base64 без '=' в конце — как в примере Google
    return base64.urlsafe_b64encode(s.encode("utf-8")).decode("utf-8").rstrip("=")


class GcpManagedKafkaOauthBearerProvider(AbstractTokenProvider):
    """
    Делает токен в формате, который ожидает Google Managed Service for Apache Kafka:
    token = base64url(header) + "." + base64url(payload) + "." + base64url(access_token)
    """

    HEADER = json.dumps({"typ": "JWT", "alg": "GOOG_OAUTH2_TOKEN"})

    def __init__(self, principal_email: str, scopes: Optional[list[str]] = None):
        self._principal_email = principal_email
        self._scopes = scopes or ["https://www.googleapis.com/auth/cloud-platform"]

        creds, _ = google.auth.default(scopes=self._scopes)
        self._creds = creds
        self._req = GoogleAuthRequest()

    async def token(self) -> str:
        # refresh() блокирующий -> в thread
        await asyncio.to_thread(self._ensure_fresh)

        if not getattr(self._creds, "token", None) or not getattr(self._creds, "expiry", None):
            raise RuntimeError("ADC credentials did not provide token/expiry")

        now = dt.datetime.now(dt.timezone.utc).timestamp()
        exp = self._creds.expiry.replace(tzinfo=dt.timezone.utc).timestamp()

        payload = json.dumps(
            {
                "exp": exp,
                "iat": now,
                "iss": "Google",
                # Важно: sub должен быть principal (email SA), который имеет roles/managedkafka.client
                "sub": self._principal_email,
            }
        )

        wrapped = ".".join(
            [
                _b64url(self.HEADER),
                _b64url(payload),
                _b64url(self._creds.token),
            ]
        )
        return wrapped

    def _ensure_fresh(self) -> None:
        if not self._creds.valid or self._creds.expired:
            self._creds.refresh(self._req)

    # extensions() можно оставить пустым — GCP пример работает без sasl.oauthbearer.extensions
    # но если тебе нужно строго как во Flink, можно вернуть principal:
    def extensions(self) -> Dict[str, Any]:
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
        token_provider = GcpManagedKafkaOauthBearerProvider(principal_email=principal_email)

        return AIOKafkaProducer(
            bootstrap_servers=settings.KAFKA_BOOTSTRAP_SERVERS,
            security_protocol="SASL_SSL",
            ssl_context=ssl_ctx,
            sasl_mechanism="OAUTHBEARER",
            sasl_oauth_token_provider=token_provider,
            # ВАЖНО: НЕ указывать sasl_plain_username/password при OAUTHBEARER
        )

    raise ValueError(f"Unknown KAFKA_MODE={mode}. Use PLAINTEXT or GCP_OAUTH.")