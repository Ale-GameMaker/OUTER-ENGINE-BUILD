package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import backend.outer.OuterPerformance;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import lime.app.Application;
import openfl.geom.Rectangle;

import states.StoryMenuState;
import states.FreeplayState;
import states.CreditsState;
import states.AchievementsMenuState;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
    public static var psychEngineVersion:String = '0.2.8';
    public static var curSelected:Int = 0;

    private var menuItems:FlxTypedGroup<FlxSprite>;
    private var camFollow:FlxObject;

    private var optionShit:Array<String> = [
        'story mode',
        'freeplay',
        'credits'
    ];

    private var selectedSomethin:Bool = false;

    // Fundo galáctico.
    private var galaxyBackground:FlxSprite;

    // Checkerboard branco translúcido, em movimento diagonal.
    private var checkerTiles:Array<FlxSprite> = [];
    private var checkerTileWidth:Int = 0;
    private var checkerTileHeight:Int = 0;

    private var checkerSpeedX:Float = 26;
    private var checkerSpeedY:Float = 15;

    // Estrelas.
    private var starGroup:FlxTypedGroup<FlxSprite>;
    private var stars:Array<FlxSprite> = [];

    // Botões redondos do lado direito.
    private var rightButtons:FlxTypedGroup<FlxSprite>;
    private var rightButtonLabels:FlxTypedGroup<FlxText>;

    private var achievementsButton:FlxSprite;
    private var optionsButton:FlxSprite;

    private var camLerp:Float = 0.08;

    override public function create():Void
    {
        super.create();

        persistentUpdate = true;
        persistentDraw = true;

        FlxG.camera.bgColor = 0xFF10091D;
        FlxG.camera.zoom = 1;

        createGalaxyBackground();
        createCheckerboard();
        createStars();

        if (FlxG.sound.music == null || !FlxG.sound.music.playing)
        {
            try
            {
                FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
            }
            catch (e:Dynamic)
            {
                trace('OUTER!ENGINE: Could not load menu music.');
            }
        }

        if (FlxG.sound.music != null)
            FlxG.sound.music.fadeIn(1, 0, 0.7);

        camFollow = new FlxObject(
            FlxG.width * 0.25,
            FlxG.height * 0.5,
            1,
            1
        );
        camFollow.scrollFactor.set();
        add(camFollow);

        menuItems = new FlxTypedGroup<FlxSprite>();
        add(menuItems);

        createMainButtons();
        createRightButtons();
        createVersionText();

        FlxG.camera.follow(camFollow, null, camLerp);

        changeItem(0);
    }

    // ============================================================
    // FUNDO GALÁCTICO
    // ============================================================

    private function createGalaxyBackground():Void
    {
        galaxyBackground = new FlxSprite();
        galaxyBackground.makeGraphic(320, 180, 0xFF10091D, true);

        var bitmap = galaxyBackground.pixels;

        for (y in 0...180)
        {
            for (x in 0...320)
            {
                var wave1:Float = Math.sin((x + y * 0.7) * 0.035);
                var wave2:Float = Math.cos((x * 0.5 - y) * 0.045);
                var glow:Float = (wave1 + wave2 + 2) / 4;

                var red:Int = Std.int(16 + glow * 28);
                var green:Int = Std.int(9 + glow * 9);
                var blue:Int = Std.int(29 + glow * 49);

                bitmap.setPixel32(
                    x,
                    y,
                    FlxColor.fromRGB(red, green, blue, 255)
                );
            }
        }

        galaxyBackground.dirty = true;
        galaxyBackground.setGraphicSize(FlxG.width, FlxG.height);
        galaxyBackground.updateHitbox();
        galaxyBackground.scrollFactor.set(0, 0);
        galaxyBackground.antialiasing = true;

        add(galaxyBackground);
    }

    // ============================================================
    // CHECKERBOARD DIAGONAL
    // ============================================================

    private function createCheckerboard():Void
    {
        var cellSize:Int = 32;

        // As dimensões são múltiplos do tamanho dos quadrados.
        // Isso permite repetir as peças sem emendas.
        checkerTileWidth = Std.int(Math.ceil(FlxG.width / cellSize)) * cellSize;
        checkerTileHeight = Std.int(Math.ceil(FlxG.height / cellSize)) * cellSize;

        // Uma peça extra de margem evita espaços vazios durante o movimento.
        checkerTileWidth += cellSize * 2;
        checkerTileHeight += cellSize * 2;

        var checkerGraphic:FlxSprite = new FlxSprite();
        checkerGraphic.makeGraphic(
            checkerTileWidth,
            checkerTileHeight,
            FlxColor.TRANSPARENT,
            true
        );

        for (cellY in 0...Std.int(checkerTileHeight / cellSize))
        {
            for (cellX in 0...Std.int(checkerTileWidth / cellSize))
            {
                if ((cellX + cellY) % 2 == 0)
                {
                    checkerGraphic.pixels.fillRect(
                        new Rectangle(cellX * cellSize, cellY * cellSize, cellSize, cellSize),
                        0x45FFFFFF
                    );
                }
            }
        }

        checkerGraphic.dirty = true;

        // Quatro peças cobrem a tela durante o movimento.
        for (row in 0...2)
        {
            for (column in 0...2)
            {
                var tile:FlxSprite = new FlxSprite(
                    column * checkerTileWidth,
                    row * checkerTileHeight
                );

                tile.loadGraphic(checkerGraphic.graphic);
                tile.alpha = 0.55;
                tile.scrollFactor.set(0, 0);
                tile.antialiasing = false;

                checkerTiles.push(tile);
                add(tile);
            }
        }
    }

    private function updateCheckerboard(elapsed:Float):Void
    {
        for (tile in checkerTiles)
        {
            tile.x -= checkerSpeedX * elapsed;
            tile.y -= checkerSpeedY * elapsed;

            if (tile.x <= -checkerTileWidth)
                tile.x += checkerTileWidth * 2;

            if (tile.x >= checkerTileWidth)
                tile.x -= checkerTileWidth * 2;

            if (tile.y <= -checkerTileHeight)
                tile.y += checkerTileHeight * 2;

            if (tile.y >= checkerTileHeight)
                tile.y -= checkerTileHeight * 2;
        }
    }

    // ============================================================
    // ESTRELAS
    // ============================================================

    private function createStars():Void
    {
        starGroup = new FlxTypedGroup<FlxSprite>();
        stars = [];

        for (i in 0...85)
        {
            var star:FlxSprite = new FlxSprite();

            var size:Int = (i % 9 == 0) ? 3 : 2;
            var color:Int = (i % 4 == 0)
                ? 0xFFFFDFFF
                : 0xFFBDA8FF;

            star.makeGraphic(size, size, color);
            star.x = (i * 97 + 31) % FlxG.width;
            star.y = (i * 67 + 19) % FlxG.height;
            star.alpha = 0.35 + ((i % 6) * 0.1);
            star.scrollFactor.set(0, 0);

            stars.push(star);
            starGroup.add(star);
        }

        add(starGroup);
    }

    private function updateGalaxy(elapsed:Float):Void
    {
        updateCheckerboard(elapsed);

        var activeStarCount:Int = Std.int(stars.length * OuterPerformance.getParticleMultiplier());
        if (activeStarCount < 12) activeStarCount = 12;

        for (i in 0...stars.length)
        {
            var star:FlxSprite = stars[i];

            if (star == null)
                continue;

            star.visible = i < activeStarCount;
            if (!star.visible) continue;

            star.y += (5 + (i % 3) * 2) * elapsed;

            if (star.y > FlxG.height)
            {
                star.y = -4;
                star.x = (i * 97 + Std.int(star.x + 31)) % FlxG.width;
            }
        }
    }

    // ============================================================
    // BOTÕES PRINCIPAIS
    // ============================================================

    private function createMainButtons():Void
    {
        var atlas:FlxAtlasFrames = null;

        try
        {
            atlas = Paths.getSparrowAtlas('mainmenu/menu');
        }
        catch (e:Dynamic)
        {
            trace('OUTER!ENGINE: Main menu atlas could not be loaded.');
        }

        var startX:Float = 45;
        var startY:Float = FlxG.height * 0.23;
        var gapY:Float = 150;

        for (i in 0...optionShit.length)
        {
            var item:FlxSprite = new FlxSprite(
                -650,
                startY + i * gapY
            );

            item.ID = i;
            item.antialiasing = true;
            item.scrollFactor.set();

            var prefix:String = optionShit[i];

            if (atlas != null)
            {
                item.frames = atlas;

                item.animation.addByPrefix('idle', prefix, 24);
                item.animation.addByPrefix(
                    'selected',
                    prefix + ' selected',
                    24
                );

                if (item.animation.exists('idle'))
                {
                    if (!item.animation.exists('selected'))
                    {
                        item.animation.addByPrefix(
                            'selected',
                            prefix,
                            24
                        );
                    }

                    item.animation.play('idle');
                    item.scale.set(0.72, 0.72);
                    item.updateHitbox();
                }
                else
                {
                    createFallbackMenuLabel(item, prefix);
                }
            }
            else
            {
                createFallbackMenuLabel(item, prefix);
            }

            menuItems.add(item);

            FlxTween.tween(
                item,
                {x: startX},
                0.85 + i * 0.12,
                {ease: FlxEase.expoOut}
            );
        }
    }

    private function createFallbackMenuLabel(
        item:FlxSprite,
        label:String
    ):Void
    {
        var text:FlxText = new FlxText(
            item.x,
            item.y,
            440,
            label.toUpperCase().replace('_', ' '),
            32
        );

        text.setFormat(
            'VCR OSD Mono',
            32,
            FlxColor.WHITE,
            LEFT
        );

        text.ID = item.ID;
        text.antialiasing = true;

        item.loadGraphic(text.graphic);
        item.setGraphicSize(Std.int(text.width), Std.int(text.height));
        item.updateHitbox();

        // Guarda o texto da opção como fallback visual.
        item.visible = false;

        var fallback:FlxSprite = new FlxSprite(text.x, text.y);
        fallback.makeGraphic(
            Std.int(text.width),
            Std.int(text.height),
            FlxColor.TRANSPARENT,
            true
        );
        fallback.visible = false;
    }

    // ============================================================
    // BOTÕES REDONDOS: ACHIEVEMENTS E OPTIONS
    // ============================================================

    private function createRightButtons():Void
    {
        rightButtons = new FlxTypedGroup<FlxSprite>();
        rightButtonLabels = new FlxTypedGroup<FlxText>();

        add(rightButtons);
        add(rightButtonLabels);

        var buttonSize:Int = 82;
        var gap:Float = 26;
        var totalWidth:Float = buttonSize * 2 + gap;

        var startX:Float = FlxG.width - totalWidth - 48;
        var y:Float = FlxG.height * 0.5 - buttonSize * 0.5;

        achievementsButton = createRoundButton(
            startX,
            y,
            buttonSize,
            'A',
            'ACHIEVEMENTS',
            0
        );

        optionsButton = createRoundButton(
            startX + buttonSize + gap,
            y,
            buttonSize,
            'O',
            'OPTIONS',
            1
        );
    }

    private function createRoundButton(
        x:Float,
        y:Float,
        size:Int,
        symbol:String,
        tooltip:String,
        buttonID:Int
    ):FlxSprite
    {
        var button:FlxSprite = new FlxSprite(x, y);
        button.makeGraphic(size, size, FlxColor.TRANSPARENT, true);

        var center:Float = size / 2;
        var radius:Float = center - 2;

        for (py in 0...size)
        {
            for (px in 0...size)
            {
                var dx:Float = px - center;
                var dy:Float = py - center;
                var distance:Float = Math.sqrt(dx * dx + dy * dy);

                if (distance <= radius - 3)
                {
                    button.pixels.setPixel32(px, py, 0xFF392653);
                }
                else if (distance <= radius)
                {
                    button.pixels.setPixel32(px, py, 0xFFBDA4E8);
                }
            }
        }

        button.dirty = true;
        button.ID = buttonID;
        button.antialiasing = true;
        button.scrollFactor.set();

        rightButtons.add(button);

        var symbolText:FlxText = new FlxText(
            x,
            y + size * 0.15,
            size,
            symbol,
            34
        );

        symbolText.setFormat(
            'VCR OSD Mono',
            34,
            FlxColor.WHITE,
            CENTER
        );

        symbolText.ID = buttonID;
        symbolText.scrollFactor.set();
        symbolText.antialiasing = true;

        rightButtonLabels.add(symbolText);

        return button;
    }

    // ============================================================
    // VERSÃO
    // ============================================================

    private function createVersionText():Void
    {
        var version:String = 'OUTER!ENGINE';

        try
        {
            version = 'OUTER!ENGINE  |  Psych Engine ' +
                Application.current.meta.get('version');
        }
        catch (e:Dynamic)
        {
            // Mantém o texto padrão caso os metadados não estejam disponíveis.
        }

        var versionText:FlxText = new FlxText(
            12,
            FlxG.height - 28,
            0,
            version,
            12
        );

        versionText.setFormat(
            'VCR OSD Mono',
            12,
            FlxColor.WHITE,
            LEFT
        );

        versionText.scrollFactor.set(0, 0);
        add(versionText);
    }

    // ============================================================
    // SELEÇÃO DO MENU
    // ============================================================

    private function changeItem(change:Int = 0):Void
    {
        if (optionShit.length == 0)
            return;

        curSelected += change;

        if (curSelected >= optionShit.length)
            curSelected = 0;

        if (curSelected < 0)
            curSelected = optionShit.length - 1;

        menuItems.forEach(function(item:FlxSprite)
        {
            if (item.ID == curSelected)
            {
                if (item.animation.exists('selected'))
                    item.animation.play('selected');

                item.scale.set(0.82, 0.82);
            }
            else
            {
                if (item.animation.exists('idle'))
                    item.animation.play('idle');

                item.scale.set(0.72, 0.72);
            }

            item.updateHitbox();
        });

        FlxG.sound.play(Paths.sound('scrollMenu'));
    }

    private function acceptSelection():Void
    {
        if (selectedSomethin)
            return;

        selectedSomethin = true;

        FlxG.sound.play(Paths.sound('confirmMenu'));

        switch (optionShit[curSelected])
        {
            case 'story mode':
                FlxG.switchState(new StoryMenuState());

            case 'freeplay':
                FlxG.switchState(new FreeplayState());

            case 'credits':
                FlxG.switchState(new CreditsState());
        }
    }

    private function openAchievements():Void
    {
        if (selectedSomethin)
            return;

        selectedSomethin = true;
        FlxG.sound.play(Paths.sound('confirmMenu'));

        FlxG.switchState(new AchievementsMenuState());
    }

    private function openOptions():Void
    {
        if (selectedSomethin)
            return;

        selectedSomethin = true;
        FlxG.sound.play(Paths.sound('confirmMenu'));

        FlxG.switchState(new OptionsState());
    }

    // ============================================================
    // CLIQUES DO MOUSE
    // ============================================================

    private function handleMouse():Void
    {
        if (selectedSomethin)
            return;

        if (!FlxG.mouse.justPressed)
            return;

        var clickedMenu:Bool = false;

        menuItems.forEach(function(item:FlxSprite)
        {
            if (item.visible && FlxG.mouse.overlaps(item))
            {
                curSelected = item.ID;
                clickedMenu = true;
            }
        });

        if (clickedMenu)
        {
            acceptSelection();
            return;
        }

        if (
            achievementsButton != null &&
            FlxG.mouse.overlaps(achievementsButton)
        )
        {
            openAchievements();
            return;
        }

        if (
            optionsButton != null &&
            FlxG.mouse.overlaps(optionsButton)
        )
        {
            openOptions();
        }
    }

    // ============================================================
    // UPDATE
    // ============================================================

    override public function update(elapsed:Float):Void
    {
        updateGalaxy(elapsed);

        if (!selectedSomethin)
        {
            if (
                FlxG.keys.justPressed.UP ||
                FlxG.keys.justPressed.W
            )
            {
                changeItem(-1);
            }

            if (
                FlxG.keys.justPressed.DOWN ||
                FlxG.keys.justPressed.S
            )
            {
                changeItem(1);
            }

            if (controls.ACCEPT)
                acceptSelection();

            if (controls.BACK)
                FlxG.switchState(new TitleState());
        }

        handleMouse();

        menuItems.forEach(function(item:FlxSprite)
        {
            var targetY:Float = FlxG.height * 0.23 + item.ID * 150;

            if (item.ID == curSelected)
                targetY -= 12;

            item.y = FlxMath.lerp(item.y, targetY, 0.18);
        });

        if (camFollow != null && menuItems.members.length > 0)
        {
            var selectedItem:FlxSprite = menuItems.members[curSelected];

            if (selectedItem != null)
            {
                camFollow.x = FlxMath.lerp(
                    camFollow.x,
                    selectedItem.x + selectedItem.width / 2,
                    camLerp
                );

                camFollow.y = FlxMath.lerp(
                    camFollow.y,
                    selectedItem.y + selectedItem.height / 2,
                    camLerp
                );
            }
        }

        super.update(elapsed);
    }
}