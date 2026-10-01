"""Unit tests for the sample HTTP application."""

import os
import unittest

from src.app import create_response


class CreateResponseTests(unittest.TestCase):
    def test_health_endpoint_returns_ok(self) -> None:
        status, body = create_response("/health")

        self.assertEqual(status, 200)
        self.assertEqual(body, {"status": "ok"})

    def test_root_endpoint_exposes_version(self) -> None:
        previous_version = os.environ.get("APP_VERSION")
        self.addCleanup(self._restore_version, previous_version)
        os.environ["APP_VERSION"] = "1.2.3"

        status, body = create_response("/")

        self.assertEqual(status, 200)
        self.assertEqual(body["version"], "1.2.3")

    def test_unknown_endpoint_returns_not_found(self) -> None:
        status, body = create_response("/missing")

        self.assertEqual(status, 404)
        self.assertEqual(body, {"error": "not found"})

    @staticmethod
    def _restore_version(previous_version: str | None) -> None:
        if previous_version is None:
            os.environ.pop("APP_VERSION", None)
        else:
            os.environ["APP_VERSION"] = previous_version


if __name__ == "__main__":
    unittest.main()
