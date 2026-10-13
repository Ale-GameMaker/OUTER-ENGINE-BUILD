package backend.outer;

import backend.Paths;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
#if flxanimate
import flxanimate.FlxAnimate;
#end

/**
 * Unified atlas entry points for OUTER!ENGINE.
 *
 * Sparrow XML and TexturePacker JSON are exposed as FlxAtlasFrames.
 * V-Slice atlases are animation bundles (spritemap PNG + spritemap JSON +
 * Animation.json), so they must be loaded by FlxAnimate rather than reduced
 * to a static FlxAtlasFrames object.
 */
class OuterAtlasLoader
{
    /** Load a traditional Sparrow atlas (image + XML). */
    public static function loadSparrow(key:String, ?parentFolder:String = null):FlxAtlasFrames
    {
        return Paths.getSparrowAtlas(key, parentFolder);
    }

    /** Load a TexturePacker/Aseprite JSON atlas (image + JSON). */
    public static function loadJson(key:String, ?parentFolder:String = null):FlxAtlasFrames
    {
        return Paths.getAsepriteAtlas(key, parentFolder);
    }

    /**
     * Load a V-Slice animated atlas into a FlxAnimate instance.
     * atlasPath points to the directory-like asset key containing spritemap PNGs,
     * spritemap JSON files and Animation.json. Paths resolves the actual index.
     */
    #if flxanimate
    public static function loadVSlice(sprite:FlxAnimate, atlasPath:String):FlxAnimate
    {
        if (sprite == null)
            throw "OuterAtlasLoader.loadVSlice requires a valid FlxAnimate instance.";

        Paths.loadAnimateAtlas(sprite, atlasPath);
        return sprite;
    }
    #end

    /** Attach frames produced by loadSparrow/loadJson to a FlxSprite. */
    public static function applyFrames(sprite:FlxSprite, frames:FlxAtlasFrames):FlxSprite
    {
        if (sprite == null)
            throw "OuterAtlasLoader.applyFrames requires a valid FlxSprite instance.";
        if (frames == null)
            throw "OuterAtlasLoader.applyFrames received null atlas frames.";

        sprite.frames = frames;
        return sprite;
    }
}
