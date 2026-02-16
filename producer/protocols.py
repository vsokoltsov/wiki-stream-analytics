from contextlib import asynccontextmanager
from typing import Protocol, Optional


class WikiClientProtocol(Protocol):
    @asynccontextmanager  # type: ignore[arg-type]
    async def open_sse_stream(self, last_event_id: Optional[str] = None): ...


class ProducerProtocol(Protocol):
    async def send_and_wait(
        self,
        topic,
        value=None,
        key=None,
        partition=None,
        timestamp_ms=None,
        headers=None,
    ): ...
