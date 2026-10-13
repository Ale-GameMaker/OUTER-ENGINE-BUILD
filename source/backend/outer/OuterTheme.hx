package backend.outer;

import flixel.text.FlxText;

/** Shared OUTER!ENGINE cosmic palette. Keep state-specific colors here. */
class OuterTheme
{
    public static inline var SPACE:Int = 0xFF10091D;
    public static inline var SPACE_DARK:Int = 0xFF0D0221;
    public static inline var PURPLE:Int = 0xFF6A0DAD;
    public static inline var PURPLE_LIGHT:Int = 0xFFDA8CFF;
    public static inline var STAR_LILAC:Int = 0xFFBDA8FF;
    public static inline var STAR_PINK:Int = 0xFFFFDFFF;
    public static inline var TEXT:Int = 0xFFF8F2FF;
    public static inline var TEXT_MUTED:Int = 0xFFD9D1E8;
    public static inline var OUTLINE:Int = 0xFF000000;

    public static function applyHudText(text:FlxText):Void
    {
        if (text == null) return;
        text.color = TEXT;
        text.borderColor = PURPLE;
        text.borderSize = 1.5;
    }
}
