package states;

import backend.Song;
import backend.WeekData;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var optionShit:Array<String> = ['play', 'credits', 'options'];
	var optionPos = [[10, 35], [10, 285], [10, 435]];

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var bg = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFFFF716D, 0xFFFFEF63], 1, 45);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		var movingGrid = new FlxBackdrop(FlxGridOverlay.create(128, 128, 1280, 1280).graphic);
		movingGrid.antialiasing = ClientPrefs.data.antialiasing;
		movingGrid.updateHitbox();
		movingGrid.screenCenter();
		movingGrid.velocity.set(25, 25);
		movingGrid.alpha = .5;
		add(movingGrid);

		var border = new FlxSprite().loadGraphic(Paths.image('menus/mainmenu/border'));
		border.antialiasing = ClientPrefs.data.antialiasing;
		border.updateHitbox();
		add(border);

		add(menuItems = new FlxTypedGroup<FlxSprite>());

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite();
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.frames = Paths.getSparrowAtlas('menus/mainmenu/menu_assets');
			menuItem.animation.addByPrefix('idle', optionShit[i], 24);
			// menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.alpha = .6;
			if (i == 0)
				menuItem.scale.set(.85, .85);
			else
				menuItem.scale.set(.7, .7);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);

			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;

			menuItem.scrollFactor.set(0, scr);
			menuItem.updateHitbox();
			menuItem.x = optionPos[i][0];
			menuItem.y = optionPos[i][1];
		}

		var psychVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		psychVer.scrollFactor.set();
		psychVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(psychVer);
		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayState.vocals != null)
				FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		for (i => spr in menuItems)
		{
			spr.scale.x = FlxMath.lerp(spr.scale.x, i == curSelected ? .85 : .7, FlxMath.bound(elapsed * 5, 0, 1));
			spr.scale.y = FlxMath.lerp(spr.scale.y, i == curSelected ? .85 : .7, FlxMath.bound(elapsed * 5, 0, 1));
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				/*if (optionShit[curSelected] == 'donate')
					{
						CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
					}
					else
					{ */
				selectedSomethin = true;

				FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flick:FlxFlicker)
				{
					switch (optionShit[curSelected])
					{
						case 'play':
							// Thanks Flain!
							WeekData.reloadWeekFiles(true);
							PlayState.SONG = Song.loadFromJson('test', 'test');
							PlayState.storyPlaylist = ['test'];
							PlayState.isStoryMode = true;
							Difficulty.list = ['hard'];
							PlayState.storyDifficulty = 0;
							PlayState.storyWeek = WeekData.weeksList.indexOf('tutorial');
							LoadingState.loadAndSwitchState(new PlayState(), true);
						case 'story_mode':
							MusicBeatState.switchState(new StoryMenuState());
						case 'freeplay':
							MusicBeatState.switchState(new FreeplayState());

						#if MODS_ALLOWED
						case 'mods':
							MusicBeatState.switchState(new ModsMenuState());
						#end

						#if ACHIEVEMENTS_ALLOWED
						case 'awards':
							MusicBeatState.switchState(new AchievementsMenuState());
						#end

						case 'credits':
							MusicBeatState.switchState(new CreditsState());
						case 'options':
							MusicBeatState.switchState(new OptionsState());
							OptionsState.onPlayState = false;
							if (PlayState.SONG != null)
							{
								PlayState.SONG.arrowSkin = null;
								PlayState.SONG.splashSkin = null;
								PlayState.stageUI = 'normal';
							}
					}
				});

				for (i in 0...menuItems.members.length)
				{
					if (i == curSelected)
						continue;
					FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							menuItems.members[i].kill();
						}
					});
				}
				// }
			}
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		menuItems.members[curSelected].alpha = .6;
		curSelected = (curSelected + huh + menuItems.length) % menuItems.length;
		menuItems.members[curSelected].alpha = 1;
	}
}
