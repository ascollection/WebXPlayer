package
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class TestSoundPlayer extends Sprite
	{
		
		private var soundPlayer:SoundPlayer;
		
		public function TestSoundPlayer():void
		{
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			stage.addEventListener(MouseEvent.CLICK, onPlayerHlr);
			
			soundPlayer = new SoundPlayer();
			soundPlayer.addEventListener(SoundPlayer.EVENT_LOAD_START, onPlayerHlr);
			soundPlayer.addEventListener(SoundPlayer.EVENT_LOAD_SUCCESS, onPlayerHlr);
			soundPlayer.addEventListener(SoundPlayer.EVENT_LOAD_ERROR, onPlayerHlr);
			soundPlayer.addEventListener(SoundPlayer.EVENT_LOAD_TIMEOUT, onPlayerHlr);
			soundPlayer.addEventListener(SoundPlayer.EVENT_LOAD_PROGRESS, onPlayerHlr);
			soundPlayer.addEventListener(SoundPlayer.EVENT_LOAD_COMPLETE, onPlayerHlr);
			soundPlayer.addEventListener(SoundPlayer.EVENT_PLAY_START, onPlayerHlr);
			soundPlayer.addEventListener(SoundPlayer.EVENT_PLAY_PROGRESS, onPlayerHlr);
			soundPlayer.addEventListener(SoundPlayer.EVENT_PLAY_COMPLETE, onPlayerHlr);
			soundPlayer.addEventListener(SoundPlayer.EVENT_METADATA, onPlayerHlr);
			soundPlayer.load("http://yinyueshiting.baidu.com/data2/music/124383755/124380645248400128.mp3?xcode=c3b12282d2ea888111e44eea0118506175126f645fd13307");
			soundPlayer.play();
			
			//播放暂停
			ShortcutKeys.getInstance(stage).add("space", function():void
				{
					if (soundPlayer.playing)
						soundPlayer.pause();
					else
						soundPlayer.resume();
				});
			ShortcutKeys.getInstance(stage).add("left", function():void
				{
					var pt:Number = soundPlayer.playTime;
					soundPlayer.seek(pt - 10);
				});
			ShortcutKeys.getInstance(stage).add("right", function():void
				{
					var pt:Number = soundPlayer.playTime;
					soundPlayer.seek(pt + 10);
				});
			ShortcutKeys.getInstance(stage).add("down", function():void
				{
					var v:Number = soundPlayer.volume;
					soundPlayer.volume = v - 0.1;
				});
			ShortcutKeys.getInstance(stage).add("up", function():void
				{
					var v:Number = soundPlayer.volume;
					soundPlayer.volume = v + 0.1;
				});
			ShortcutKeys.getInstance(stage).add("r", function():void
				{
					soundPlayer.replay();
				});
		}
		
		private function onPlayerHlr(e:Event):void
		{
			trace(e.type);
			switch (e.type)
			{
				case MouseEvent.CLICK: 
					if (soundPlayer.playing)
						soundPlayer.pause();
					else
						soundPlayer.resume();
					break;
			}
		}
	
	}

}