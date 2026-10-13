package backend.outer;

import haxe.ds.StringMap;
import flixel.FlxG;

/** Small allocation-conscious helpers; use them where profiling shows a benefit. */
class OuterPerformance
{
    public static inline var MIN_FRAME_DELTA:Float = 0.0;
    public static inline var MAX_FRAME_DELTA:Float = 1.0 / 15.0;

    /** Clamp pathological frame deltas after stalls or debugger pauses. */
    public static inline function clampFrameDelta(delta:Float):Float
    {
        if (Math.isNaN(delta) || delta < MIN_FRAME_DELTA) return MIN_FRAME_DELTA;
        return delta > MAX_FRAME_DELTA ? MAX_FRAME_DELTA : delta;
    }

    /** Convert a user-facing quality choice into a predictable render scale. */
    public static function renderScale(quality:String):Float
    {
        return switch (quality == null ? "normal" : quality.toLowerCase())
        {
            case "low", "potato": 0.5;
            case "medium", "normal": 0.75;
            case "high": 1.0;
            case "ultra": 1.0;
            default: 0.75;
        };
    }

    // Runtime telemetry and adaptive quality, kept alongside the existing helpers.
    public static var targetFPS(default, null):Int = 60;
    public static var adaptiveQuality(default, null):Bool = true;
    public static var qualityProfile(default, null):String = "balanced";
    public static var frameTimeMs(default, null):Float = 0;
    public static var averageFrameTimeMs(default, null):Float = 0;
    public static var worstFrameTimeMs(default, null):Float = 0;
    public static var estimatedFPS(default, null):Float = 0;
    public static var hitchCount(default, null):Int = 0;
    public static var droppedFrameCount(default, null):Int = 0;
    public static var qualityTier(default, null):Int = 1;

    static var frameSamples:Array<Float> = [];
    static var badTime:Float = 0;
    static var goodTime:Float = 0;

    public static function loadSettings():Void
    {
        try
        {
            if (FlxG.save != null && FlxG.save.data.outerPerformance != null)
            {
                var saved:Dynamic = FlxG.save.data.outerPerformance;
                if (Reflect.hasField(saved, "targetFPS")) targetFPS = clampFPS(Std.int(saved.targetFPS));
                if (Reflect.hasField(saved, "adaptiveQuality")) adaptiveQuality = saved.adaptiveQuality == true;
                if (Reflect.hasField(saved, "qualityProfile")) qualityProfile = normalizeProfile(Std.string(saved.qualityProfile));
            }
        }
        catch (e:Dynamic) trace("OUTER!ENGINE performance settings load failed: " + e);
        applyProfileTier();
    }

    public static function saveSettings():Void
    {
        try
        {
            if (FlxG.save == null) return;
            FlxG.save.data.outerPerformance = {
                targetFPS: targetFPS,
                adaptiveQuality: adaptiveQuality,
                qualityProfile: qualityProfile
            };
            FlxG.save.flush();
        }
        catch (e:Dynamic) trace("OUTER!ENGINE performance settings save failed: " + e);
    }

    public static function setTargetFPS(value:Int):Void
    {
        targetFPS = clampFPS(value);
        applyFrameRate();
        saveSettings();
    }

    public static function setAdaptiveQuality(enabled:Bool):Void
    {
        adaptiveQuality = enabled;
        badTime = 0;
        goodTime = 0;
        saveSettings();
    }

    public static function setQualityProfile(profile:String):Void
    {
        qualityProfile = normalizeProfile(profile);
        applyProfileTier();
        saveSettings();
    }

    public static function applyFrameRate():Void
    {
        var target:Int = clampFPS(targetFPS);
        try
        {
            FlxG.updateFramerate = target;
            FlxG.drawFramerate = target;
        }
        catch (e:Dynamic) trace("OUTER!ENGINE could not apply frame cap: " + e);
    }

