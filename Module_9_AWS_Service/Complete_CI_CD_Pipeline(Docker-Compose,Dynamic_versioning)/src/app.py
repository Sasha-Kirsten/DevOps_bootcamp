"""Minimal HTTP service used by the Docker Compose and Jenkins examples."""

from __future__ import annotations

from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os

HOST = "0.0.0.0"
PORT = 8080


def create_response(path: str) -> tuple[int, dict[str, str]]:
    """Return a status code and JSON payload for a request path."""
    if path == "/health":
        return HTTPStatus.OK, {"status": "ok"}
    if path == "/":
        return HTTPStatus.OK, {
            "message": "CI/CD starter application",
            "version": os.getenv("APP_VERSION", "development"),
        }
    return HTTPStatus.NOT_FOUND, {"error": "not found"}


class RequestHandler(BaseHTTPRequestHandler):
    """Serve JSON responses for the sample application."""

    def do_GET(self) -> None:  # noqa: N802 - required by BaseHTTPRequestHandler
        status, payload = create_response(self.path)
        body = json.dumps(payload).encode("utf-8")

        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format: str, *args: object) -> None:
        """Keep the sample server output concise while retaining access logs."""
        print(f"{self.address_string()} - {format % args}")


def main() -> None:
    """Start the local HTTP server."""
    server = ThreadingHTTPServer((HOST, PORT), RequestHandler)
    print(f"Listening on http://{HOST}:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
