package backend.outer;

import haxe.Json;

/**
 * Ultimate Parser(TM) for OUTER!ENGINE.
 *
 * This is a compatibility/import layer, not a promise that every engine's
 * entire mod format is interchangeable. It normalizes chart note/event data
 * into one representation while retaining raw source objects for extensions.
 */
enum EngineFormat
{
    AUTO;
    PSYCH;
    KADE;
    MICDUP;
    CODENAME;
    VSLICE;
    UNKNOWN;
}

typedef UnifiedNote =
{
    var time:Float;
    var lane:Int;
    var duration:Float;
    var mustPress:Bool;
    var section:Int;
    var kind:String;
    var raw:Dynamic;
}

typedef UnifiedEvent =
{
    var time:Float;
    var name:String;
    var value1:String;
    var value2:String;
    var raw:Dynamic;
}

typedef UnifiedChart =
{
    var title:String;
    var bpm:Float;
    var speed:Float;
    var source:EngineFormat;
    var notes:Array<UnifiedNote>;
    var events:Array<UnifiedEvent>;
    var warnings:Array<String>;
    var raw:Dynamic;
}

class UltimateParser
{
    public static function parseChart(text:String, ?requested:EngineFormat = AUTO):UnifiedChart
    {
        var root:Dynamic;
        try
        {
            root = Json.parse(text);
        }
        catch (e:Dynamic)
        {
            throw "Ultimate Parser: invalid JSON (" + Std.string(e) + ")";
        }

        var song:Dynamic = field(root, "song");
        if (song == null) song = root;

        var format:EngineFormat = requested == AUTO ? detect(root, song) : requested;
        var chart:UnifiedChart =
        {
            title: firstString(song, ["song", "title", "name"], "Unknown Song"),
            bpm: firstNumber(song, ["bpm", "beatsPerMinute"], 100),
            speed: firstNumber(song, ["speed", "scrollSpeed"], 1),
            source: format,
            notes: [],
            events: [],
            warnings: [],
            raw: root
        };

        if (chart.bpm <= 0)
        {
            chart.warnings.push("BPM was missing or invalid; using 100.");
            chart.bpm = 100;
        }
        if (chart.speed <= 0)
        {
            chart.warnings.push("Scroll speed was missing or invalid; using 1.");
            chart.speed = 1;
        }

        var noteData:Dynamic = field(song, "notes");
        if (noteData == null) noteData = field(song, "chartData");
        if (noteData == null) noteData = field(root, "notes");

        if (Std.isOfType(noteData, Array))
        {
            var entries:Array<Dynamic> = cast noteData;
            if (looksLikePsychSections(entries))
                parseSectionNotes(entries, chart);
            else
                parseObjectNotes(entries, chart);
        }
        else
        {
            chart.warnings.push("No recognized note array was found.");
        }

        parseEvents(song, root, chart);
        chart.notes.sort(function(a, b) return a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
        chart.events.sort(function(a, b) return a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));
        return chart;
    }

    public static function detect(root:Dynamic, ?song:Dynamic):EngineFormat
    {
        if (song == null) song = field(root, "song");
        if (song == null) song = root;

        var version:String = firstString(root, ["version", "formatVersion"], "").toLowerCase();
        var rootVersion:String = firstString(song, ["version", "formatVersion"], "").toLowerCase();

        if (version.indexOf("v-slice") >= 0 || version.indexOf("vslice") >= 0 ||
            rootVersion.indexOf("v-slice") >= 0 || field(song, "playData") != null)
            return VSLICE;

        if (field(song, "song") != null && field(song, "notes") != null)
        {
            var notes:Dynamic = field(song, "notes");
            if (Std.isOfType(notes, Array) && looksLikePsychSections(cast notes))
                return PSYCH;
        }

        if (field(root, "codename") != null || field(song, "stage") != null && field(song, "characters") != null)
            return CODENAME;

        // Mic'd Up and many Kade charts are Psych-compatible JSON. The caller
        // can explicitly request either when metadata cannot disambiguate them.
        if (field(root, "mic'd up") != null || field(root, "micdUp") != null)
            return MICDUP;
        if (field(root, "kadeEngine") != null || field(root, "kade") != null)
            return KADE;

        if (field(song, "notes") != null) return PSYCH;
        return UNKNOWN;
    }

    static function looksLikePsychSections(entries:Array<Dynamic>):Bool
    {
        if (entries.length == 0) return false;
        var first:Dynamic = entries[0];
        return field(first, "sectionNotes") != null || field(first, "mustHitSection") != null;
    }

    static function parseSectionNotes(sections:Array<Dynamic>, chart:UnifiedChart):Void
    {
        for (sectionIndex in 0...sections.length)
        {
            var section:Dynamic = sections[sectionIndex];
            var notes:Dynamic = field(section, "sectionNotes");
            if (!Std.isOfType(notes, Array)) continue;

            var sectionNotes:Array<Dynamic> = cast notes;
            var sectionMustHit:Bool = boolValue(field(section, "mustHitSection"), false);
            for (entry in sectionNotes)
            {
                if (Std.isOfType(entry, Array))
                {
                    var values:Array<Dynamic> = cast entry;
                    if (values.length < 2) continue;
                    var time:Float = number(values[0], 0);
                    var rawLane:Int = Std.int(number(values[1], 0));
                    var playerSide:Bool = sectionMustHit;
                    if (rawLane > 3) playerSide = !playerSide;
                    var lane:Int = rawLane % 4;
                    var duration:Float = values.length > 2 ? number(values[2], 0) : 0;
                    var kind:String = values.length > 3 ? Std.string(values[3]) : "";
                    chart.notes.push({
                        time: time,
                        lane: lane,
                        duration: duration < 0 ? 0 : duration,
                        mustPress: playerSide,
                        section: sectionIndex,
                        kind: kind,
                        raw: entry
                    });
                }
                else
                {
                    addObjectNote(entry, sectionIndex, sectionMustHit, chart);
                }
            }
        }
    }

