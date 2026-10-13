package options;

import backend.Paths;
import backend.AssistantManager;
import backend.outer.OuterAI;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.MusicBeatSubstate;

class OuterOptionsSubState extends MusicBeatSubstate
{
    var options:Array<String> = [
        "Active Assistant",
        "Sky Variant",
        "Local AI (Ollama)",
        "Shift Timezone Offset",
        "Ultimate Parser",
        "Reset Shift Schedule"
    ];

    var curSelected:Int = 0;
    var descText:FlxText;
    var itemDisplay:FlxText;
    var bg:FlxSprite;
    var titleText:FlxText;

    override function create()
    {
        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0D0221);
        bg.alpha = 0.92;
        add(bg);

        titleText = new FlxText(40, 35, FlxG.width - 80, "OUTER!ENGINE | Assistant Control Center", 26);
        titleText.setFormat("VCR OSD Mono", 26, 0xFFDA8CFF, CENTER, OUTLINE, FlxColor.BLACK);
        add(titleText);

        itemDisplay = new FlxText(40, FlxG.height * 0.36, FlxG.width - 80, "", 22);
        itemDisplay.setFormat("VCR OSD Mono", 22, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        add(itemDisplay);

        descText = new FlxText(40, FlxG.height - 110, FlxG.width - 80, "", 13);
        descText.setFormat("VCR OSD Mono", 13, 0xFFD9D1E8, CENTER, OUTLINE, FlxColor.BLACK);
        add(descText);

        updateSelection();
        super.create();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        AssistantManager.updateTimer(elapsed);

        if (controls.UI_UP_P)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelected = (curSelected - 1 + options.length) % options.length;
            updateSelection();
        }
        if (controls.UI_DOWN_P)
        {
            FlxG.sound.play(Paths.sound('scrollMenu'));
            curSelected = (curSelected + 1) % options.length;
            updateSelection();
        }
        if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
        {
            adjustSelectedOption(controls.UI_RIGHT_P ? 1 : -1);
            updateSelection();
        }
        if (controls.ACCEPT)
        {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            executeOptionAction();
            updateSelection();
        }
        if (controls.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            close();
        }
    }

    function updateSelection():Void
    {
        itemDisplay.text = "< " + options[curSelected] + " >";
        switch (curSelected)
        {
            case 0:
                descText.text = "Current: " + AssistantManager.getAssistantDisplayName() +
                    "\nMinusBright is always available. Left/Right changes the active assistant.";
            case 1:
                descText.text = "Sky variant: " + AssistantManager.skyVariant +
                    "\nNormal Sky is bubbly; SkyBlue uses a more mature tone.";
            case 2:
                descText.text = "Local Ollama: " + (OuterAI.enabled ? "ENABLED" : "DISABLED") +
                    "\nRequires a local Ollama server and an installed model. No bundled model is included.";
            case 3:
                descText.text = "UTC offset: " + (AssistantManager.timeZoneOffset >= 0 ? "+" : "") +
                    AssistantManager.timeZoneOffset + " hours" +
                    "\nLeft/Right changes the local timezone used for 12-hour specialist shifts.";
            case 4:
                descText.text = "Ultimate Parser: prototype available." +
                    "\nNormalizes chart notes/events; full mod portability needs engine-specific adapters.";
            case 5:
                descText.text = "Recalculate the current specialist from your configured timezone." +
                    "\nThe four specialists rotate in 12-hour blocks. MinusBright stays available 24/7.";
        }
    }

    function adjustSelectedOption(direction:Int):Void
    {
        switch (curSelected)
        {
            case 0:
                var assistants:Array<String> = ["OuterQT", "OuterSky", "OuterNikku", "OuterCarol", "MinusBright"];
                var index:Int = assistants.indexOf(AssistantManager.currentAssistant);
                if (index < 0) index = 0;
                index = (index + direction + assistants.length) % assistants.length;
                AssistantManager.selectAssistant(assistants[index]);

            case 1:
                AssistantManager.skyVariant = AssistantManager.skyVariant == "Normal" ? "SkyBlue" : "Normal";

            case 2:
                OuterAI.enabled = !OuterAI.enabled;

            case 3:
                AssistantManager.timeZoneOffset += direction;
                if (AssistantManager.timeZoneOffset > 14) AssistantManager.timeZoneOffset = -12;
                if (AssistantManager.timeZoneOffset < -12) AssistantManager.timeZoneOffset = 14;
                AssistantManager.refreshSchedule();

            case 4:
                // Informational item. The parser is exposed to code/tools rather than a toggle.

            case 5:
                AssistantManager.resetShift();
        }
    }

    function executeOptionAction():Void
    {
        switch (curSelected)
        {
            case 0, 1, 2, 3:
                adjustSelectedOption(1);
            case 5:
                AssistantManager.resetShift();
            case 4:
                // Keep ACCEPT inert for the informational parser item.
        }
    }
}
