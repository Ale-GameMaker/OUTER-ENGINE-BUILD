package backend.outer;

import haxe.ds.StringMap;

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
