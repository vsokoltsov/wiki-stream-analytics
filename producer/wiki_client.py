"""Thin client: open SSE connection with correct headers and status handling."""

import logging
from dataclasses import dataclass
from contextlib import asynccontextmanager
from typing import Optional

import aiohttp

logger = logging.getLogger("wiki-producer")


@dataclass
class WikiClient:
    url: str
    user_agent: str
    timeout: int
    client_timeout: Optional[aiohttp.ClientTimeout] = None

    def __post_init__(self):
        self.client_timeout = aiohttp.ClientTimeout(
            total=None, sock_connect=self.timeout, sock_read=None
        )

    def _default_headers(self, last_event_id: Optional[str] = None) -> dict[str, str]:
        headers = {
            "Accept": "text/event-stream",
            "User-Agent": self.user_agent,
        }
        if last_event_id:
            headers["Last-Event-ID"] = last_event_id
        return headers

    @asynccontextmanager
    async def open_sse_stream(
        self,
        last_event_id: Optional[str] = None,
    ):
        """Open GET to SSE endpoint; validate status (including 403); yield the response.
        Caller is responsible for reading resp.content (e.g. readline() in a loop).
        """
        headers = self._default_headers(last_event_id)
        async with aiohttp.ClientSession(
            timeout=self.timeout, headers=headers
        ) as session:
            async with session.get(self.url) as resp:
                if resp.status == 403:
                    body = await resp.text()
                    raise RuntimeError(f"403 Forbidden. Body: {body[:300]}")
                resp.raise_for_status()
                logger.info(
                    "Connected to SSE (status=%s). Waiting for events...", resp.status
                )
                yield resp
