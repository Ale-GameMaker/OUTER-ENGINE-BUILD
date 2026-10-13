# OUTER!ENGINE Assistant Scheduler

The schedule is shared between the Haxe engine and a standalone Python worker through
`outer_assistant_schedule.json`. The engine writes this file in its current working directory when the schedule is first loaded or changed.

## Run the background worker

1. Start OUTER!ENGINE once and change any schedule setting, or create `outer_assistant_schedule.json` in the same directory as the game.
2. Keep the worker script and the JSON file in a location you can write to.
3. Run `tools\start_outer_assistant_scheduler.bat` or from CMD:

```bat
py -3 tools\outer_assistant_scheduler.py
```

The worker runs independently of the game window until Ctrl+C closes it. By default it binds only to `127.0.0.1:8765`.

## Local endpoints

- `GET http://127.0.0.1:8765/health`: worker health.
- `GET http://127.0.0.1:8765/status`: active assistant, current mode, schedules and time remaining.
- `GET http://127.0.0.1:8765/assistant`: compact active-assistant response.

## Schedule schema

Each bot entry contains `enabled`, `startHour` (0-23), `startMinute` (0-59), `durationHours` (1-24), `days` (Sunday=0 through Saturday=6), and `preset`. Overnight shifts are supported. The default timezone offset is UTC-3.

## Important limitation

This worker evaluates schedules and exposes the current availability over localhost. It does **not** log into Discord or another provider and does not run an external chat-bot session by itself. A provider adapter must consume this API and implement the provider's actual online/offline lifecycle. The in-engine assistant schedule itself works without that adapter.
