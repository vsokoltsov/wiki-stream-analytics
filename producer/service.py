import asyncio
from typing import Optional, Dict, Any
import json
from dataclasses import dataclass
from producer.protocols import WikiClientProtocol, ProducerProtocol
from producer.errors import ContinueStream


@dataclass
class WikipediaProducerService:
    client: WikiClientProtocol
    producer: ProducerProtocol
    topic_name: str

    async def run(self, last_event_id: Optional[str] = None) -> Optional[str]:
        current_id: Optional[str] = last_event_id
        try:
            async with self.client.open_sse_stream(last_event_id=current_id) as resp:
                while True:
                    try:
                        raw = await resp.content.readline()
                        obj = self._clean_data(raw=raw, current_id=current_id)
                        await self.producer.send_and_wait(
                            self.topic_name, json.dumps(obj).encode("utf-8")
                        )
                    except ContinueStream as e:
                        if e.current_id is not None:
                            current_id = e.current_id
                        continue
        except asyncio.CancelledError:
            raise
        except Exception:
            return current_id

    def _clean_data(
        self, raw: bytes, current_id: Optional[str] = None
    ) -> Dict[str, Any]:
        if not raw:
            # server closed connection
            raise ConnectionError("SSE connection closed")

        line = raw.decode("utf-8", errors="ignore").strip()
        if not line:
            # end of event block
            raise ContinueStream(current_id=current_id)

        # Example lines:
        # id: 12345
        # data: {...json...}
        if line.startswith("id:"):
            current_id = line[3:].strip() or None
            raise ContinueStream(current_id=current_id)

        if line.startswith("data:"):
            payload = line[5:].strip()
            if not payload:
                raise ContinueStream(current_id=current_id)

            try:
                payload_json = json.loads(payload)
                if payload_json:
                    return payload_json
            except Exception:
                raise ContinueStream(current_id=current_id)

        raise ContinueStream(current_id=current_id)
