package states;

import ui.ClickableText;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;

import Sys;

class LauncherState extends FlxState
{
    // ============================================================
    // OUTER!ENGINE GALACTIC LAUNCHER
    // ============================================================

    private var currentScreen:String = "launcher";

    // Interface
    private var uiGroup:FlxGroup;

    private var titleText:FlxText;
    private var subtitleText:FlxText;
    private var introContinue:FlxText;
    private var character:FlxSprite;

    private var playButton:ClickableText;
    private var optionsButton:ClickableText;
    private var quitButton:ClickableText;
    private var musicOption:ClickableText;
    private var fullscreenOption:ClickableText;
    private var backButton:ClickableText;

    // Procedural galactic background
    private var galaxyGrid:FlxSprite;
    private var starGroup:FlxGroup;
    private var stars:Array<FlxSprite> = [];

    private var gridSpacing:Int = 42;
    private var gridSpeed:Float = 24;
    private var starSpeed:Float = 5;

    // Audio and preferences
    private var launcherMusicEnabled:Bool = true;
    private var launcherJingle:FlxSound;
    private var launcherFullscreen:Bool = false;

    // First-launch introduction
    private var introTime:Float = 0;
    private var canContinueIntro:Bool = false;

    override public function create():Void
    {
        super.create();

        FlxG.camera.bgColor = 0xFF10091D;

        // Generate the background before adding the interface.
        buildGalaxyBackground();

        uiGroup = new FlxGroup();
        add(uiGroup);

        loadPreferences();

        FlxG.fullscreen = launcherFullscreen;

        if (launcherMusicEnabled)
            playJingle();

        showLauncher();
    }

    // ============================================================
    // PREFERENCES
    // ============================================================

    private function loadPreferences():Void
    {
        if (FlxG.save == null || FlxG.save.data == null)
            return;

        if (FlxG.save.data.outerLauncherMusic != null)
            launcherMusicEnabled = FlxG.save.data.outerLauncherMusic;

        if (FlxG.save.data.outerLauncherFullscreen != null)
            launcherFullscreen = FlxG.save.data.outerLauncherFullscreen;
    }

    private function savePreferences():Void
    {
        if (FlxG.save != null && FlxG.save.data != null)
            FlxG.save.flush();
    }

    // ============================================================
    // PROCEDURAL GALAXY
    // No external background images are required.
    // ============================================================

    private function buildGalaxyBackground():Void
    {
        stars = [];

        // The grid graphic is taller than the screen so it can scroll
        // and wrap without exposing an empty strip at the top or bottom.
        galaxyGrid = new FlxSprite();

        var gridHeight:Int = FlxG.height + gridSpacing;

        galaxyGrid.makeGraphic(
            FlxG.width,
            gridHeight,
            FlxColor.TRANSPARENT,
            true
        );

        // Draw a diagonal diamond grid directly into the bitmap.
        // This is generated once, not redrawn every frame.
        var gridColor:Int = 0x459A72FF;

        for (y in 0...gridHeight)
        {
            for (x in 0...FlxG.width)
            {
                var diagonalA:Int = (x + y) % gridSpacing;
                var diagonalB:Int = Std.int(Math.abs(x - y)) % gridSpacing;

                if (diagonalA < 2 || diagonalB < 2)
                    galaxyGrid.pixels.setPixel32(x, y, gridColor);
            }
        }

        galaxyGrid.dirty = true;
        galaxyGrid.x = 0;
        galaxyGrid.y = -gridSpacing;
        galaxyGrid.alpha = 0.72;
        galaxyGrid.scrollFactor.set();

        add(galaxyGrid);

        // Procedural stars.
        starGroup = new FlxGroup();

        var starCount:Int = 85;

        for (i in 0...starCount)
        {
            var star:FlxSprite = new FlxSprite();

            var starSize:Int = (i % 9 == 0) ? 3 : 2;
            var starColor:Int = (i % 4 == 0)
                ? 0xFFFFDFFF
                : 0xFFBDA8FF;

            star.makeGraphic(starSize, starSize, starColor, true);

            star.x = (i * 97 + 31) % FlxG.width;
            star.y = (i * 67 + 19) % FlxG.height;

            star.alpha = 0.35 + ((i % 6) * 0.1);
            star.scrollFactor.set();

            stars.push(star);
            starGroup.add(star);
        }

        add(starGroup);

        // Decorative orbital points.
        for (i in 0...4)
        {
            var orbit:FlxSprite = new FlxSprite();

            orbit.makeGraphic(4, 4, 0xFFCE9DFF, true);
            orbit.x = FlxG.width * 0.15 + i * (FlxG.width * 0.22);
            orbit.y = 34 + (i % 2) * 25;
            orbit.alpha = 0.65;
            orbit.scrollFactor.set();

            add(orbit);
        }
    }

