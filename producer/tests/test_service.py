"""Unit tests for WikipediaProducerService."""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock

from producer.service import WikipediaProducerService
from producer.errors import ContinueStream

# Sample SSE data line matching your format (single line, no id line in payload)
SSE_DATA_LINE = (
    b'data: {"$schema":"/mediawiki/recentchange/1.0.0","meta":{"uri":"https://vi.wikipedia.org/wiki/Example",'
    b'"request_id":"12946aa3-367a-48dc-93e5-efaddc9d74f8","id":"234c5c0a-f291-44da-a3d3-d04f1391d4e3",'
    b'"domain":"vi.wikipedia.org","stream":"mediawiki.recentchange","dt":"2026-02-10T19:11:06.357Z",'
    b'"topic":"codfw.mediawiki.recentchange","partition":0,"offset":1969383194},"id":136897154,"type":"log",'
    b'"namespace":3,"title":"Example","timestamp":1770750665,"user":"Ladsgroup","bot":true}\n'
)


def _make_service(client=None, producer=None, topic_name="recentchange_raw"):
    """Build service with mocked client and producer."""
    return WikipediaProducerService(
        client=client or MagicMock(),
        producer=producer or MagicMock(),
        topic_name=topic_name,
    )


@pytest.mark.unit
class TestCleanData:
    """Tests for _clean_data."""

    def test_empty_raw_raises_connection_error(self):
        service = _make_service()
        with pytest.raises(ConnectionError, match="SSE connection closed"):
            service._clean_data(b"", current_id=None)
        with pytest.raises(ConnectionError, match="SSE connection closed"):
            service._clean_data(raw=b"")

    def test_empty_line_raises_continue_stream_preserves_current_id(self):
        service = _make_service()
        with pytest.raises(ContinueStream) as exc_info:
            service._clean_data(b"\n", current_id="123")
        assert exc_info.value.current_id == "123"

    def test_id_line_raises_continue_stream_with_new_id(self):
        service = _make_service()
        with pytest.raises(ContinueStream) as exc_info:
            service._clean_data(b"id: 12345\n", current_id=None)
        assert exc_info.value.current_id == "12345"

    def test_id_line_empty_value_raises_continue_stream_none(self):
        service = _make_service()
        with pytest.raises(ContinueStream) as exc_info:
            service._clean_data(b"id: \n", current_id="previous")
        assert exc_info.value.current_id is None

    def test_data_line_valid_json_returns_parsed_dict(self):
        service = _make_service()
        result = service._clean_data(b'data: {"a": 1, "b": "two"}\n', current_id="99")
        assert result == {"a": 1, "b": "two"}

    def test_data_line_real_sse_format_returns_dict_with_schema(self):
        service = _make_service()
        result = service._clean_data(SSE_DATA_LINE, current_id=None)
        assert isinstance(result, dict)
        assert result.get("$schema") == "/mediawiki/recentchange/1.0.0"
        assert result.get("meta", {}).get("domain") == "vi.wikipedia.org"
        assert result.get("id") == 136897154
        assert result.get("type") == "log"
        assert result.get("user") == "Ladsgroup"

    def test_data_line_empty_payload_raises_continue_stream(self):
        service = _make_service()
        with pytest.raises(ContinueStream) as exc_info:
            service._clean_data(b"data: \n", current_id="42")
        assert exc_info.value.current_id == "42"

    def test_data_line_invalid_json_raises_continue_stream(self):
        service = _make_service()
        with pytest.raises(ContinueStream) as exc_info:
            service._clean_data(b"data: not valid json {]\n", current_id="7")
        assert exc_info.value.current_id == "7"

    def test_data_line_empty_json_object_raises_continue_stream(self):
        service = _make_service()
        with pytest.raises(ContinueStream) as exc_info:
            service._clean_data(b"data: {}\n", current_id="x")
        assert exc_info.value.current_id == "x"

    def test_unknown_line_type_raises_continue_stream(self):
        service = _make_service()
        with pytest.raises(ContinueStream) as exc_info:
            service._clean_data(b"event: message\n", current_id="id")
        assert exc_info.value.current_id == "id"


@pytest.mark.unit
@pytest.mark.asyncio
class TestRun:
    """Tests for run() (async)."""

    async def test_run_parses_data_line_and_sends_to_producer(self):
        client = MagicMock()
        readline = AsyncMock(side_effect=[SSE_DATA_LINE, b""])
        mock_resp = MagicMock()
        mock_resp.content.readline = readline
        ctx = AsyncMock()
        ctx.__aenter__ = AsyncMock(return_value=mock_resp)
        ctx.__aexit__ = AsyncMock(return_value=None)
        client.open_sse_stream = MagicMock(return_value=ctx)

        producer = MagicMock()
        producer.send_and_wait = AsyncMock()

        service = _make_service(client=client, producer=producer, topic_name="my_topic")
        result = await service.run(last_event_id=None)

        producer.send_and_wait.assert_called_once()
        call_args = producer.send_and_wait.call_args
        assert call_args[0][0] == "my_topic"
        payload_bytes = call_args[0][1]
        assert payload_bytes is not None
        import json as json_mod

        payload_obj = json_mod.loads(payload_bytes.decode("utf-8"))
        assert payload_obj.get("$schema") == "/mediawiki/recentchange/1.0.0"
        assert payload_obj.get("id") == 136897154

        assert result is None

    async def test_run_passes_last_event_id_to_client(self):
        client = MagicMock()
        readline = AsyncMock(side_effect=[b""])
        mock_resp = MagicMock()
        mock_resp.content.readline = readline
        ctx = AsyncMock()
        ctx.__aenter__ = AsyncMock(return_value=mock_resp)
        ctx.__aexit__ = AsyncMock(return_value=None)
        client.open_sse_stream = MagicMock(return_value=ctx)

        producer = MagicMock()
        producer.send_and_wait = AsyncMock()

        service = _make_service(client=client, producer=producer)
        await service.run(last_event_id="resume-123")

        client.open_sse_stream.assert_called_once_with(last_event_id="resume-123")

    async def test_run_returns_current_id_on_connection_closed(self):
        client = MagicMock()
        readline = AsyncMock(side_effect=[b"id: 999\n", SSE_DATA_LINE, b""])
        mock_resp = MagicMock()
        mock_resp.content.readline = readline
        ctx = AsyncMock()
        ctx.__aenter__ = AsyncMock(return_value=mock_resp)
        ctx.__aexit__ = AsyncMock(return_value=None)
        client.open_sse_stream = MagicMock(return_value=ctx)

        producer = MagicMock()
        producer.send_and_wait = AsyncMock()

        service = _make_service(client=client, producer=producer)
        result = await service.run(last_event_id=None)

        assert result == "999"
        producer.send_and_wait.assert_called_once()

    async def test_run_propagates_cancelled_error(self):
        client = MagicMock()
        readline = AsyncMock(side_effect=asyncio.CancelledError())
        mock_resp = MagicMock()
        mock_resp.content.readline = readline
        ctx = AsyncMock()
        ctx.__aenter__ = AsyncMock(return_value=mock_resp)
        ctx.__aexit__ = AsyncMock(return_value=None)
        client.open_sse_stream = MagicMock(return_value=ctx)

        producer = MagicMock()
        producer.send_and_wait = AsyncMock()

        service = _make_service(client=client, producer=producer)
        with pytest.raises(asyncio.CancelledError):
            await service.run(last_event_id=None)
