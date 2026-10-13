package objects.outer;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Reusable OUTER!ENGINE assistant speech bubble.
 * Text is revealed with a lightweight typewriter effect.
 */
class OuterDialogueBubble extends FlxSpriteGroup
{
    private var panel:FlxSprite;
    private var nameBar:FlxSprite;
    private var tail:FlxSprite;
    private var nameText:FlxText;
    private var bodyText:FlxText;

    private var fullText:String;
    private var revealedCharacters:Float = 0;
    private var charactersPerSecond:Float = 42;
    private var finishedWait:Float = 0;
    private var autoHideAfter:Float = 3.0;
    private var completed:Bool = false;

    public function new(x:Float, y:Float, width:Int, height:Int, speaker:String, message:String, accentColor:Int)
    {
        super(x, y);

        fullText = message == null ? "" : message;

        tail = new FlxSprite(28, height - 13);
        tail.makeGraphic(22, 22, accentColor);
        tail.angle = 45;
        tail.antialiasing = false;
        add(tail);

        panel = new FlxSprite(0, 0);
        panel.makeGraphic(width, height, 0xF20C0918);
        panel.scrollFactor.set();
        add(panel);

        nameBar = new FlxSprite(0, 0);
        nameBar.makeGraphic(width, 29, accentColor);
        nameBar.scrollFactor.set();
        add(nameBar);

        nameText = new FlxText(12, 5, width - 24, speaker == null ? "Assistant" : speaker, 16);
        nameText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT);
        nameText.scrollFactor.set();
        add(nameText);

        bodyText = new FlxText(14, 39, width - 28, "", 17);
        bodyText.setFormat("VCR OSD Mono", 17, FlxColor.WHITE, LEFT);
        bodyText.wordWrap = true;
        bodyText.scrollFactor.set();
        add(bodyText);

        scrollFactor.set();
        cameras = [FlxG.camera];
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (completed)
        {
            finishedWait += elapsed;
            if (finishedWait >= autoHideAfter)
                alpha = Math.max(0, alpha - elapsed * 2.5);
            if (alpha <= 0)
                visible = false;
            return;
        }

        revealedCharacters += charactersPerSecond * elapsed;
        var count:Int = Std.int(revealedCharacters);
        if (count >= fullText.length)
        {
            count = fullText.length;
            completed = true;
            finishedWait = 0;
        }

        bodyText.text = fullText.substr(0, count);
    }

    /** Completes the typewriter effect immediately, useful for dialogue input. */
    public function revealAll():Void
    {
        revealedCharacters = fullText.length;
        bodyText.text = fullText;
        completed = true;
        finishedWait = 0;
    }

    public function setMessage(speaker:String, message:String, accentColor:Int):Void
    {
        fullText = message == null ? "" : message;
        revealedCharacters = 0;
        finishedWait = 0;
        completed = false;
        alpha = 1;
        visible = true;
        nameText.text = speaker == null ? "Assistant" : speaker;
        nameBar.makeGraphic(Std.int(panel.width), 29, accentColor);
        tail.makeGraphic(22, 22, accentColor);
        bodyText.text = "";
    }
}
