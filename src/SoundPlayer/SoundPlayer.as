package
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.ID3Info;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	/**
	 * support mp3
	 */
	public class SoundPlayer extends EventDispatcher
	{
		//event
		public static const EVENT_LOAD_START:String = "eventLoadStart";
		public static const EVENT_LOAD_SUCCESS:String = "eventLoadSuccess";
		public static const EVENT_LOAD_ERROR:String = "eventLoadError";
		public static const EVENT_LOAD_TIMEOUT:String = "eventLoadTimeout";
		public static const EVENT_LOAD_PROGRESS:String = "eventLoadProgress";
		public static const EVENT_LOAD_COMPLETE:String = "eventLoadComplete";
		
		public static const EVENT_PLAY_START:String = "eventPlayStart";
		//public static const EVENT_PLAY_BUFFER_EMPTY:String = "eventPlayBufferEmpty";
		//public static const EVENT_PLAY_BUFFER_FULL:String = "eventPlayBufferFull";
		public static const EVENT_PLAY_PROGRESS:String = "eventPlayProgress";
		public static const EVENT_PLAY_COMPLETE:String = "eventPlayComplete";
		
		public static const EVENT_METADATA:String = "eventMetadata";
		//public static const EVENT_CLICK:String = "eventClick";
		
		//private static const BUFFER_TIME:int = 2;
		private static const PLAYER_CLOCK:int = 250;
		private static const CONNECT_TIMEOUT_VALUE:int = 4000;
		private static const LOADING_TIMEOUT_VALUE:int = 0;
		
		private var soundFactory:Sound;
		private var soundChannel:SoundChannel;
		
		private var _first_size_loaded:Boolean = false;
		private var _start_play:Boolean = false;
		private var _volume:Number = 0.3;
		private var _mute:Boolean = false;
		private var _playing:Boolean = false;
		private var _play_end:Boolean = false;
		private var _metaData:ID3Info;
		private var _playURL:String;
		private var _playtime:Number; //秒
		
		private var playTimer:Timer;
		private var loadTimer:Timer;
		
		private var isLoadSucc:Boolean = false;
		private var isLoadComplete:Boolean = false;
		
		private var curConnectTimeout:Number;
		private var curLoadingTimeout:Number;
		
		public function SoundPlayer()
		{
		}
		
		private function resetBody():void
		{
			close();
			//play clock
			playTimer = new Timer(PLAYER_CLOCK);
			playTimer.addEventListener(TimerEvent.TIMER, playTimerHandler);
			
			//load clock
			loadTimer = new Timer(PLAYER_CLOCK);
			loadTimer.addEventListener(TimerEvent.TIMER, loadTimerHandler);
			
			soundFactory = new Sound();
			soundFactory.addEventListener(Event.COMPLETE, loadCompleteHandler);
			soundFactory.addEventListener(Event.ID3, id3Handler);
			soundFactory.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			soundChannel = new SoundChannel();
			soundChannel.addEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
			
			volume = _volume;
			mute = _mute;
		}
		
		private function close():void
		{
			_metaData = null;
			_playURL = "";
			_playtime = 0;
			isLoadComplete = false;
			isLoadSucc = false;
			_start_play = false;
			_playing = false;
			_play_end = false;
			
			_first_size_loaded = false;
			
			curConnectTimeout = 0;
			curLoadingTimeout = 0;
			
			if (soundFactory)
			{
				soundFactory.close();
				soundFactory.removeEventListener(Event.COMPLETE, loadCompleteHandler);
				soundFactory.removeEventListener(Event.ID3, id3Handler);
				soundFactory.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				soundFactory = null;
			}
			
			if (soundChannel)
			{
				soundChannel.stop();
				soundChannel.removeEventListener(Event.SOUND_COMPLETE, soundCompleteHandler);
				soundChannel = null;
			}
			
			removeLoadTimer();
			removePlayTimer();
		}
		
		private function removePlayTimer():void
		{
			if (playTimer)
			{
				playTimer.reset();
				playTimer.removeEventListener(TimerEvent.TIMER, playTimerHandler);
				playTimer = null;
			}
		}
		
		private function removeLoadTimer():void
		{
			if (loadTimer)
			{
				loadTimer.reset();
				loadTimer.removeEventListener(TimerEvent.TIMER, loadTimerHandler);
				loadTimer = null;
			}
			
			if (curConnectTimeout > 0)
			{
				clearTimeout(curConnectTimeout);
			}
			
			if (curLoadingTimeout > 0)
			{
				clearTimeout(curLoadingTimeout);
			}
		}
		
		private function id3Handler(event:Event):void
		{
			_metaData = soundFactory.id3;
			dispatch(EVENT_METADATA);
		}
		
		private function ioErrorHandler(event:Event):void
		{
			errorHlr();
		}
		
		private function soundCompleteHandler(event:Event):void
		{
			completeHlr();
		}
		
		private function bufferEmptyHlr():void
		{
		}
		
		private function bufferFullHlr():void
		{
		}
		
		private function completeHlr():void
		{
			_playing = false;
			_play_end = true;
			if (playTimer && playTimer.running)
				playTimer.stop();
			dispatch(EVENT_PLAY_COMPLETE);
		}
		
		private function errorHlr():void
		{
			_playing = false;
			removeLoadTimer();
			dispatch(EVENT_LOAD_ERROR);
		}
		
		private function onConnectTimeOutHlr():void
		{
			_playing = false;
			removeLoadTimer();
			dispatch(EVENT_LOAD_TIMEOUT);
		}
		
		private function onSoundLoadingTimeOutHlr():void
		{
			onConnectTimeOutHlr();
		}
		
		private function playTimerHandler(event:TimerEvent):void
		{
			if (totalTime == 0)
				return;
			if (!_start_play)
				return;
			if (!_playing)
				return;
			if (soundChannel)
				_playtime = soundChannel.position / 1000;
			dispatch(EVENT_PLAY_PROGRESS);
		}
		
		private function loadTimerHandler(event:TimerEvent):void
		{
			if (!soundFactory)
				return;
			if (!soundFactory.bytesTotal)
				return;
			if (soundFactory.bytesLoaded < soundFactory.bytesTotal)
			{
				if (!_first_size_loaded && soundFactory.bytesLoaded > 0)
				{
					_first_size_loaded = true;
					if (curConnectTimeout > 0)
					{
						clearTimeout(curConnectTimeout);
					}
					if (curLoadingTimeout > 0)
					{
						clearTimeout(curLoadingTimeout);
					}
					if (LOADING_TIMEOUT_VALUE > 0)
					{
						curLoadingTimeout = setTimeout(onSoundLoadingTimeOutHlr, LOADING_TIMEOUT_VALUE);
					}
					dispatch(EVENT_LOAD_SUCCESS);
				}
				dispatch(EVENT_LOAD_PROGRESS);
			}
		}
		
		private function loadCompleteHandler(event:Event):void
		{
			isLoadComplete = true;
			removeLoadTimer();
			dispatch(EVENT_LOAD_COMPLETE);
		}
		
		private function setVolume(value:Number):void
		{
			if (soundChannel)
			{
				var soundTsf:SoundTransform = soundChannel.soundTransform;
				soundTsf.volume = value;
				soundChannel.soundTransform = soundTsf;
			}
		}
		
		private function dispatch(eventType:String):void
		{
			dispatchEvent(new Event(eventType));
		}
		
		public function load(url:String):void
		{
			if (!url || url == "")
			{
				errorHlr();
			}
			try
			{
				dispatch(EVENT_LOAD_START);
				
				resetBody();
				_playURL = url;
				
				soundFactory.load(new URLRequest(url));
				
				loadTimer.start();
				
				if (curConnectTimeout > 0)
				{
					clearTimeout(curConnectTimeout);
				}
				if (CONNECT_TIMEOUT_VALUE > 0)
				{
					curConnectTimeout = setTimeout(onConnectTimeOutHlr, CONNECT_TIMEOUT_VALUE);
				}
			}
			catch (e:*)
			{
				errorHlr();
			}
		}
		
		public function play():void
		{
			_start_play = true;
			if (playTimer && !playTimer.running)
				playTimer.start();
			
			resume();
			dispatch(EVENT_PLAY_START);
		}
		
		public function resume():void
		{
			if (!_start_play)
			{
				play();
				return;
			}
			if (_play_end)
			{
				replay();
			}
			else
			{
				if (soundChannel)
				{
					if (playTimer && !playTimer.running)
						playTimer.start();
					if (_playing)
						soundChannel.stop();
					_playing = true;
					
					soundChannel = soundFactory.play(playTime * 1000);
				}
			}
		}
		
		public function pause():void
		{
			if (soundChannel)
			{
				if (playTimer && playTimer.running)
					playTimer.stop();
				_playing = false;
				
				_playtime = soundChannel.position / 1000;
				soundChannel.stop();
			}
		}
		
		public function seek(time:Number):void
		{
			if (totalTime > 0 && time >= totalTime)
			{
				return;
			}
			if (time < 0)
				time = 0;
			if (soundFactory)
			{
				_playing = true;
				_play_end = false;
				
				soundChannel.stop();
				soundChannel = soundFactory.play(time * 1000);
			}
		}
		
		public function replay():void
		{
			_play_end = false;
			_playing = true;
			seek(0);
		}
		
		public function destroy():void
		{
			close();
		}
		
		public function resize(w:Number, h:Number):void
		{
		}
		
		public function get loadSize():Number
		{
			if (soundFactory)
				return soundFactory.bytesLoaded;
			else
				return 0;
		}
		
		public function get totalSize():Number
		{
			if (soundFactory)
				return soundFactory.bytesTotal;
			else
				return 0;
		}
		
		public function get playTime():Number
		{
			return _playtime ? _playtime : 0;
		}
		
		public function get totalTime():Number
		{
			return soundFactory ? soundFactory.length / 1000 : 0;
		}
		
		public function get metaData():ID3Info
		{
			return _metaData;
		}
		
		public function get playing():Boolean
		{
			return _playing;
		}
		
		public function set mute(value:Boolean):void
		{
			_mute = value;
			if (_mute)
				setVolume(0);
			else
				setVolume(_volume);
		}
		
		public function get mute():Boolean
		{
			return _mute;
		}
		
		public function set volume(value:Number):void
		{
			if (isNaN(value))
				_volume = 0;
			else if (value < 0)
				_volume = 0;
			else if (value > 1)
				_volume = 1;
			else
				_volume = value;
			setVolume(_volume);
		}
		
		public function get volume():Number
		{
			return _volume;
		}
	}
}