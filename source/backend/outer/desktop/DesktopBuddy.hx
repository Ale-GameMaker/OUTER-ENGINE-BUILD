package backend.outer.desktop;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

/**
 * OUTER!ENGINE animated assistant buddy.
 *
 * This is the in-game draggable buddy controller, intended for use in a
 * FlxState/FlxSubState. It does not create a separate native Windows window.
 * The native desktop-pet host can reuse this animation/state model later.
 *
 * Asset convention:
 *   assets/images/outer/buddies/<id>.png
 *   assets/images/outer/buddies/<id>.xml
 *
 * Sparrow XML animation prefixes supported:
 *   idle, walk, drag (optional)
 */
class DesktopBuddy extends FlxSprite
{
    public var assistantId(default, null):String;
    public var isDragging(default, null):Bool = false;
    public var wandering(default, set):Bool = true;
    public var walkSpeed:Float = 55;
    public var edgePadding:Float = 8;
    public var floorPadding:Float = 12;

    var dragOffsetX:Float = 0;
    var dragOffsetY:Float = 0;
    var wanderDirection:Int = 1;
    var pauseTimer:Float = 0;
    var hasWalkAnimation:Bool = false;
    var hasDragAnimation:Bool = false;
    var initialized:Bool = false;

    public function new(assistantId:String, ?x:Float = 40, ?y:Float = 40, ?scale:Float = 1)
    {
        super(x, y);
        this.assistantId = sanitizeId(assistantId);
        this.scale.set(scale, scale);
        antialiasing = true;
        scrollFactor.set();
        loadBuddyAtlas();
    }

    static function sanitizeId(id:String):String
    {
        if (id == null || StringTools.trim(id) == "") return "minusbright";
        return id.toLowerCase().replace("!", "").replace(" ", "").replace("-", "");
    }

    function loadBuddyAtlas():Void
    {
        var asset:String = "outer/buddies/" + assistantId;
        try
        {
            frames = Paths.getSparrowAtlas(asset);
            animation.addByPrefix("idle", "idle", 12, true);
            animation.addByPrefix("walk", "walk", 12, true);
            animation.addByPrefix("drag", "drag", 12, true);
            hasWalkAnimation = animation.getByName("walk") != null;
            hasDragAnimation = animation.getByName("drag") != null;

            // Common atlas variants can use these prefixes instead.
            if (animation.getByName("idle") == null)
                animation.addByPrefix("idle", "Idle", 12, true);
            if (animation.getByName("walk") == null)
            {
                animation.addByPrefix("walk", "Walk", 12, true);
                hasWalkAnimation = animation.getByName("walk") != null;
            }
            if (animation.getByName("drag") == null)
            {
                animation.addByPrefix("drag", "Drag", 12, true);
                hasDragAnimation = animation.getByName("drag") != null;
            }

            if (animation.getByName("idle") != null)
                animation.play("idle");
            updateHitbox();
            initialized = true;
        }
        catch (e:Dynamic)
        {
            // Keep the editor usable if the optional buddy art hasn't been installed.
            makeGraphic(48, 48, FlxColor.fromRGB(174, 92, 255));
            initialized = false;
        }
    }

    function set_wandering(value:Bool):Bool
    {
        wandering = value;
        return value;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (!exists || !visible || !active) return;

        var mouseX:Float = FlxG.mouse.x;
        var mouseY:Float = FlxG.mouse.y;

        if (FlxG.mouse.justPressed && overlapsPoint(FlxG.mouse.getWorldPosition()))
        {
            isDragging = true;
            dragOffsetX = x - mouseX;
            dragOffsetY = y - mouseY;
            pauseTimer = 0;
            playIfAvailable(hasDragAnimation ? "drag" : "idle");
        }

        if (isDragging)
        {
            if (FlxG.mouse.pressed)
            {
                x = FlxMath.bound(mouseX + dragOffsetX, 0, FlxG.width - width);
                y = FlxMath.bound(mouseY + dragOffsetY, 0, FlxG.height - height);
            }
            else
            {
                isDragging = false;
                playIfAvailable("idle");
            }
            return;
        }

        if (!wandering) return;

        pauseTimer -= elapsed;
        if (pauseTimer > 0)
        {
            playIfAvailable("idle");
            return;
        }

        if (x <= edgePadding) wanderDirection = 1;
        else if (x + width >= FlxG.width - edgePadding) wanderDirection = -1;

        x += wanderDirection * walkSpeed * elapsed;
        x = FlxMath.bound(x, edgePadding, Math.max(edgePadding, FlxG.width - width - edgePadding));
        flipX = wanderDirection < 0;

        if (hasWalkAnimation)
            playIfAvailable("walk");
        else
            playIfAvailable("idle");

        // Occasionally pause for a moment so the buddy feels less mechanical.
        if (FlxG.random.bool(0.35) && (x <= edgePadding || x + width >= FlxG.width - edgePadding))
            pauseTimer = FlxG.random.float(0.6, 1.8);

        // Keep it near the bottom of the editor without forcing it there while dragged.
        if (y < 0) y = 0;
        if (y + height > FlxG.height - floorPadding)
            y = FlxG.height - height - floorPadding;
    }

    function playIfAvailable(name:String):Void
    {
        if (animation.getByName(name) != null && animation.name != name)
            animation.play(name);
    }

    /** Toggle the little assistant's autonomous pacing. */
    public function setWandering(enabled:Bool):Void
    {
        wandering = enabled;
        if (!enabled && !isDragging) playIfAvailable("idle");
    }
}
