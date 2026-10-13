package options;

import backend.Paths;
import backend.AssistantManager;
import backend.outer.AssistantSchedule;
import backend.outer.OuterPerformance;
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
        "Schedule Timezone",
        "Ultimate Parser",
        "Refresh Schedule",
        "Scheduler Execution Mode",
        "Global Schedule Switch",
        "Schedule Target Bot",
        "Target Bot Enabled",
        "Target Start Hour",
        "Target Duration",
        "Apply Schedule Preset",
        "Target Active Days",
        "FPS Target",
        "Graphics Quality Profile",
        "Adaptive Quality Controller",
        "Target Start Minute"
    ];

    var curSelected:Int = 0;
    var descText:FlxText;
    var itemDisplay:FlxText;
    var bg:FlxSprite;
    var titleText:FlxText;

    var scheduleTargets:Array<String> = ["OuterQT", "OuterSky", "OuterNikku", "OuterCarol"];
    var scheduleTargetIndex:Int = 0;
    var presetOptions:Array<String> = ["daytime", "evening", "workday", "always", "disabled"];
    var presetIndex:Int = 0;
    var dayProfileIndex:Int = 0;

    override function create()
    {
        AssistantSchedule.ensureLoaded();

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF0D0221);
        bg.alpha = 0.94;
        add(bg);

        titleText = new FlxText(40, 35, FlxG.width - 80, "OUTER!ENGINE | Assistant Control Center", 26);
        titleText.setFormat("VCR OSD Mono", 26, 0xFFDA8CFF, CENTER, OUTLINE, FlxColor.BLACK);
        add(titleText);

        itemDisplay = new FlxText(40, FlxG.height * 0.34, FlxG.width - 80, "", 21);
        itemDisplay.setFormat("VCR OSD Mono", 21, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        add(itemDisplay);

        descText = new FlxText(55, FlxG.height * 0.49, FlxG.width - 110, "", 13);
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
        var target:String = scheduleTargets[scheduleTargetIndex];
        var entry:Dynamic = AssistantSchedule.getEntry(target);

        switch (curSelected)
        {
            case 0:
                descText.text = "Current: " + AssistantManager.getAssistantDisplayName() +
                    "\nMinusBright remains available at all times. Left/Right changes the selected assistant.";
            case 1:
                descText.text = "Sky variant: " + AssistantManager.skyVariant +
                    "\nNormal Sky is bubbly; SkyBlue uses a more mature tone.";
            case 2:
                descText.text = "Local Ollama: " + (OuterAI.enabled ? "ENABLED" : "DISABLED") +
                    "\nRequires a local Ollama server and an installed model. No model is bundled.";
            case 3:
                descText.text = "Schedule UTC offset: " + (AssistantSchedule.timezoneOffset >= 0 ? "+" : "") +
                    AssistantSchedule.timezoneOffset + " hours" +
                    "\nLeft/Right adjusts the fixed offset used by every assistant schedule.";
            case 4:
                descText.text = "Ultimate Parser: prototype available." +
                    "\nNormalizes chart notes/events; full mod portability needs engine-specific adapters.";
            case 5:
                descText.text = "Recalculate the active assistant from the saved schedule." +
                    "\nSchedule settings are persisted in the engine save data.";
            case 6:
                descText.text = "Execution mode: " + AssistantSchedule.executionMode.toUpperCase() +
                    "\nENGINE runs schedules inside the game. BACKGROUND uses the standalone worker when the game is closed. Run tools/start_outer_assistant_scheduler.bat. BOTH enables in-game scheduling and the worker.";
            case 7:
                descText.text = "Global schedule: " + (AssistantSchedule.globallyEnabled ? "ENABLED" : "DISABLED") +
                    "\nWhen disabled, scheduled specialists go offline and MinusBright remains available.";
            case 8:
                descText.text = "Selected bot: " + target +
                    "\nUse Left/Right to choose QT, Sky, Nikku or Carol before editing its schedule.";
            case 9:
                descText.text = target + " is " + (entry.enabled ? "ENABLED" : "DISABLED") +
                    "\nToggle whether this assistant can become active during its scheduled hours.";
            case 10:
                descText.text = target + " starts at " + formatTime(entry.startHour, entry.startMinute) +
                    "\nLeft/Right changes its start hour. Use schedule presets for common shifts.";
            case 11:
                descText.text = target + " duration: " + entry.durationHours + " hour(s)" +
                    "\nDuration supports overnight shifts and can be set from 1 to 24 hours.";
            case 12:
                descText.text = target + " preset: " + entry.preset +
                    "\nPresets: daytime (06:00/12h), evening (18:00/12h), workday (09:00/8h), always (24h), disabled.";
            case 13:
                descText.text = target + " active days: " + describeDays(cast entry.days) +
                    "\nLeft/Right cycles all days, weekdays, and weekends.";
            case 14:
                descText.text = "Frame cap: " + OuterPerformance.targetFPS + " FPS" +
                    "\nLeft/Right selects a cap from 30 to 360 FPS. The monitor tracks frame time, spikes and missed-frame estimates." +
                    "\nCurrent: " + Math.round(OuterPerformance.frameTimeMs * 100) / 100 + " ms, average " + Math.round(OuterPerformance.averageFrameTimeMs * 100) / 100 + " ms.";
            case 15:
                descText.text = "Graphics profile: " + OuterPerformance.qualityProfile.toUpperCase() +
                    "\nLOW reduces optional effects, BALANCED is the default, HIGH favors visuals, ADAPTIVE adjusts the quality tier based on frame pacing.";
            case 16:
                descText.text = "Adaptive quality controller: " + (OuterPerformance.adaptiveQuality ? "ENABLED" : "DISABLED") +
                    "\nWhen using the ADAPTIVE profile, sustained slow frame pacing lowers the quality tier; stable performance gradually restores it.";
            case 17:
                descText.text = target + " starts at " + formatTime(entry.startHour, entry.startMinute) +
                    "\nLeft/Right adjusts the start minute in 5-minute steps. Overnight shifts are supported.";
        }
    }

    function formatTime(hour:Int, minute:Int):String
    {
        return StringTools.lpad(Std.string(hour), "0", 2) + ":" + StringTools.lpad(Std.string(minute), "0", 2);
    }

    function describeDays(days:Array<Int>):String
    {
        if (days == null || days.length == 0) return "none";
        if (days.length == 7) return "every day";
        if (days.length == 5 && days.indexOf(1) >= 0 && days.indexOf(5) >= 0) return "weekdays";
        if (days.length == 2 && days.indexOf(0) >= 0 && days.indexOf(6) >= 0) return "weekends";
        return days.join(", ");
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
                var offset:Int = AssistantSchedule.timezoneOffset + direction;
                if (offset > 14) offset = -12;
                if (offset < -12) offset = 14;
                AssistantSchedule.setTimezoneOffset(offset);
                AssistantManager.timeZoneOffset = offset;
                AssistantManager.refreshSchedule();

            case 4:
                // Informational item.

            case 5:
                AssistantSchedule.save();
                AssistantManager.refreshSchedule();

            case 6:
                var modes:Array<String> = ["engine", "background", "both"];
                var modeIndex:Int = modes.indexOf(AssistantSchedule.executionMode);
                if (modeIndex < 0) modeIndex = 0;
                modeIndex = (modeIndex + direction + modes.length) % modes.length;
                AssistantSchedule.setExecutionMode(modes[modeIndex]);
                AssistantManager.refreshSchedule();

            case 7:
                AssistantSchedule.setGlobalEnabled(!AssistantSchedule.globallyEnabled);
                AssistantManager.refreshSchedule();

            case 8:
                scheduleTargetIndex = (scheduleTargetIndex + direction + scheduleTargets.length) % scheduleTargets.length;

            case 9:
                var entry:Dynamic = AssistantSchedule.getEntry(scheduleTargets[scheduleTargetIndex]);
                AssistantSchedule.setEnabled(scheduleTargets[scheduleTargetIndex], !entry.enabled);
                AssistantManager.refreshSchedule();

            case 10:
                var entry:Dynamic = AssistantSchedule.getEntry(scheduleTargets[scheduleTargetIndex]);
                AssistantSchedule.setStartTime(scheduleTargets[scheduleTargetIndex], (entry.startHour + direction + 24) % 24, entry.startMinute);
                AssistantManager.refreshSchedule();

            case 11:
                var entry:Dynamic = AssistantSchedule.getEntry(scheduleTargets[scheduleTargetIndex]);
                var duration:Int = entry.durationHours + direction;
                if (duration > 24) duration = 1;
                if (duration < 1) duration = 24;
                AssistantSchedule.setDuration(scheduleTargets[scheduleTargetIndex], duration);
                AssistantManager.refreshSchedule();

            case 12:
                var entry:Dynamic = AssistantSchedule.getEntry(scheduleTargets[scheduleTargetIndex]);
                var currentIndex:Int = presetOptions.indexOf(entry.preset);
                if (currentIndex < 0) currentIndex = 0;
                presetIndex = (currentIndex + direction + presetOptions.length) % presetOptions.length;
                AssistantSchedule.applyPreset(scheduleTargets[scheduleTargetIndex], presetOptions[presetIndex]);
                AssistantManager.refreshSchedule();

            case 13:
                dayProfileIndex = (dayProfileIndex + direction + 3) % 3;
                var days:Array<Int> = switch (dayProfileIndex)
                {
                    case 0: [0, 1, 2, 3, 4, 5, 6];
                    case 1: [1, 2, 3, 4, 5];
                    default: [0, 6];
                };
                AssistantSchedule.setDays(scheduleTargets[scheduleTargetIndex], days);
                AssistantManager.refreshSchedule();

            case 14:
                var fpsOptions:Array<Int> = [30, 45, 60, 75, 90, 120, 144, 165, 240, 300, 360];
                var fpsIndex:Int = fpsOptions.indexOf(OuterPerformance.targetFPS);
                if (fpsIndex < 0) fpsIndex = 2;
                fpsIndex = (fpsIndex + direction + fpsOptions.length) % fpsOptions.length;
                OuterPerformance.setTargetFPS(fpsOptions[fpsIndex]);

            case 15:
                var profiles:Array<String> = ["low", "balanced", "high", "adaptive"];
                var profileIndex:Int = profiles.indexOf(OuterPerformance.qualityProfile);
                if (profileIndex < 0) profileIndex = 1;
                profileIndex = (profileIndex + direction + profiles.length) % profiles.length;
                OuterPerformance.setQualityProfile(profiles[profileIndex]);

            case 16:
                OuterPerformance.setAdaptiveQuality(!OuterPerformance.adaptiveQuality);

            case 17:
                var entry:Dynamic = AssistantSchedule.getEntry(scheduleTargets[scheduleTargetIndex]);
                var minute:Int = (entry.startMinute + direction * 5 + 60) % 60;
                AssistantSchedule.setStartTime(scheduleTargets[scheduleTargetIndex], entry.startHour, minute);
                AssistantManager.refreshSchedule();
        }
    }

    function executeOptionAction():Void
    {
        switch (curSelected)
        {
            case 4:
                // Keep the informational parser item inert.
            case 5:
                AssistantSchedule.save();
                AssistantManager.refreshSchedule();
            case 8:
                scheduleTargetIndex = (scheduleTargetIndex + 1) % scheduleTargets.length;
            default:
                adjustSelectedOption(1);
        }
    }
}
