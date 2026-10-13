package backend;

import flixel.FlxG;

/**
 * Manages the rotating 12-hour specialist schedule.
 * MinusBright is available at all times and is not part of the rotation.
 *
 * timeZoneOffset is the local UTC offset in whole hours (e.g. -3 for
 * Brasília standard time). Users can change it from Options.
 */
class AssistantManager
{
    public static var currentAssistant:String = "OuterQT";
    public static var usageTimeLeft:Float = 12 * 3600;
    public static var timeZoneOffset:Int = -3;
    public static var skyVariant:String = "Normal";
    public static var isMinusBrightGlobal:Bool = false;

    static var lastSlot:Int = -1;
    static var elapsedFallback:Float = 0;

    static inline var SHIFT_SECONDS:Float = 12 * 60 * 60;
    static var rotation:Array<String> = ["OuterQT", "OuterSky", "OuterNikku", "OuterCarol"];

    /** Call from a state update if the UI needs a live countdown. */
    public static function updateTimer(elapsed:Float):Void
    {
        elapsedFallback += elapsed;
        var now:Float = Date.now().getTime() / 1000.0;
        var localNow:Float = now + timeZoneOffset * 3600.0;
        var slot:Int = Std.int(Math.floor(localNow / SHIFT_SECONDS));
        var rotationIndex:Int = slot % rotation.length;
        if (rotationIndex < 0) rotationIndex += rotation.length;

        var remaining:Float = SHIFT_SECONDS - (localNow % SHIFT_SECONDS);
        if (remaining < 0 || remaining > SHIFT_SECONDS) remaining = SHIFT_SECONDS;

        if (slot != lastSlot)
        {
            lastSlot = slot;
            currentAssistant = rotation[rotationIndex];
        }
        usageTimeLeft = remaining;
        isMinusBrightGlobal = false;
    }

    /** Recalculate immediately after changing timezone or Sky's variant. */
    public static function refreshSchedule():Void
    {
        lastSlot = -1;
        updateTimer(0);
    }

    public static function resetShift():Void
    {
        lastSlot = -1;
        elapsedFallback = 0;
        refreshSchedule();
    }

    /** MinusBright is always selectable, even while a specialist is on shift. */
    public static function selectAssistant(id:String):Void
    {
        currentAssistant = switch (id == null ? "" : id.toLowerCase())
        {
            case "outerqt", "outer_qt", "qt": "OuterQT";
            case "outersky", "outer_sky", "sky": "OuterSky";
            case "skyblue", "outer_skyblue": "OuterSky";
            case "outernikku", "outer_nikku", "nikku": "OuterNikku";
            case "outercarol", "outer_carol", "carol": "OuterCarol";
            case "minusbright", "minus_bright": "MinusBright";
            default: currentAssistant;
        };
        if (id != null && (id.toLowerCase() == "skyblue" || id.toLowerCase() == "outer_skyblue"))
            skyVariant = "SkyBlue";
        else if (id != null && (id.toLowerCase() == "outersky" || id.toLowerCase() == "outer_sky" || id.toLowerCase() == "sky"))
            skyVariant = "Normal";
    }

    public static function getAssistantColor():Int
    {
        return switch(currentAssistant)
        {
            case "OuterQT": 0xFFDA8CFF;
            case "OuterSky":
                skyVariant == "SkyBlue" ? 0xFF1E90FF : 0xFF4B70D8;
            case "OuterNikku": 0xFF8A2BE2;
            case "OuterCarol": 0xFFDA70D6;
            case "MinusBright": 0xFF483D8B;
            default: 0xFF6A0DAD;
        };
    }

    public static function getAssistantDisplayName():String
    {
        return switch(currentAssistant)
        {
            case "OuterQT": "OUTER!QT | Charts";
            case "OuterSky": skyVariant == "SkyBlue" ? "OUTER!SKY (SkyBlue) | Events" : "OUTER!SKY | Events";
            case "OuterNikku": "OUTER!NIKKU | Lua/Haxe";
            case "OuterCarol": "OUTER!CAROL | Stages";
            case "MinusBright": "MinusBright | Always Online";
            default: "Unknown Assistant";
        };
    }

    public static function getSpecialistNameAt(time:Date):String
    {
        var localSeconds:Float = time.getTime() / 1000.0 + timeZoneOffset * 3600.0;
        var slot:Int = Std.int(Math.floor(localSeconds / SHIFT_SECONDS));
        var index:Int = slot % rotation.length;
        if (index < 0) index += rotation.length;
        return rotation[index];
    }

    public static function getDialogue(action:String):String
    {
        return switch(currentAssistant)
        {
            case "OuterQT":
                switch(action)
                {
                    case "welcome": "Hii! OUTER!QT is here! Let's chart something awesome together! :3";
                    case "success": "Yay! The chart is ready! Let's check the timing once in-game!";
                    default: "We can chart it together, note by note!";
                }
            case "OuterSky":
                if (skyVariant == "SkyBlue")
                {
                    switch(action)
                    {
                        case "welcome": "Hello. I'm SkyBlue. Let's review the event timeline carefully.";
                        case "success": "The event data has been prepared. Verify engine-specific behavior in-game.";
                        default: "Let's inspect the event and its target-engine equivalent.";
                    }
                }
                else
                {
                    switch(action)
                    {
                        case "welcome": "Hi! I'm OUTER!SKY! Want to build or convert some chart events?";
                        case "success": "Yay! The events are lined up!";
                        default: "Tell me what the event should do and we'll work it out!";
                    }
                }
            case "OuterNikku":
                switch(action)
                {
                    case "welcome": "OUTER!NIKKU here. Show me the script and the actual error.";
                    case "success": "Looks correct on inspection. No, that doesn't mean you can skip testing.";
                    default: "Send the relevant code. I can't debug a blank screen by telepathy.";
                }
            case "OuterCarol":
                switch(action)
                {
                    case "welcome": "OUTER!CAROL here. Tell me the stage and the visual goal.";
                    case "success": "Stage setup prepared. Check asset paths and camera placement.";
                    default: "Let's keep the stage structure clear and maintainable.";
                }
            case "MinusBright":
                switch(action)
                {
                    case "welcome": "*Long sigh.* MinusBright here. Yes, I'm online. What broke?";
                    case "overtime": "I don't have shifts. I have an eternal to-do list.";
                    default: "I can help with the engine-wide problem. Show me the error.";
                }
            default: "...";
        };
    }
}