    private function updateGalaxy(elapsed:Float):Void
    {
        // Move the grid diagonally downward.
        if (galaxyGrid != null)
        {
            galaxyGrid.y += gridSpeed * elapsed;

            // The pattern repeats every gridSpacing pixels vertically,
            // so wrapping by one spacing unit keeps the animation smooth.
            if (galaxyGrid.y >= 0)
                galaxyGrid.y -= gridSpacing;
        }

        // Give the stars a subtle downward drift.
        if (stars != null)
        {
            for (i in 0...stars.length)
            {
                var star:FlxSprite = stars[i];

                if (star == null)
                    continue;

                star.y += starSpeed * elapsed * (1 + (i % 3) * 0.25);

                if (star.y > FlxG.height)
                {
                    star.y = -4;
                    star.x = (i * 97 + Std.int(introTime * 13) + 31) % FlxG.width;
                }

                // Gentle variation in brightness.
                star.alpha = 0.35 + ((i % 6) * 0.1);
            }
        }
    }

    // ============================================================
    // AUDIO
    // ============================================================

    private function playJingle():Void
    {
        try
        {
            if (launcherJingle != null)
            {
                launcherJingle.stop();
                launcherJingle = null;
            }

            launcherJingle = FlxG.sound.play(
                Paths.sound("outerLauncherJingle")
            );
        }
        catch (e:Dynamic)
        {
            launcherJingle = null;
            trace("OUTER!ENGINE: optional launcher jingle not found.");
        }
    }

    // ============================================================
    // MAIN LAUNCHER
    // ============================================================

    private function showLauncher():Void
    {
        currentScreen = "launcher";
        clearUI();

        FlxG.camera.bgColor = 0xFF10091D;

        var eyebrow:FlxText = new FlxText(
            0,
            48,
            FlxG.width,
            "MINUSBRIGHT SYSTEMS  //  GALACTIC INTERFACE",
            11
        );

        eyebrow.setFormat(
            null,
            11,
            0xFFBDA4E8,
            CENTER
        );

        uiGroup.add(eyebrow);

        titleText = new FlxText(
            0,
            FlxG.height * 0.20,
            FlxG.width,
            "OUTER!ENGINE",
            42
        );

        titleText.setFormat(
            null,
            42,
            0xFFE6C5FF,
            CENTER,
            OUTLINE,
            0xFF40235E
        );

        uiGroup.add(titleText);

        subtitleText = new FlxText(
            0,
            titleText.y + 56,
            FlxG.width,
            "YOUR NEXT UNIVERSE STARTS HERE",
            14
        );

        subtitleText.setFormat(
            null,
            14,
            0xFFBBA6D9,
            CENTER
        );

        uiGroup.add(subtitleText);

        var separator:FlxSprite = new FlxSprite(
            FlxG.width * 0.30,
            subtitleText.y + 35
        );

        separator.makeGraphic(
            Std.int(FlxG.width * 0.40),
            2,
            0xFF8053B5,
            true
        );

        separator.alpha = 0.8;
        uiGroup.add(separator);

        var buttonY:Float = FlxG.height * 0.48;
        var buttonGap:Float = 52;

        playButton = createButton(
            "[ PLAY ]",
            buttonY,
            startEngine
        );

        optionsButton = createButton(
            "[ OPTIONS ]",
            buttonY + buttonGap,
            showOptions
        );

        quitButton = createButton(
            "[ QUIT ]",
            buttonY + buttonGap * 2,
            quitGame
        );

        uiGroup.add(playButton);
        uiGroup.add(optionsButton);
        uiGroup.add(quitButton);

        var footer:FlxText = new FlxText(
            0,
            FlxG.height - 36,
            FlxG.width,
            "MINUSBRIGHT • OUTER!ENGINE",
            11
        );

        footer.setFormat(
            null,
            11,
            0xFF8876A8,
            CENTER
        );

        uiGroup.add(footer);
    }

