package
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class TestVideoPlayer extends Sprite
	{
		private var videoPlayer:VideoPlayer;
		
		public function TestVideoPlayer():void
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
			
			videoPlayer = new VideoPlayer();
			videoPlayer.addEventListener(VideoPlayer.EVENT_LOAD_START, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_LOAD_SUCCESS, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_LOAD_ERROR, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_LOAD_TIMEOUT, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_LOAD_PROGRESS, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_LOAD_COMPLETE, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_PLAY_START, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_PLAY_BUFFER_EMPTY, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_PLAY_BUFFER_FULL, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_PLAY_PROGRESS, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_PLAY_COMPLETE, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_METADATA, onPlayerHlr);
			videoPlayer.addEventListener(VideoPlayer.EVENT_CLICK, onPlayerHlr);
			videoPlayer.load("http://f.xxx.com/1.mp4");
			videoPlayer.play();
			addChild(videoPlayer);
			
			//播放暂停
			ShortcutKeys.getInstance(stage).add("space", function():void
				{
					if (videoPlayer.playing)
						videoPlayer.pause();
					else
						videoPlayer.resume();
				});
			ShortcutKeys.getInstance(stage).add("left", function():void
				{
					var pt:Number = videoPlayer.playTime;
					videoPlayer.seek(pt - 10);
				});
			ShortcutKeys.getInstance(stage).add("right", function():void
				{
					var pt:Number = videoPlayer.playTime;
					videoPlayer.seek(pt + 10);
				});
			ShortcutKeys.getInstance(stage).add("r", function():void
				{
					videoPlayer.replay();
				});
			//包含黑色背景的截图
			ShortcutKeys.getInstance(stage).add("z", function():void
				{
					var bitmap:Bitmap = new Bitmap(videoPlayer.getSnapshot());
					bitmap.x = 401;
					addChild(bitmap);
				});
			//仅有video的截图
			ShortcutKeys.getInstance(stage).add("x", function():void
				{
					var bitmap:Bitmap = new Bitmap(videoPlayer.getSnapshot(false));
					bitmap.y = 301;
					addChild(bitmap);
				});
		}
		
		private function onPlayerHlr(e:Event):void
		{
			switch (e.type)
			{
				case VideoPlayer.EVENT_CLICK: 
					if (videoPlayer.playing)
						videoPlayer.pause();
					else
						videoPlayer.resume();
					break;
			}
		}
	
	}
}