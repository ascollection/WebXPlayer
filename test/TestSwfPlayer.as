package  
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author kshen
	 */
	public class TestSwfPlayer extends Sprite 
	{
		
		private var swfPlayer:SwfPlayer;
		
		public function TestSwfPlayer():void
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
			
			swfPlayer = new SwfPlayer();
			swfPlayer.addEventListener(SwfPlayer.EVENT_LOAD_START, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_LOAD_SUCCESS, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_LOAD_ERROR, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_LOAD_TIMEOUT, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_LOAD_PROGRESS, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_LOAD_COMPLETE, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_PLAY_START, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_PLAY_BUFFER_EMPTY, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_PLAY_BUFFER_FULL, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_PLAY_PROGRESS, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_PLAY_COMPLETE, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_METADATA, onPlayerHlr);
			swfPlayer.addEventListener(SwfPlayer.EVENT_CLICK, onPlayerHlr);
			//swfPlayer.load("http://y0.ifengimg.com/tres/recommend/cpro/same/2014/11/1120_rc1/1000400.swf");
			swfPlayer.load("http://f.xxx.com/123.jpg");
			swfPlayer.play();
			addChild(swfPlayer);
			
			//播放暂停
			ShortcutKeys.getInstance(stage).add("space", function():void
				{
					if (swfPlayer.playing)
						swfPlayer.pause();
					else
						swfPlayer.resume();
				});
			ShortcutKeys.getInstance(stage).add("left", function():void
				{
					var pt:Number = swfPlayer.playTime;
					swfPlayer.seek(pt - 10);
				});
			ShortcutKeys.getInstance(stage).add("right", function():void
				{
					var pt:Number = swfPlayer.playTime;
					swfPlayer.seek(pt + 10);
				});
			ShortcutKeys.getInstance(stage).add("r", function():void
				{
					swfPlayer.replay();
				});
			//包含黑色背景的截图
			ShortcutKeys.getInstance(stage).add("z", function():void
				{
					var bitmap:Bitmap = new Bitmap(swfPlayer.getSnapshot());
					bitmap.x = 401;
					addChild(bitmap);
				});
			//仅有video的截图
			ShortcutKeys.getInstance(stage).add("x", function():void
				{
					var bitmap:Bitmap = new Bitmap(swfPlayer.getSnapshot(false));
					bitmap.y = 301;
					addChild(bitmap);
				});
		}
		
		private function onPlayerHlr(e:Event):void
		{
			trace(e.type);
			switch (e.type)
			{
				case SwfPlayer.EVENT_CLICK: 
					if (swfPlayer.playing)
						swfPlayer.pause();
					else
						swfPlayer.resume();
					break;
			}
		}
		
	}

}