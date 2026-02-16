"""Unit tests for WikiClient."""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from producer.wiki_client import WikiClient


@pytest.mark.unit
class TestWikiClientDefaults:
    """Tests for _default_headers and __post_init__."""

    def test_default_headers_without_last_event_id(self):
        client = WikiClient(
            url="https://stream.example.org/sse",
            user_agent="TestAgent/1.0",
            timeout=30,
        )
        headers = client._default_headers()
        assert headers == {
            "Accept": "text/event-stream",
            "User-Agent": "TestAgent/1.0",
        }

    def test_default_headers_with_last_event_id(self):
        client = WikiClient(
            url="https://stream.example.org/sse",
            user_agent="TestAgent/1.0",
            timeout=30,
        )
        headers = client._default_headers(last_event_id="12345")
        assert headers["Accept"] == "text/event-stream"
        assert headers["User-Agent"] == "TestAgent/1.0"
        assert headers["Last-Event-ID"] == "12345"

    def test_post_init_sets_timeout_to_client_timeout(self):
        client = WikiClient(
            url="https://stream.example.org/sse",
            user_agent="TestAgent/1.0",
            timeout=10,
        )
        assert client.client_timeout is not None
        assert client.client_timeout.sock_connect == 10
        assert client.client_timeout.total is None
        assert client.client_timeout.sock_read is None


@pytest.mark.unit
@pytest.mark.asyncio
class TestWikiClientOpenSseStream:
    """Tests for open_sse_stream (async context manager)."""

    @patch("producer.wiki_client.aiohttp.ClientSession")
    async def test_open_sse_stream_success_yields_response(self, mock_session_class):
        mock_resp = MagicMock()
        mock_resp.status = 200
        mock_resp.raise_for_status = MagicMock()

        mock_get = AsyncMock()
        mock_get.__aenter__ = AsyncMock(return_value=mock_resp)
        mock_get.__aexit__ = AsyncMock(return_value=None)

        mock_session = AsyncMock()
        mock_session.get = MagicMock(return_value=mock_get)

        mock_session_class.return_value.__aenter__ = AsyncMock(
            return_value=mock_session
        )
        mock_session_class.return_value.__aexit__ = AsyncMock(return_value=None)

        client = WikiClient(
            url="https://stream.example.org/sse",
            user_agent="TestAgent/1.0",
            timeout=30,
        )
        async with client.open_sse_stream() as resp:
            assert resp is mock_resp
        mock_session.get.assert_called_once_with("https://stream.example.org/sse")
        mock_resp.raise_for_status.assert_called_once()

    @patch("producer.wiki_client.aiohttp.ClientSession")
    async def test_open_sse_stream_passes_last_event_id_in_headers(
        self, mock_session_class
    ):
        mock_resp = MagicMock()
        mock_resp.status = 200
        mock_resp.raise_for_status = MagicMock()

        mock_get = AsyncMock()
        mock_get.__aenter__ = AsyncMock(return_value=mock_resp)
        mock_get.__aexit__ = AsyncMock(return_value=None)

        mock_session = AsyncMock()
        mock_session.get = MagicMock(return_value=mock_get)

        mock_session_class.return_value.__aenter__ = AsyncMock(
            return_value=mock_session
        )
        mock_session_class.return_value.__aexit__ = AsyncMock(return_value=None)

        client = WikiClient(
            url="https://stream.example.org/sse",
            user_agent="TestAgent/1.0",
            timeout=30,
        )
        async with client.open_sse_stream(last_event_id="999") as resp:
            assert resp is mock_resp
        # ClientSession was created with headers containing Last-Event-ID
        call_kwargs = mock_session_class.call_args[1]
        assert call_kwargs["headers"]["Last-Event-ID"] == "999"
        assert call_kwargs["headers"]["Accept"] == "text/event-stream"
        assert call_kwargs["headers"]["User-Agent"] == "TestAgent/1.0"

    @patch("producer.wiki_client.aiohttp.ClientSession")
    async def test_open_sse_stream_403_raises_runtime_error_with_body(
        self, mock_session_class
    ):
        mock_resp = MagicMock()
        mock_resp.status = 403
        mock_resp.text = AsyncMock(
            return_value="Forbidden: bad user agent or similar message"
        )

        mock_get = AsyncMock()
        mock_get.__aenter__ = AsyncMock(return_value=mock_resp)
        mock_get.__aexit__ = AsyncMock(return_value=None)

        mock_session = AsyncMock()
        mock_session.get = MagicMock(return_value=mock_get)

        mock_session_class.return_value.__aenter__ = AsyncMock(
            return_value=mock_session
        )
        mock_session_class.return_value.__aexit__ = AsyncMock(return_value=None)

        client = WikiClient(
            url="https://stream.example.org/sse",
            user_agent="TestAgent/1.0",
            timeout=30,
        )
        with pytest.raises(RuntimeError) as exc_info:
            async with client.open_sse_stream():
                pass
        assert "403" in str(exc_info.value)
        assert "Forbidden" in str(exc_info.value)
        assert "body" in str(exc_info.value).lower() or "Body" in str(exc_info.value)
        # Body truncated to 300 chars
        assert len(str(exc_info.value)) <= 350 or "..." in str(exc_info.value)

    @patch("producer.wiki_client.aiohttp.ClientSession")
    async def test_open_sse_stream_500_calls_raise_for_status(self, mock_session_class):
        mock_resp = MagicMock()
        mock_resp.status = 500
        mock_resp.raise_for_status = MagicMock(
            side_effect=Exception("500 Server Error")
        )

        mock_get = AsyncMock()
        mock_get.__aenter__ = AsyncMock(return_value=mock_resp)
        mock_get.__aexit__ = AsyncMock(return_value=None)

        mock_session = AsyncMock()
        mock_session.get = MagicMock(return_value=mock_get)

        mock_session_class.return_value.__aenter__ = AsyncMock(
            return_value=mock_session
        )
        mock_session_class.return_value.__aexit__ = AsyncMock(return_value=None)

        client = WikiClient(
            url="https://stream.example.org/sse",
            user_agent="TestAgent/1.0",
            timeout=30,
        )
        with pytest.raises(Exception, match="500 Server Error"):
            async with client.open_sse_stream():
                pass
        mock_resp.raise_for_status.assert_called_once()
