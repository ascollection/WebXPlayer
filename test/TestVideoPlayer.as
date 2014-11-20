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
			videoPlayer.load("http://f.tudou.com/1.mp4");
			videoPlayer.play();
			addChild(videoPlayer);
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
						
						var bitmap:Bitmap = new Bitmap(videoPlayer.getSnapshot(false));
						bitmap.y = 301;
						addChild(bitmap);
					break;
				
			}
		}
	
	}
}