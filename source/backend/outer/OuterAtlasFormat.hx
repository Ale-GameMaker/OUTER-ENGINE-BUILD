package backend.outer;

/** Supported atlas formats understood by the OUTER!ENGINE asset layer. */
enum abstract OuterAtlasFormat(String) from String to String
{
    /** Detect format from the files available in the asset system. */
    var AUTO = "auto";
    /** Sparrow atlas: PNG + XML. */
    var SPARROW = "sparrow";
    /** TexturePacker/Aseprite JSON atlas: PNG + JSON. */
    var TEXTURE_PACKER_JSON = "texturepacker-json";
    /** Flixel SpriteSheetPacker atlas: PNG + TXT. */
    var SPRITESHEET_PACKER = "spritesheet-packer";
    /** V-Slice animated atlas: Animation.json + spritemap JSON + PNG. */
    var VSLICE = "vslice";
    /** No matching supported atlas was found. */
    var UNKNOWN = "unknown";
}