    public static function recordFrame(elapsedSeconds:Float):Void
    {
        if (elapsedSeconds <= 0 || Math.isNaN(elapsedSeconds) || elapsedSeconds > 1000000) return;
        frameTimeMs = elapsedSeconds * 1000.0;
        estimatedFPS = 1.0 / elapsedSeconds;
        if (frameTimeMs > worstFrameTimeMs) worstFrameTimeMs = frameTimeMs;
        if (frameTimeMs > 1000.0 / targetFPS * 1.75) hitchCount++;
        if (frameTimeMs > 1000.0 / targetFPS * 1.5) droppedFrameCount++;

        frameSamples.push(frameTimeMs);
        if (frameSamples.length > 120) frameSamples.shift();
        var total:Float = 0;
        for (sample in frameSamples) total += sample;
        averageFrameTimeMs = frameSamples.length > 0 ? total / frameSamples.length : frameTimeMs;

        if (!adaptiveQuality || qualityProfile != "adaptive") return;
        var budget:Float = 1000.0 / targetFPS;
        if (averageFrameTimeMs > budget * 1.18)
        {
            badTime += elapsedSeconds;
            goodTime = 0;
            if (badTime >= 2.0 && qualityTier > 0) { qualityTier--; badTime = 0; }
        }
        else if (averageFrameTimeMs < budget * 0.78)
        {
            goodTime += elapsedSeconds;
            badTime = 0;
            if (goodTime >= 8.0 && qualityTier < 2) { qualityTier++; goodTime = 0; }
        }
        else { badTime = 0; goodTime = 0; }
    }

    public static function getParticleMultiplier():Float
    {
        return switch (qualityTier) { case 0: 0.25; case 1: 0.60; default: 1.0; };
    }

    public static function shouldUseExpensiveEffects():Bool return qualityTier >= 2;

    public static function resetSessionMetrics():Void
    {
        frameSamples = [];
        frameTimeMs = averageFrameTimeMs = worstFrameTimeMs = estimatedFPS = 0;
        hitchCount = droppedFrameCount = 0;
        badTime = goodTime = 0;
    }

    static function applyProfileTier():Void
    {
        qualityTier = switch (qualityProfile)
        {
            case "low": 0;
            case "high", "ultra": 2;
            case "adaptive": 2;
            default: 1;
        };
    }

    static function normalizeProfile(profile:String):String
    {
        return switch (profile == null ? "" : profile.toLowerCase())
        {
            case "low", "potato", "performance": "low";
            case "high", "ultra", "quality": "high";
            case "adaptive", "auto": "adaptive";
            default: "balanced";
        };
    }

    static inline function clampFPS(value:Int):Int return value < 30 ? 30 : (value > 360 ? 360 : value);

}

/**
 * Bounded FIFO cache for derived data (parsed charts, lookup tables, etc.).
 * Avoids unbounded growth and does not assume that cached values are disposable
 * engine assets. Callers remain responsible for destroying FlxGraphic/FlxSound.
 */
class OuterBoundedCache<T>
{
    var values:StringMap<T>;
    var order:Array<String>;
    public var capacity(default, null):Int;

    public function new(capacity:Int = 64)
    {
        this.capacity = capacity < 1 ? 1 : capacity;
        values = new StringMap<T>();
        order = [];
    }

    public inline function exists(key:String):Bool return values.exists(key);
    public inline function get(key:String):Null<T> return values.get(key);

    public function set(key:String, value:T):Void
    {
        if (values.exists(key))
        {
            values.set(key, value);
            return;
        }
        values.set(key, value);
        order.push(key);
        while (order.length > capacity)
        {
            var oldest:String = order.shift();
            values.remove(oldest);
        }
    }

    public function remove(key:String):Void
    {
        if (!values.exists(key)) return;
        values.remove(key);
        order.remove(key);
    }

    public function clear():Void
    {
        values = new StringMap<T>();
        order = [];
    }

    public inline function size():Int return order.length;
}
