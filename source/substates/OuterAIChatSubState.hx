package substates;

import backend.outer.OuterAI;
import backend.outer.OuterAssistant;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.addons.ui.FlxInputText;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class OuterAIChatSubState extends FlxSubState
{
	private var assistant:OuterAssistant;
	private var transcript:FlxText;
	private var inputField:FlxInputText;
	private var statusText:FlxText;
	private var enableButton:FlxText;
	private var sendButton:FlxText;
	private var closeButton:FlxText;
	private var conversation:Array<String> = [];
	private var waiting:Bool = false;

	public function new(assistantId:String = "minusbright")
	{
		super(0xE6080712);
		assistant = OuterAssistant.byId(assistantId);
	}

	override public function create():Void
	{
		super.create();

		var panel:FlxSprite = new FlxSprite(0, 0);
		panel.makeGraphic(760, 510, 0xFF171329);
		panel.screenCenter();
		panel.scrollFactor.set();
		add(panel);

		var title:FlxText = new FlxText(panel.x + 24, panel.y + 18, 500, assistant.displayName + "  |  OUTER AI CHAT", 22);
		title.setFormat(Paths.font("vcr.ttf"), 22, FlxColor.WHITE, LEFT);
		title.scrollFactor.set();
		add(title);

		closeButton = makeLabel(panel.x + panel.width - 70, panel.y + 18, 45, "[ X ]", 16, FlxColor.WHITE);
		add(closeButton);

		statusText = makeLabel(panel.x + 24, panel.y + 52, panel.width - 48, "", 13, FlxColor.GRAY);
		updateStatus();
		add(statusText);

		enableButton = makeLabel(panel.x + 24, panel.y + 76, 300, "", 14, FlxColor.CYAN);
		updateEnableButton();
		add(enableButton);

		transcript = new FlxText(panel.x + 24, panel.y + 108, panel.width - 48, "", 15);
		transcript.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, LEFT);
		transcript.borderStyle = OUTLINE;
		transcript.borderColor = FlxColor.BLACK;
		transcript.borderSize = 1;
		transcript.scrollFactor.set();
		transcript.text = "You are chatting with " + assistant.displayName + ".\nMessages are sent to your configured local Ollama endpoint.\n";
		add(transcript);

		inputField = new FlxInputText(panel.x + 24, panel.y + panel.height - 68, panel.width - 145, "", 16, FlxColor.WHITE, 0xFF29243B, true, true, true, true);
		inputField.scrollFactor.set();
		add(inputField);

		sendButton = makeLabel(panel.x + panel.width - 108, panel.y + panel.height - 66, 80, "[ SEND ]", 16, FlxColor.LIME);
		add(sendButton);

		var hint:FlxText = makeLabel(panel.x + 24, panel.y + panel.height - 28, panel.width - 48, "ENTER sends  |  ESC closes  |  Local model: " + OuterAI.model, 11, FlxColor.GRAY);
		add(hint);
	}

	private function makeLabel(x:Float, y:Float, width:Float, text:String, size:Int, color:FlxColor):FlxText
	{
		var label:FlxText = new FlxText(x, y, width, text, size);
		label.setFormat(Paths.font("vcr.ttf"), size, color, LEFT);
		label.scrollFactor.set();
		return label;
	}

	private function updateStatus():Void
	{
		if (statusText == null) return;
		statusText.text = "Specialty: " + assistant.role + "  |  Endpoint: " + OuterAI.endpoint;
	}

	private function updateEnableButton():Void
	{
		if (enableButton == null) return;
		enableButton.text = OuterAI.enabled ? "[ DISABLE LOCAL AI ]" : "[ ENABLE LOCAL AI ]";
		enableButton.color = OuterAI.enabled ? FlxColor.LIME : FlxColor.ORANGE;
	}

	private function sendMessage():Void
	{
		if (waiting || inputField == null) return;
		var message:String = StringTools.trim(inputField.text);
		if (message.length == 0) return;

		inputField.text = "";
		conversation.push("YOU: " + message);
		transcript.text += "\nYOU: " + message + "\n" + assistant.displayName + ": thinking...\n";
		waiting = true;

		var context:Array<String> = conversation.copy();
		if (context.length > 12) context = context.slice(context.length - 12);
		var prompt:String = "Continue this conversation as " + assistant.displayName + ".\n\n" + context.join("\n") + "\n\nReply to the latest YOU message. Do not repeat the transcript.";
		OuterAI.ask(assistant.id, prompt, function(reply:String)
		{
			waiting = false;
			conversation.push(assistant.displayName + ": " + reply);
			transcript.text = "You are chatting with " + assistant.displayName + ".\nMessages are sent to your configured local Ollama endpoint.\n\n" + conversation.join("\n\n");
			transcript.scrollFactor.set();
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			close();
			return;
		}

		if (FlxG.keys.justPressed.ENTER)
			sendMessage();

		if (FlxG.mouse.justPressed)
		{
			if (closeButton != null && FlxG.mouse.overlaps(closeButton))
			{
				close();
				return;
			}
			if (sendButton != null && FlxG.mouse.overlaps(sendButton))
				sendMessage();
			if (enableButton != null && FlxG.mouse.overlaps(enableButton))
			{
				OuterAI.enabled = !OuterAI.enabled;
				updateEnableButton();
				updateStatus();
			}
		}
	}
}
