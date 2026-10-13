package backend.outer;

import flixel.FlxG;

/**
 * Persistent per-assistant schedule.
 *
 * Days use Date.getDay() conventions: Sunday=0 through Saturday=6.
 * Times are evaluated against a configurable fixed UTC offset.
 *
 * This class schedules assistant availability inside OUTER!ENGINE. A separate
 * background worker is still required for autonomous external integrations
 * while the game process is closed.
 */
class AssistantSchedule
{
    public static var timezoneOffset:Int = -3;
    public static var globallyEnabled:Bool = true;
    public static var executionMode:String = "both"; // engine, background, both

    static var loaded:Bool = false;
    static var entries:Map<String, Dynamic> = new Map<String, Dynamic>();

    static inline var DAY_SECONDS:Float = 86400.0;

    public static function ensureLoaded():Void
    {
        if (loaded) return;
        loaded = true;

        entries.set("OuterQT", makeEntry(true, 6, 0, 12, [0, 1, 2, 3, 4, 5, 6], "daytime"));
        entries.set("OuterSky", makeEntry(true, 18, 0, 12, [0, 1, 2, 3, 4, 5, 6], "evening"));
        entries.set("OuterNikku", makeEntry(false, 0, 0, 8, [1, 2, 3, 4, 5], "workday"));
        entries.set("OuterCarol", makeEntry(false, 9, 0, 8, [1, 2, 3, 4, 5], "workday"));

        try
        {
            if (FlxG.save != null && FlxG.save.data.outerAssistantSchedule != null)
            {
                var saved:Dynamic = FlxG.save.data.outerAssistantSchedule;
                if (Reflect.hasField(saved, "timezoneOffset")) timezoneOffset = Std.int(saved.timezoneOffset);
                if (Reflect.hasField(saved, "globallyEnabled")) globallyEnabled = saved.globallyEnabled == true;
                if (Reflect.hasField(saved, "executionMode")) executionMode = normalizeMode(Std.string(saved.executionMode));

                if (Reflect.hasField(saved, "entries"))
                {
                    var savedEntries:Dynamic = saved.entries;
                    for (id in ["OuterQT", "OuterSky", "OuterNikku", "OuterCarol"])
                    {
                        var value:Dynamic = Reflect.field(savedEntries, id);
                        if (value != null) entries.set(id, sanitizeEntry(value, id));
                    }
                }
            }
        }
        catch (e:Dynamic)
        {
            trace("OUTER!ENGINE schedule: could not load saved configuration: " + e);
        }
    }

    static function makeEntry(enabled:Bool, hour:Int, minute:Int, duration:Int, days:Array<Int>, preset:String):Dynamic
    {
        return {
            enabled: enabled,
            startHour: hour,
            startMinute: minute,
            durationHours: duration,
            days: days.copy(),
            preset: preset
        };
    }

    static function sanitizeEntry(value:Dynamic, id:String):Dynamic
    {
        var fallback:Dynamic = entries.get(id);
        var hour:Int = Reflect.hasField(value, "startHour") ? Std.int(value.startHour) : fallback.startHour;
        var minute:Int = Reflect.hasField(value, "startMinute") ? Std.int(value.startMinute) : fallback.startMinute;
        var duration:Int = Reflect.hasField(value, "durationHours") ? Std.int(value.durationHours) : fallback.durationHours;
        var days:Array<Int> = Reflect.hasField(value, "days") && Std.isOfType(value.days, Array) ? cast value.days : cast fallback.days;
        var preset:String = Reflect.hasField(value, "preset") ? Std.string(value.preset) : "custom";
        return makeEntry(
            Reflect.hasField(value, "enabled") ? value.enabled == true : fallback.enabled,
            clamp(hour, 0, 23),
            clamp(minute, 0, 59),
            clamp(duration, 1, 24),
            sanitizeDays(days),
            preset
        );
    }

    static function sanitizeDays(days:Array<Int>):Array<Int>
    {
        var result:Array<Int> = [];
        if (days != null)
            for (day in days)
                if (day >= 0 && day <= 6 && result.indexOf(day) < 0) result.push(day);
        return result;
    }

    static inline function clamp(value:Int, minimum:Int, maximum:Int):Int
    {
        return value < minimum ? minimum : (value > maximum ? maximum : value);
    }

    static function normalizeMode(mode:String):String
    {
        return switch (mode == null ? "" : mode.toLowerCase())
        {
            case "engine", "in-engine", "game": "engine";
            case "background", "service", "daemon": "background";
            default: "both";
        };
    }

    public static function setExecutionMode(mode:String):Void
    {
        ensureLoaded();
        executionMode = normalizeMode(mode);
        save();
    }

    public static function setGlobalEnabled(enabled:Bool):Void
    {
        ensureLoaded();
        globallyEnabled = enabled;
        save();
    }

    public static function setTimezoneOffset(offset:Int):Void
    {
        ensureLoaded();
        timezoneOffset = clamp(offset, -12, 14);
        save();
    }

    public static function getEntry(id:String):Dynamic
    {
        ensureLoaded();
        return entries.exists(id) ? entries.get(id) : null;
    }

    public static function setEnabled(id:String, enabled:Bool):Void
    {
        var entry = getEntry(id);
        if (entry == null) return;
        entry.enabled = enabled;
        entry.preset = "custom";
        save();
    }