    // ============================================================
    // OPTIONS
    // ============================================================

    private function showOptions():Void
    {
        currentScreen = "options";
        clearUI();

        FlxG.camera.bgColor = 0xFF10091D;

        var heading:FlxText = new FlxText(
            0,
            FlxG.height * 0.20,
            FlxG.width,
            "GALACTIC SETTINGS",
            32
        );

        heading.setFormat(
            null,
            32,
            0xFFE6C5FF,
            CENTER
        );

        uiGroup.add(heading);

        var description:FlxText = new FlxText(
            0,
            heading.y + 48,
            FlxG.width,
            "Configure your launch sequence.",
            14
        );

        description.setFormat(
            null,
            14,
            0xFFBBA6D9,
            CENTER
        );

        uiGroup.add(description);

        musicOption = createButton(
            "JINGLE: " + (launcherMusicEnabled ? "ON" : "OFF"),
            FlxG.height * 0.43,
            toggleMusic
        );

        fullscreenOption = createButton(
            "FULLSCREEN: " + (launcherFullscreen ? "ON" : "OFF"),
            FlxG.height * 0.43 + 58,
            toggleFullscreen
        );

        backButton = createButton(
            "[ BACK ]",
            FlxG.height * 0.43 + 145,
            showLauncher
        );

        uiGroup.add(musicOption);
        uiGroup.add(fullscreenOption);
        uiGroup.add(backButton);
    }

    private function toggleMusic():Void
    {
        launcherMusicEnabled = !launcherMusicEnabled;

        if (FlxG.save != null && FlxG.save.data != null)
        {
            FlxG.save.data.outerLauncherMusic = launcherMusicEnabled;
            savePreferences();
        }

        if (launcherMusicEnabled)
        {
            playJingle();
        }
        else if (launcherJingle != null)
        {
            launcherJingle.stop();
            launcherJingle = null;
        }

        showOptions();
    }

    private function toggleFullscreen():Void
    {
        launcherFullscreen = !launcherFullscreen;

        if (FlxG.save != null && FlxG.save.data != null)
        {
            FlxG.save.data.outerLauncherFullscreen = launcherFullscreen;
            savePreferences();
        }

        FlxG.fullscreen = launcherFullscreen;

        showOptions();
    }

    // ============================================================
    // ENGINE STARTUP AND MINUSBRIGHT INTRO
    // ============================================================

    private function startEngine():Void
    {
        if (FlxG.save != null &&
            FlxG.save.data != null &&
            FlxG.save.data.outerEngineOpened == true)
        {
            FlxG.switchState(new TitleState());
            return;
        }

        if (FlxG.save != null && FlxG.save.data != null)
        {
            FlxG.save.data.outerEngineOpened = true;
            savePreferences();
        }

        showMinusBrightIntro();
    }

