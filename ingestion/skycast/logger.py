"""Structured JSON logging for Cloud Functions / Cloud Run.

Emits one JSON object per line so logs are parsed natively by Cloud Logging.
"""

from __future__ import annotations

import json
import logging
import os
import sys
from datetime import datetime, timezone


class _JsonFormatter(logging.Formatter):
    """Render log records as single-line JSON understood by Cloud Logging."""

    def format(self, record: logging.LogRecord) -> str:
        payload: dict[str, object] = {
            "time": datetime.now(timezone.utc).isoformat(),
            "severity": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
        }
        # Attach any structured context passed via `extra={"context": {...}}`.
        context = getattr(record, "context", None)
        if isinstance(context, dict):
            payload.update(context)
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, default=str)


def get_logger(service: str) -> logging.Logger:
    """Return a configured logger.

    Level is controlled by the LOGLEVEL env var (default INFO).
    """
    logger = logging.getLogger(service)
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(_JsonFormatter())
        logger.addHandler(handler)
        logger.setLevel(os.environ.get("LOGLEVEL", "INFO").upper())
        logger.propagate = False
    return logger
