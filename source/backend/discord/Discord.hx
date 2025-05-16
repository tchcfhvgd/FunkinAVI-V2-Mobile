package backend.discord;

#if desktop
import Sys.sleep;
import lime.app.Application;
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

class DiscordClient
{
	public static var isInitialized:Bool = false;
	private static final _defaultID:String = "1297021927788904491";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordRichPresence = DiscordRichPresence.create();
	public static var discordName:String = "None";
	
	public static function prepare()
	{
		if (!isInitialized)
			initialize();

		Application.current.window.onClose.add(function() {
			if(isInitialized) shutdown();
		});
	}

	public dynamic static function shutdown() {
		Discord.Shutdown();
		isInitialized = false;
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void {
		var requestPtr:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(requestPtr.discriminator, String)) != 0) //New Discord IDs/Discriminator system
		{
			trace('(Discord) Connected to User (${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)})');
			discordName = '${cast(requestPtr.username, String)}#${cast(requestPtr.discriminator, String)}';
		}
		else //Old discriminators
		{
			trace('(Discord) Connected to User (${cast(requestPtr.username, String)})');
			discordName = '${cast(requestPtr.username, String)}';
		}

		changePresence();
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void {
		trace('Discord: Error ($errorCode: ${cast(message, String)})');
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void {
		trace('Discord: Disconnected ($errorCode: ${cast(message, String)})');
	}

	public static function initialize()
	{
		var discordHandlers:DiscordEventHandlers = DiscordEventHandlers.create();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), 1, null);

		if(!isInitialized) trace("Discord Client initialized");

		sys.thread.Thread.create(() ->
		{
			var localID:String = clientID;
			while (localID == clientID)
			{
				#if DISCORD_DISABLE_IO_THREAD
				Discord.UpdateConnection();
				#end
				Discord.RunCallbacks();

				// Wait 0.5 seconds until the next loop...
				Sys.sleep(0.5);
			}
		});
		isInitialized = true;
	}

	public static function changePresence(?details:String = 'Starting Game...', ?state:Null<String>, ?largeImageKey:String = 'default', ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		var startTimestamp:Float = 0;
		if (hasStartTimestamp) startTimestamp = Date.now().getTime();
		if (endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.details = details;
		presence.state = state;
		presence.largeImageKey = largeImageKey;
		presence.largeImageText = "Funkin.avi";
		presence.smallImageKey =  smallImageKey;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);

		var button1:DiscordButton = DiscordButton.create();
        button1.label = "GameJolt Page";
		button1.url = "https://gamejolt.com/games/funkin-avi/710505";

        var button2:DiscordButton = DiscordButton.create();
        button2.label = "Discord Server";
        button2.url = "https://discord.gg/qTZYpP4hg3";

		presence.buttons[0] = button2;
		presence.buttons[1] = button1;

		updatePresence();
		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	public static function updatePresence()
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence));
	
	public static function resetClientID()
		clientID = _defaultID;

	private static function set_clientID(newID:String)
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}
}
#end
