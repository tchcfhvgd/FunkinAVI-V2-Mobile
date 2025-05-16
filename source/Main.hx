package;

import openfl.Assets;
import openfl.Lib;
import backend.Framerate;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;

#if mobile
import mobile.CopyState;
#end

using StringTools;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var initialState:Class<FlxState> = /*EVILantileakState; *uncomment for playtest builds*/ TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:Framerate;
	public static var debug:Bool = false;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
	}

	public function new()
	{
		#if mobile
		#if android
		StorageUtil.requestPermissions();
		#end
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end

		CrashHandler.init();

		#if windows
		@:functionCode("
		#include <windows.h>
		#include <winuser.h>
		setProcessDPIAware() // allows for more crisp visuals
		DisableProcessWindowsGhosting() // lets you move the window and such if it's not responding
		")
		#end
		
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		ClientPrefs.loadDefaultKeys();

		var game:FlxGame = new FlxGame(gameWidth, gameHeight, #if (mobile && MODS_ALLOWED) !CopyState.checkExistingFiles() ? CopyState : #end Init, #if (flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash, startFullscreen);
		@:privateAccess game._customSoundTray = gameObjects.ui.Soundtray;
		addChild(game);

		fpsVar = new Framerate(10, 3);
		fpsVar.textColor = FlxColor.WHITE;
		#if !mobile
		addChild(fpsVar);
		#else
		FlxG.game.addChild(fpsVar);
		#end
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}

		FlxG.autoPause = ClientPrefs.autoPause;
		#if html5
		FlxG.mouse.visible = false;
		#end
		
		#if mobile
		lime.system.System.allowScreenTimeout = ClientPrefs.screensaver;
		#if android
		FlxG.android.preventDefaultKeys = [BACK]; 
		#end
		#end

		//FlxG.mouse.load(Paths.image('UI/funkinAVI/mouses/Hand').bitmap);
		FlxG.signals.gameResized.add(function (w, h) {
			if (FlxG.cameras != null) {
			  for (cam in FlxG.cameras.list) {
			   if (cam != null && cam.filters != null)
				   resetSpriteCache(cam.flashSprite);
			  }
		   }

		   if (FlxG.game != null)
		    @:privateAccess {
				FlxG.game.__cacheBitmap = null;
				FlxG.game.__cacheBitmapData = null;
		}
	   });
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
				sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