    static function parseObjectNotes(entries:Array<Dynamic>, chart:UnifiedChart):Void
    {
        for (entry in entries)
            addObjectNote(entry, intValue(field(entry, "section"), 0),
                boolValue(field(entry, "mustPress"), boolValue(field(entry, "player"), false)), chart);
    }

    static function addObjectNote(entry:Dynamic, sectionIndex:Int, sectionMustHit:Bool, chart:UnifiedChart):Void
    {
        if (entry == null) return;

        var time:Float = firstNumber(entry, ["time", "strumTime", "t"], Math.NaN);
        var laneValue:Float = firstNumber(entry, ["lane", "direction", "noteData", "data", "key"], Math.NaN);
        if (Math.isNaN(time) || Math.isNaN(laneValue))
        {
            chart.warnings.push("Skipped a note with no recognized time/lane fields.");
            return;
        }

        var lane:Int = Std.int(laneValue);
        var mustPress:Bool = boolValue(field(entry, "mustPress"),
            boolValue(field(entry, "mustHitSection"), sectionMustHit));
        if (lane > 3)
        {
            lane = lane % 4;
            if (field(entry, "mustPress") == null) mustPress = !mustPress;
        }

        var duration:Float = firstNumber(entry, ["duration", "sustainLength", "length"], 0);
        chart.notes.push({
            time: time,
            lane: lane,
            duration: duration < 0 ? 0 : duration,
            mustPress: mustPress,
            section: sectionIndex,
            kind: firstString(entry, ["kind", "type", "noteType"], ""),
            raw: entry
        });
    }

    static function parseEvents(song:Dynamic, root:Dynamic, chart:UnifiedChart):Void
    {
        var data:Dynamic = field(song, "events");
        if (data == null) data = field(root, "events");
        if (!Std.isOfType(data, Array)) return;

        var events:Array<Dynamic> = cast data;
        for (entry in events)
        {
            if (Std.isOfType(entry, Array))
            {
                var row:Array<Dynamic> = cast entry;
                if (row.length < 2) continue;
                var time:Float = number(row[0], 0);
                var nested:Dynamic = row[1];
                if (Std.isOfType(nested, Array))
                {
                    for (eventData in (cast nested:Array<Dynamic>))
                    {
                        if (Std.isOfType(eventData, Array))
                        {
                            var values:Array<Dynamic> = cast eventData;
                            chart.events.push({
                                time: time,
                                name: values.length > 0 ? Std.string(values[0]) : "Unknown",
                                value1: values.length > 1 ? Std.string(values[1]) : "",
                                value2: values.length > 2 ? Std.string(values[2]) : "",
                                raw: eventData
                            });
                        }
                    }
                }
            }
            else
            {
                var time:Float = firstNumber(entry, ["time", "strumTime", "timestamp"], Math.NaN);
                if (Math.isNaN(time)) continue;
                chart.events.push({
                    time: time,
                    name: firstString(entry, ["name", "event", "type"], "Unknown"),
                    value1: firstString(entry, ["value1", "value", "param1"], ""),
                    value2: firstString(entry, ["value2", "param2"], ""),
                    raw: entry
                });
            }
        }
    }

    static inline function field(value:Dynamic, name:String):Dynamic
        return value != null && Reflect.hasField(value, name) ? Reflect.field(value, name) : null;

    static function firstString(value:Dynamic, names:Array<String>, fallback:String):String
    {
        for (name in names)
        {
            var v:Dynamic = field(value, name);
            if (v != null && Std.string(v) != "") return Std.string(v);
        }
        return fallback;
    }

    static function firstNumber(value:Dynamic, names:Array<String>, fallback:Float):Float
    {
        for (name in names)
        {
            var v:Dynamic = field(value, name);
            if (v != null)
            {
                var n:Float = number(v, Math.NaN);
                if (!Math.isNaN(n)) return n;
            }
        }
        return fallback;
    }

    static function number(value:Dynamic, fallback:Float):Float
    {
        if (value == null) return fallback;
        var n:Float = Std.parseFloat(Std.string(value));
        return Math.isNaN(n) ? fallback : n;
    }

    static function intValue(value:Dynamic, fallback:Int):Int
    {
        var n:Float = number(value, fallback);
        return Std.int(n);
    }

    static function boolValue(value:Dynamic, fallback:Bool):Bool
    {
        if (value == null) return fallback;
        if (Std.isOfType(value, Bool)) return cast value;
        var text:String = Std.string(value).toLowerCase();
        if (text == "true" || text == "1") return true;
        if (text == "false" || text == "0") return false;
        return fallback;
    }
}
