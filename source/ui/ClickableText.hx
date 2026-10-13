
package ui;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;

class ClickableText extends FlxText
{
    public var onClick:Void->Void;

    private var isHovered:Bool = false;
    private var clickLocked:Bool = false;

    public function new(
        x:Float,
        y:Float,
        width:Float,
        text:String,
        size:Int,
        onClick:Void->Void
    )
    {
        super(x, y, width, text, size);

        this.onClick = onClick;
        this.color = FlxColor.WHITE;
        this.isHovered = false;
        this.clickLocked = false;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!exists || !visible || !active || clickLocked)
            return;

        var hovering:Bool = FlxG.mouse.overlaps(this);

        if (hovering && !isHovered)
        {
            isHovered = true;
            color = 0xFFD7A0FF;
            scale.set(1.06, 1.06);
        }
        else if (!hovering && isHovered)
        {
            isHovered = false;
            color = FlxColor.WHITE;
            scale.set(1, 1);
        }

        if (hovering && FlxG.mouse.justPressed && onClick != null)
        {
            // Impede que o mesmo botão dispare o callback mais de uma vez
            // durante uma transição de estado.
            clickLocked = true;

            var callback = onClick;
            callback();
        }
    }
}