    public static function setStartTime(id:String, hour:Int, minute:Int = 0):Void
    {
        var entry = getEntry(id);
        if (entry == null) return;
        entry.startHour = clamp(hour, 0, 23);
        entry.startMinute = clamp(minute, 0, 59);
        entry.preset = "custom";
        save();
    }

    public static function setDuration(id:String, hours:Int):Void
    {
        var entry = getEntry(id);
        if (entry == null) return;
        entry.durationHours = clamp(hours, 1, 24);
        entry.preset = "custom";
        save();
    }

    public static function setDays(id:String, days:Array<Int>):Void
    {
        var entry = getEntry(id);
        if (entry == null) return;
        entry.days = sanitizeDays(days);
        entry.preset = "custom";
        save();
    }

    public static function applyPreset(id:String, preset:String):Void
    {
        var entry = getEntry(id);
        if (entry == null) return;

        switch (preset == null ? "" : preset.toLowerCase())
        {
            case "always", "24h":
                entry.enabled = true;
                entry.startHour = 0;
                entry.startMinute = 0;
                entry.durationHours = 24;
                entry.days = [0, 1, 2, 3, 4, 5, 6];
                entry.preset = "always";
            case "daytime", "morning":
                entry.enabled = true;
                entry.startHour = 6;
                entry.startMinute = 0;
                entry.durationHours = 12;
                entry.days = [0, 1, 2, 3, 4, 5, 6];
                entry.preset = "daytime";
            case "evening", "night":
                entry.enabled = true;
                entry.startHour = 18;
                entry.startMinute = 0;
                entry.durationHours = 12;
                entry.days = [0, 1, 2, 3, 4, 5, 6];
                entry.preset = "evening";
            case "workday", "weekday":
                entry.enabled = true;
                entry.startHour = 9;
                entry.startMinute = 0;
                entry.durationHours = 8;
                entry.days = [1, 2, 3, 4, 5];
                entry.preset = "workday";
            case "disabled", "off":
                entry.enabled = false;
                entry.preset = "disabled";
            default:
                entry.preset = "custom";
        }
        save();
    }

    public static function isAvailable(id:String, ?timestampMs:Float):Bool
    {
        ensureLoaded();
        if (!globallyEnabled || id == "MinusBright") return id == "MinusBright";
        var entry = getEntry(id);
        if (entry == null || !entry.enabled) return false;
        if (executionMode == "background") return false;

        var nowMs:Float = timestampMs == null ? Date.now().getTime() : timestampMs;
        var localSeconds:Float = nowMs / 1000.0 + timezoneOffset * 3600.0;
        var currentDay:Int = Std.int(Math.floor(localSeconds / DAY_SECONDS));
        var secondOfDay:Float = localSeconds - currentDay * DAY_SECONDS;
        var startSeconds:Float = entry.startHour * 3600.0 + entry.startMinute * 60.0;
        var durationSeconds:Float = entry.durationHours * 3600.0;

        // Check today's shift and yesterday's shift, so overnight schedules work.
        for (dayOffset in [-1, 0])
        {
            var startDay:Int = currentDay + dayOffset;
            var weekday:Int = (startDay + 4) % 7;
            if (weekday < 0) weekday += 7;
            if (cast(entry.days, Array<Int>).indexOf(weekday) < 0) continue;

            var elapsed:Float = secondOfDay + (dayOffset == -1 ? DAY_SECONDS : 0) - startSeconds;
            if (elapsed >= 0 && elapsed < durationSeconds) return true;
        }
        return false;
    }

    public static function getActiveAssistant(?timestampMs:Float):String
    {
        ensureLoaded();
        if (!globallyEnabled) return "MinusBright";
        for (id in ["OuterQT", "OuterSky", "OuterNikku", "OuterCarol"])
            if (isAvailable(id, timestampMs)) return id;
        return "MinusBright";
    }

    public static function getSecondsUntilChange(?timestampMs:Float):Float
    {
        ensureLoaded();
        var nowMs:Float = timestampMs == null ? Date.now().getTime() : timestampMs;
        var current:String = getActiveAssistant(nowMs);
        var step:Float = 60.0;
        var elapsed:Float = 0;
        // Minute granularity is enough for the UI countdown and avoids per-frame scanning.
        while (elapsed < 48 * 3600)
        {
            elapsed += step;
            if (getActiveAssistant(nowMs + elapsed * 1000.0) != current) return elapsed;
        }
        return 0;
    }

    public static function save():Void
    {
        ensureLoaded();
        try
        {
            if (FlxG.save == null) return;
            var stored:Dynamic = {};
            for (id in ["OuterQT", "OuterSky", "OuterNikku", "OuterCarol"])
                Reflect.setField(stored, id, entries.get(id));
            FlxG.save.data.outerAssistantSchedule = {
                timezoneOffset: timezoneOffset,
                globallyEnabled: globallyEnabled,
                executionMode: executionMode,
                entries: stored
            };
            FlxG.save.flush();
        }
        catch (e:Dynamic)
        {
            trace("OUTER!ENGINE schedule: could not save configuration: " + e);
        }
    }

    public static function getStatusSummary(id:String):String
    {
        var entry = getEntry(id);
        if (entry == null) return "No schedule";
        var start:String = StringTools.lpad(Std.string(entry.startHour), "0", 2) + ":" +
            StringTools.lpad(Std.string(entry.startMinute), "0", 2);
        var status:String = entry.enabled ? "enabled" : "disabled";
        return status + " | " + start + " | " + entry.durationHours + "h | " + entry.preset;
    }
}
