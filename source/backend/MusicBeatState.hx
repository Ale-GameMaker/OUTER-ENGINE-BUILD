package backend;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.transition.FlxTransitionableState;
import backend.PsychCamera;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	public var controls(get, never):Controls;
	private function get_controls()
	{
		return Controls.instance;
	}

	var _psychCameraInitialized:Bool = false;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static function getVariables()
	{
		return getState().variables;
	}

	public static var timePassedOnState:Float = 0;

	public var stages:Array<BaseStage> = [];

	// OUTER!ENGINE global assistant HUD.
	private var globalAssistantCam:FlxCamera;
	private var globalBox:FlxSprite;
	private var globalTitle:FlxText;
	private var globalDialogue:FlxText;
	private var lastAssistantName:String = "";
	private var lastSkyVariant:String = "";

	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED
		Mods.updatedOnState = false;
		#end

		if (!_psychCameraInitialized)
			initPsychCamera();

		super.create();

		if (!skip)
			openSubState(new CustomFadeTransition(0.5, true));

		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;

		setupGlobalAssistantHUD();
	}

	public function initPsychCamera():PsychCamera
	{
		var camera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	private function setupGlobalAssistantHUD():Void
	{
		globalAssistantCam = new FlxCamera();
		globalAssistantCam.bgColor.alpha = 0;
		FlxG.cameras.add(globalAssistantCam, false);

		globalBox = new FlxSprite(FlxG.width - 330, 15).makeGraphic(315, 65, 0xCC1A0B2E);
		globalBox.cameras = [globalAssistantCam];
		globalBox.scrollFactor.set();
		add(globalBox);

		globalTitle = new FlxText(FlxG.width - 320, 20, 295, "", 11);
		globalTitle.cameras = [globalAssistantCam];
		globalTitle.scrollFactor.set();
		globalTitle.setFormat("VCR OSD Mono", 11, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		add(globalTitle);

		globalDialogue = new FlxText(FlxG.width - 320, 38, 295, "", 10);
		globalDialogue.cameras = [globalAssistantCam];
		globalDialogue.scrollFactor.set();
		globalDialogue.setFormat("VCR OSD Mono", 9, FlxColor.WHITE, LEFT);
		add(globalDialogue);

		refreshGlobalAssistantHUD(true);
	}

	private function refreshGlobalAssistantHUD(force:Bool = false):Void
	{
		if (globalTitle == null || globalDialogue == null)
			return;

		var assistantName = AssistantManager.currentAssistant;
		var skyVariant = AssistantManager.skyVariant;

		if (force || assistantName != lastAssistantName || skyVariant != lastSkyVariant)
		{
			globalTitle.text = AssistantManager.getAssistantDisplayName();
			globalTitle.color = AssistantManager.getAssistantColor();
			globalDialogue.text = AssistantManager.getDialogue("welcome");
			lastAssistantName = assistantName;
			lastSkyVariant = skyVariant;
		}
	}

	override function update(elapsed:Float)
	{
		AssistantManager.updateTimer(elapsed);
		refreshGlobalAssistantHUD();

		var oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if (curStep > 0)
				stepHit();

			if (PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if (FlxG.save.data != null)
			FlxG.save.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage)
		{
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if (stepsToDo < 1)
			stepsToDo = Math.round(getBeatsOnSection() * 4);

		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if (curStep < 0 || PlayState.SONG == null)
			return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;

		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep)
					break;

				curSection++;
			}
		}

		if (curSection > lastSection)
			sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;

		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public static function switchState(nextState:FlxState = null):Void
	{
		if (nextState == null)
			nextState = FlxG.state;

		if (nextState == FlxG.state)
		{
			resetState();
			return;
		}

		if (FlxTransitionableState.skipNextTransIn)
			FlxG.switchState(nextState);
		else
			startTransition(nextState);

		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function resetState():Void
	{
		if (FlxTransitionableState.skipNextTransIn)
			FlxG.resetState();
		else
			startTransition();

		FlxTransitionableState.skipNextTransIn = false;
	}

	public static function startTransition(nextState:FlxState = null):Void
	{
		if (nextState == null)
			nextState = FlxG.state;

		FlxG.state.openSubState(new CustomFadeTransition(0.5, false));

		if (nextState == FlxG.state)
			CustomFadeTransition.finishCallback = function() FlxG.resetState();
		else
			CustomFadeTransition.finishCallback = function() FlxG.switchState(nextState);
	}

	public static function getState():MusicBeatState
	{
		return cast(FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		stagesFunc(function(stage:BaseStage)
		{
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	private function stagesFunc(func:BaseStage->Void):Void
	{
		for (stage in stages)
		{
			if (stage != null && stage.exists && stage.active)
				func(stage);
		}
	}

	private function getBeatsOnSection():Float
	{
		var val:Null<Float> = 4;
		if (PlayState.SONG != null && PlayState.SONG.notes[curSection] != null)
			val = PlayState.SONG.notes[curSection].sectionBeats;

		return val == null ? 4 : val;
	}
}
