# OUTER!ENGINE: Ultimate Parser(TM) and local assistants

## Scope

The first parser layer normalizes chart note and event data into a shared model.
It does **not** make complete mods portable between engines. Stage scripts, shaders,
characters, event callbacks, note behaviors, dialogue, assets and engine APIs remain
engine-specific and need adapters or manual migration.

Supported import targets currently attempted by the parser:

- **Psych Engine:** section-based `sectionNotes`, `mustHitSection`, note types and legacy events.
- **Kade Engine:** Psych-style chart structures and generic note objects.
- **Mic'd Up:** Psych-compatible charts where the chart schema matches; pass `MICDUP` explicitly if detection is ambiguous.
- **Codename Engine:** generic object notes and metadata when represented in the supported fields. Full Codename mod conversion requires dedicated adapters.
- **V-Slice:** generic object notes using time/lane/duration-style fields. Native variation/metadata/chart formats require a dedicated adapter.

Example:

```haxe
import backend.outer.UltimateParser;
import backend.outer.UltimateParser.EngineFormat;

var chart = UltimateParser.parseChart(chartJson, EngineFormat.PSYCH);
trace(chart.title + " / " + chart.notes.length + " notes");
for (warning in chart.warnings) trace("Parser: " + warning);
```

The `raw` field on the chart, notes and events is preserved so future adapters can
inspect engine-specific data without losing the original fields. Always inspect warnings
and compare imported charts in-game; automatic conversion can never infer every custom
mod mechanic.

## Local AI assistants

The `OuterAI` bridge is opt-in and points to local Ollama by default:

1. Install Ollama and download a model, for example `ollama pull llama3.2:3b`.
2. Start Ollama locally.
3. Set `OuterAI.enabled = true` from a user-controlled settings screen or developer console.
4. Select an assistant profile and call `OuterAI.ask("outer_qt", "Help me chart this song", callback)`.

Available assistant IDs:

- `outer_qt`: charts, timing, chart authoring and conversion.
- `outer_sky`: chart events and equivalent event systems in other engines.
- `outer_skyblue`: Sky's more mature-toned variant.
- `outer_nikku`: Lua/Haxe and equivalent gameplay scripts.
- `outer_carol`: stages, environments and visual layout.
- `minusbright`: general engine support, always available.

The four specialists rotate in configurable 12-hour local-time blocks. Set
`AssistantManager.timeZoneOffset` to the local UTC offset (whole hours); the Options
menu exposes this setting. MinusBright is not part of the rotation and remains available
at all times. SkyBlue changes Sky's personality profile, not her technical role.

The engine sends prompts only to the configured endpoint. The default endpoint is
`http://127.0.0.1:11434/api/generate`. Do not change it to a remote endpoint without
making that behavior explicit to the user. Builds without `sys` support return a
clear message instead of attempting network access.

These assistant profiles provide prompts and a connection bridge, not a bundled model.
No AI can safely rewrite project source files without an explicit, reviewable file-editing workflow.

## Performance utilities

`OuterPerformance` contains a frame-delta clamp and quality scale helper.
`OuterBoundedCache<T>` is a bounded FIFO cache for derived data. These are utilities,
not automatic engine-wide optimizations. Integrate them at measured hot spots and profile
before/after. Do not cache disposable Flixel assets without explicit lifecycle handling.
