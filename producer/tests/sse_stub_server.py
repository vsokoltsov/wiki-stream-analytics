"""Minimal SSE server for integration tests."""

from aiohttp import web
import socket


def _free_port() -> int:
    """Return a port number that is currently free for binding."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("", 0))
        return s.getsockname()[1]


def make_sse_app(events: list[tuple[str | None, str]]) -> web.Application:
    """events: list of (event_id, data_json)."""

    async def stream(_request: web.Request) -> web.StreamResponse:
        resp = web.StreamResponse(
            status=200, headers={"Content-Type": "text/event-stream"}
        )
        await resp.prepare(_request)
        for event_id, data in events:
            if event_id is not None:
                await resp.write(f"id: {event_id}\n".encode())
            await resp.write(f"data: {data}\n".encode())
            await resp.write(b"\n")
        return resp

    app = web.Application()
    app.router.add_get("/stream", stream)
    return app


async def run_sse_stub(events: list[tuple[str | None, str]], port: int = 0):
    """Start stub SSE server; return (runner, port). Caller must await runner.cleanup()."""
    if port == 0:
        port = _free_port()

    app = make_sse_app(events)
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, "127.0.0.1", port)
    await site.start()
    return runner, port
