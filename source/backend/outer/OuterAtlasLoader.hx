package backend.outer;

import backend.Paths;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
#if flxanimate
import flxanimate.FlxAnimate;
#end

/**
 * Format-aware atlas API for OUTER!ENGINE.
 *
 * Static atlas formats produce FlxAtlasFrames. V-Slice is an animated bundle
 * (Animation.json + spritemap JSON + PNG) and is loaded through FlxAnimate.
 * Existing Paths methods remain the format-specific implementation layer.
 */
class OuterAtlasLoader
{
    /** Detect a supported atlas format from files available to the asset system. */
    public static function detect(key:String, ?parentFolder:String = null):OuterAtlasFormat
    {
        if (key == null || StringTools.trim(key).length == 0)
            return OuterAtlasFormat.UNKNOWN;

        // Animated V-Slice bundles must be checked before a static atlas.
        if (Paths.fileExists('images/$key/Animation.json', AssetType.TEXT, false, parentFolder)
            && hasVSliceSpritemap(key, parentFolder))
            return OuterAtlasFormat.VSLICE;

        if (Paths.fileExists('images/$key.xml', AssetType.TEXT, false, parentFolder))
            return OuterAtlasFormat.SPARROW;

        if (Paths.fileExists('images/$key.json', AssetType.TEXT, false, parentFolder))
            return OuterAtlasFormat.TEXTURE_PACKER_JSON;

        if (Paths.fileExists('images/$key.txt', AssetType.TEXT, false, parentFolder))
            return OuterAtlasFormat.SPRITESHEET_PACKER;

        return OuterAtlasFormat.UNKNOWN;
    }

    /** Load any supported static atlas. AUTO detects XML, JSON, or Packer TXT. */
    public static function loadFrames(key:String, ?format:OuterAtlasFormat = AUTO, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
    {
        var resolved:OuterAtlasFormat = (format == OuterAtlasFormat.AUTO) ? detect(key, parentFolder) : format;
        switch (resolved)
        {
            case SPARROW:
                return Paths.getSparrowAtlas(key, parentFolder, allowGPU);
            case TEXTURE_PACKER_JSON:
                return Paths.getAsepriteAtlas(key, parentFolder, allowGPU);
            case SPRITESHEET_PACKER:
                return Paths.getPackerAtlas(key, parentFolder, allowGPU);
            case VSLICE:
                throw 'Atlas "$key" is a V-Slice animation bundle. Use loadVSlice() with FlxAnimate.';
            case AUTO, UNKNOWN:
                throw 'Could not detect a supported atlas for "$key". Expected PNG plus XML, JSON, TXT, or a V-Slice bundle.';
        }
    }

    /** Load static atlas frames and attach them to a FlxSprite. */
    public static function loadInto(sprite:FlxSprite, key:String, ?format:OuterAtlasFormat = AUTO, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxSprite
    {
        if (sprite == null)
            throw 'OuterAtlasLoader.loadInto requires a valid FlxSprite.';
        sprite.frames = loadFrames(key, format, parentFolder, allowGPU);
        return sprite;
    }

    /**
     * Load a V-Slice animated bundle. key is the folder key, not the PNG name.
     * Example: freeplay/freeplay-boyfriend
     */
    #if flxanimate
    public static function loadVSlice(sprite:FlxAnimate, key:String):FlxAnimate
    {
        if (sprite == null)
            throw 'OuterAtlasLoader.loadVSlice requires a valid FlxAnimate.';
        if (detect(key) != OuterAtlasFormat.VSLICE)
            throw '"$key" does not appear to be a complete V-Slice atlas bundle.';
        Paths.loadAnimateAtlas(sprite, key);
        return sprite;
    }
    #end

    /** Attach already-loaded atlas frames to a sprite. */
    public static function applyFrames(sprite:FlxSprite, frames:FlxAtlasFrames):FlxSprite
    {
        if (sprite == null) throw 'OuterAtlasLoader.applyFrames requires a valid FlxSprite.';
        if (frames == null) throw 'OuterAtlasLoader.applyFrames received null frames.';
        sprite.frames = frames;
        return sprite;
    }

    private static function hasVSliceSpritemap(key:String, ?parentFolder:String = null):Bool
    {
        for (i in 0...10)
        {
            var suffix = i == 0 ? '' : '$i';
            if (Paths.fileExists('images/$key/spritemap$suffix.png', AssetType.IMAGE, false, parentFolder)
                && Paths.fileExists('images/$key/spritemap$suffix.json', AssetType.TEXT, false, parentFolder))
                return true;
        }
        return false;
    }
}