    private function showMinusBrightIntro():Void
    {
        currentScreen = "intro";
        clearUI();

        FlxG.camera.bgColor = 0xFF10091D;

        introTime = 0;
        canContinueIntro = false;

        // Artwork is optional. The intro remains usable without it.
        try
        {
            character = new FlxSprite();

            character.loadGraphic(Paths.image("outer/minusBright"));
            character.setGraphicSize(Std.int(FlxG.width * 0.30));
            character.updateHitbox();
            character.screenCenter(X);
            character.y = FlxG.height * 0.08;
            character.alpha = 0;
            character.antialiasing = true;

            uiGroup.add(character);

            FlxTween.tween(
                character,
                {alpha: 1},
                1.2,
                {ease: FlxEase.quadOut}
            );
        }
        catch (e:Dynamic)
        {
            character = null;
            trace("OUTER!ENGINE: MinusBright artwork not found; continuing without it.");
        }

        titleText = new FlxText(
            0,
            FlxG.height * 0.60,
            FlxG.width,
            "HEY! I'M MINUSBRIGHT!",
            30
        );

        titleText.setFormat(
            null,
            30,
            0xFFE6C5FF,
            CENTER
        );

        titleText.alpha = 0;
        uiGroup.add(titleText);

        FlxTween.tween(
            titleText,
            {alpha: 1},
            1.2,
            {startDelay: 0.6, ease: FlxEase.quadOut}
        );

        subtitleText = new FlxText(
            FlxG.width * 0.08,
            titleText.y + 52,
            FlxG.width * 0.84,
            "Your new companion inside OUTER!ENGINE.\nLet's make something amazing together!",
            17
        );

        subtitleText.setFormat(
            null,
            17,
            FlxColor.WHITE,
            CENTER
        );

        subtitleText.alpha = 0;
        uiGroup.add(subtitleText);

        FlxTween.tween(
            subtitleText,
            {alpha: 1},
            1.2,
            {startDelay: 1.4, ease: FlxEase.quadOut}
        );

        introContinue = new FlxText(
            0,
            FlxG.height - 65,
            FlxG.width,
            "PRESS ENTER, SPACE OR CLICK TO CONTINUE",
            13
        );

        introContinue.setFormat(
            null,
            13,
            0xFFBDA4E8,
            CENTER
        );

        introContinue.alpha = 0;
        uiGroup.add(introContinue);

        FlxTween.tween(
            introContinue,
            {alpha: 1},
            0.8,
            {startDelay: 2.5, ease: FlxEase.quadOut}
        );
    }

    // ============================================================
    // BUTTON FACTORY
    // ============================================================

    private function createButton(
        label:String,
        y:Float,
        onClick:Void->Void
    ):ClickableText
    {
        var button:ClickableText = new ClickableText(
            0,
            y,
            FlxG.width,
            label,
            25,
            onClick
        );

        button.setFormat(
            null,
            25,
            FlxColor.WHITE,
            CENTER
        );

        button.scrollFactor.set();
        button.antialiasing = true;

        return button;
    }

    // ============================================================
    // CLEANUP
    // ============================================================

    private function clearUI():Void
    {
        // Cancel only tweens attached to existing objects.
        if (character != null)
            FlxTween.cancelTweensOf(character);

        if (titleText != null)
            FlxTween.cancelTweensOf(titleText);

        if (subtitleText != null)
            FlxTween.cancelTweensOf(subtitleText);

        if (introContinue != null)
            FlxTween.cancelTweensOf(introContinue);

        if (uiGroup != null)
            uiGroup.clear();

        character = null;
        titleText = null;
        subtitleText = null;
        introContinue = null;

        playButton = null;
        optionsButton = null;
        quitButton = null;
        musicOption = null;
        fullscreenOption = null;
        backButton = null;
    }

    // ============================================================
    // QUIT
    // ============================================================

    private function quitGame():Void
    {
        if (launcherJingle != null)
        {
            launcherJingle.stop();
            launcherJingle = null;
        }

        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();

        Sys.exit(0);
    }

    // ============================================================
    // UPDATE
    // ============================================================

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        updateGalaxy(elapsed);

        if (currentScreen == "intro")
        {
            introTime += elapsed;

            if (introTime >= 3)
                canContinueIntro = true;

            if (canContinueIntro &&
                (
                    FlxG.keys.justPressed.ENTER ||
                    FlxG.keys.justPressed.SPACE ||
                    FlxG.mouse.justPressed
                ))
            {
                FlxG.switchState(new TitleState());
            }
        }
    }
}
