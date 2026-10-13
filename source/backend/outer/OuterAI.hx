package backend.outer;

import haxe.Json;

/**
 * Optional local-model bridge. It is deliberately opt-in and defaults to
 * localhost, so the engine never silently uploads prompts to a remote service.
 */
class OuterAI
{
    public static var enabled:Bool = false;
    public static var endpoint:String = "http://127.0.0.1:11434/api/generate";
    public static var model:String = "llama3.2:3b";
    public static var timeoutSeconds:Int = 90;

    public static function ask(assistantId:String, prompt:String, callback:String->Void):Void
    {
        var assistant:OuterAssistant = OuterAssistant.byId(assistantId);
        if (!enabled)
        {
            callback("OUTER AI is disabled. Enable it in settings and start a local Ollama server to use " + assistant.displayName + ".");
            return;
        }

        #if sys
        var http:sys.Http = new sys.Http(endpoint);
        http.setHeader("Content-Type", "application/json");
        http.setPostData(Json.stringify({
            model: model,
            prompt: assistant.systemPrompt + "\n\nUser request:\n" + prompt,
            stream: false,
            options: { temperature: 0.4, num_predict: 700 }
        }));
        http.onData = function(data:String)
        {
            try
            {
                var response:Dynamic = Json.parse(data);
                var text:Dynamic = Reflect.field(response, "response");
                callback(text == null ? "The local model returned an empty response." : Std.string(text));
            }
            catch (e:Dynamic)
            {
                callback("Could not parse the local AI response: " + Std.string(e));
            }
        };
        http.onError = function(error:String)
        {
            callback("Local AI connection failed: " + error +
                "\nCheck that Ollama is running at " + endpoint + " and that model '" + model + "' is installed.");
        };
        try
        {
            http.request(true);
        }
        catch (e:Dynamic)
        {
            callback("Could not contact the local AI service: " + Std.string(e));
        }
        #else
        callback("Local Ollama integration is only available on sys targets in this build.");
        #end
    }
}
