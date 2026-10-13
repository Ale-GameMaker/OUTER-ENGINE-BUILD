#!/usr/bin/env python3
"""OUTER!ENGINE assistant schedule worker.

Reads outer_assistant_schedule.json from the current working directory and
serves the active schedule over localhost HTTP. This process remains alive when
the game window closes. It intentionally does not impersonate a Discord or
other provider bot; provider adapters can consume its /status endpoint.
"""
from __future__ import annotations

import argparse
import json
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

BOT_IDS = ("OuterQT", "OuterSky", "OuterNikku", "OuterCarol")
DEFAULT_CONFIG: dict[str, Any] = {
    "timezoneOffset": -3,
    "globallyEnabled": True,
    "executionMode": "both",
    "entries": {
        "OuterQT": {"enabled": True, "startHour": 6, "startMinute": 0, "durationHours": 12,
                    "days": [0, 1, 2, 3, 4, 5, 6], "preset": "daytime"},
        "OuterSky": {"enabled": True, "startHour": 18, "startMinute": 0, "durationHours": 12,
                     "days": [0, 1, 2, 3, 4, 5, 6], "preset": "evening"},
        "OuterNikku": {"enabled": False, "startHour": 0, "startMinute": 0, "durationHours": 8,
                       "days": [1, 2, 3, 4, 5], "preset": "workday"},
        "OuterCarol": {"enabled": False, "startHour": 9, "startMinute": 0, "durationHours": 8,
                       "days": [1, 2, 3, 4, 5], "preset": "workday"},
    },
}


def read_config(path: Path) -> dict[str, Any]:
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(DEFAULT_CONFIG, indent=2), encoding="utf-8")
        return json.loads(json.dumps(DEFAULT_CONFIG))
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            raise ValueError("root JSON value must be an object")
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        raise RuntimeError(f"Cannot read scheduler config {path}: {exc}") from exc

    merged = json.loads(json.dumps(DEFAULT_CONFIG))
    merged.update({key: data[key] for key in ("timezoneOffset", "globallyEnabled", "executionMode") if key in data})
    if isinstance(data.get("entries"), dict):
        for bot_id in BOT_IDS:
            if isinstance(data["entries"].get(bot_id), dict):
                merged["entries"][bot_id].update(data["entries"][bot_id])
    return merged


def active_bot(config: dict[str, Any], timestamp: float | None = None) -> tuple[str, float | None]:
    if not config.get("globallyEnabled", True):
        return "MinusBright", None

    mode = str(config.get("executionMode", "both")).lower()
    if mode not in ("background", "both"):
        return "MinusBright", None

    now = time.time() if timestamp is None else timestamp
    offset = max(-12, min(14, int(config.get("timezoneOffset", -3))))
    local_seconds = now + offset * 3600
    day_number = int(local_seconds // 86400)
    second_of_day = local_seconds - day_number * 86400
    weekday_today = (day_number + 4) % 7
    candidates: list[tuple[float, str]] = []

    for bot_id in BOT_IDS:
        entry = config["entries"].get(bot_id, {})
        if not entry.get("enabled", False):
            continue
        try:
            start_hour = max(0, min(23, int(entry.get("startHour", 0))))
            start_minute = max(0, min(59, int(entry.get("startMinute", 0))))
            duration = max(1, min(24, int(entry.get("durationHours", 12)))) * 3600
            days = {int(day) for day in entry.get("days", []) if 0 <= int(day) <= 6}
        except (TypeError, ValueError):
            continue

        start_seconds = start_hour * 3600 + start_minute * 60
        for day_offset in (-1, 0):
            start_day = day_number + day_offset
            weekday = (start_day + 4) % 7
            if weekday not in days:
                continue
            elapsed = second_of_day + (86400 if day_offset == -1 else 0) - start_seconds
            if 0 <= elapsed < duration:
                # Stable priority matches the engine's specialist roster.
                candidates.append((elapsed, bot_id))
                break

    if not candidates:
        return "MinusBright", None

    # Prefer the active shift that started most recently. Roster order breaks ties.
    _, selected = min(candidates, key=lambda item: item[0])
    entry = config["entries"][selected]
    start = int(entry.get("startHour", 0)) * 3600 + int(entry.get("startMinute", 0)) * 60
    elapsed = second_of_day - start
    if elapsed < 0:
        elapsed += 86400
    remaining = max(0.0, int(entry.get("durationHours", 12)) * 3600 - elapsed)
    return selected, remaining


def make_status(config_path: Path) -> dict[str, Any]:
    config = read_config(config_path)
    selected, remaining = active_bot(config)
    now = datetime.now(timezone.utc).isoformat()
    return {
        "service": "OUTER!ENGINE Assistant Scheduler",
        "timestampUtc": now,
        "mode": config.get("executionMode", "both"),
        "globallyEnabled": bool(config.get("globallyEnabled", True)),
        "activeAssistant": selected,
        "secondsRemaining": remaining,
        "timezoneOffset": int(config.get("timezoneOffset", -3)),
        "schedules": config.get("entries", {}),
        "note": "Scheduler availability only; a provider adapter is needed to run external chat bots."
    }


class SchedulerHandler(BaseHTTPRequestHandler):
    config_path: Path

    def _send_json(self, status: int, body: dict[str, Any]) -> None:
        payload = json.dumps(body, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self) -> None:
        if self.path not in ("/", "/health", "/status", "/assistant"):
            self._send_json(404, {"error": "not_found", "available": ["/health", "/status", "/assistant"]})
            return
        try:
            status = make_status(self.config_path)
            if self.path == "/health":
                self._send_json(200, {"ok": True, "service": status["service"]})
            elif self.path == "/assistant":
                self._send_json(200, {
                    "activeAssistant": status["activeAssistant"],
                    "secondsRemaining": status["secondsRemaining"],
                    "mode": status["mode"],
                })
            else:
                self._send_json(200, status)
        except RuntimeError as exc:
            self._send_json(500, {"error": "config_error", "message": str(exc)})

    def log_message(self, fmt: str, *args: Any) -> None:
        print("[scheduler] " + (fmt % args))


def main() -> None:
    parser = argparse.ArgumentParser(description="Run the OUTER!ENGINE assistant schedule worker.")
    parser.add_argument("--config", default="outer_assistant_schedule.json", help="Path to the shared JSON schedule.")
    parser.add_argument("--host", default="127.0.0.1", help="Bind address. Keep localhost unless remote access is secured.")
    parser.add_argument("--port", type=int, default=8765, help="HTTP port, default 8765.")
    args = parser.parse_args()

    config_path = Path(args.config).expanduser().resolve()
    read_config(config_path)
    handler = type("BoundSchedulerHandler", (SchedulerHandler,), {"config_path": config_path})
    server = ThreadingHTTPServer((args.host, args.port), handler)
    print(f"OUTER!ENGINE scheduler running at http://{args.host}:{args.port}/status")
    print(f"Schedule file: {config_path}")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        print("\nStopping OUTER!ENGINE scheduler...")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
