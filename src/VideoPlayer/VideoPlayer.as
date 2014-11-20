package
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	/**
	 * support mp4/flv/f4v
	 */
	public class VideoPlayer extends Sprite
	{
		//event
		public static const EVENT_LOAD_START:String = "eventLoadStart";
		public static const EVENT_LOAD_SUCCESS:String = "eventLoadSuccess";
		public static const EVENT_LOAD_ERROR:String = "eventLoadError";
		public static const EVENT_LOAD_TIMEOUT:String = "eventLoadTimeout";
		public static const EVENT_LOAD_PROGRESS:String = "eventLoadProgress";
		public static const EVENT_LOAD_COMPLETE:String = "eventLoadComplete";
		
		public static const EVENT_PLAY_START:String = "eventPlayStart";
		public static const EVENT_PLAY_BUFFER_EMPTY:String = "eventPlayBufferEmpty";
		public static const EVENT_PLAY_BUFFER_FULL:String = "eventPlayBufferFull";
		public static const EVENT_PLAY_PROGRESS:String = "eventPlayProgress";
		public static const EVENT_PLAY_COMPLETE:String = "eventPlayComplete";
		
		public static const EVENT_METADATA:String = "eventMetadata";
		public static const EVENT_CLICK:String = "eventClick";
		
		private static const BUFFER_TIME:int = 2;
		private static const PLAYER_CLOCK:int = 250;
		private static const CONNECT_TIMEOUT_VALUE:int = 4000;
		private static const LOADING_TIMEOUT_VALUE:int = 0;
		
		private var background:Shape;
		private var netConnetion:NetConnection;
		private var netStream:NetStream;
		private var video:Video;
		
		private var _start_play:Boolean = false;
		private var _volume:Number = 0.3;
		private var _mute:Boolean = false;
		private var _playing:Boolean = false;
		private var _play_end:Boolean = false;
		private var _metaData:MetaData;
		private var _playURL:String;
		
		private var playTimer:Timer;
		private var loadTimer:Timer;
		
		private var videoScale:Number = 4 / 3;
		private var isLoadSucc:Boolean = false;
		private var isLoadComplete:Boolean = false;
		private var isFirstBufferFull:Boolean = false;
		
		private var curConnectTimeout:Number;
		private var curLoadingTimeout:Number;
		
		public function VideoPlayer(w:uint = 400, h:uint = 300)
		{
			//mask
			var thisMask:DisplayObject = getShape(w, h, 0x000000, 0.6);
			this.mask = thisMask;
			addChild(thisMask);
			
			//background
			background = getShape(w, h, 0x000000, 1);
			addChild(background);
			
			//video
			video = new Video(w, h);
			video.smoothing = true;
			video.deblocking = 1;
			addChild(video);
			
			//play clock
			playTimer = new Timer(PLAYER_CLOCK);
			playTimer.addEventListener(TimerEvent.TIMER, playTimerHandler);
			
			//load clock
			loadTimer = new Timer(PLAYER_CLOCK);
			loadTimer.addEventListener(TimerEvent.TIMER, loadTimerHandler);
			
			//click
			addEventListener(MouseEvent.CLICK, onCickHlr);
			buttonMode = true;
			mouseChildren = false;
			visible = false;
			
			curConnectTimeout = 0;
			curLoadingTimeout = 0;
			
			resetBody();
		}
		
		private function resetBody():void
		{
			close();
			
			netConnetion = new NetConnection();
			netConnetion.addEventListener(NetStatusEvent.NET_STATUS, onStatusHlr);
			netConnetion.connect(null);
			
			netStream = new NetStream(netConnetion);
			netStream.addEventListener(NetStatusEvent.NET_STATUS, onStatusHlr);
			netStream.bufferTime = BUFFER_TIME;
			netStream.client = {onMetaData: this.onMetaData};
			
			volume = _volume;
			mute = _mute;
			
			video.attachNetStream(netStream);
		}
		
		private function onMetaData(metaData:Object):void
		{
			if (_metaData != null)
				return;
			if (!metaData.filesize)
				metaData.filesize = netStream.bytesTotal;
			_metaData = new MetaData(metaData);
			
			var orginalVideoScale:Number = _metaData.width / _metaData.height;
			if (isNaN(orginalVideoScale) || orginalVideoScale <= 0)
				orginalVideoScale = 4.0 / 3;
			videoScale = orginalVideoScale;
			
			refresh();
			dispatch(EVENT_METADATA);
		}
		
		private function getShape(width:Number = 100, height:Number = 75, color:uint = 0x000000, alpha:Number = 1):Shape
		{
			var shape:Shape = new Shape();
			shape.graphics.clear();
			shape.graphics.beginFill(color, alpha);
			shape.graphics.drawRect(0, 0, width, height);
			shape.graphics.endFill();
			return shape;
		}
		
		private function setWidthHeight(w:Number, h:Number):void
		{
			background.width = w;
			background.height = h;
			mask.width = w;
			mask.height = h;
			video.width = w;
			video.height = h;
		}
		
		private function refresh():void
		{
			var ww:Number = background.width;
			var hh:Number = background.height;
			
			if (!_metaData)
				return;
			var containerAspectRatio:Number = ww / hh;
			
			var tempW:Number;
			var tempH:Number;
			
			if (containerAspectRatio > videoScale)
			{
				video.width = hh * videoScale;
				video.height = hh;
			}
			else
			{
				video.width = ww;
				video.height = ww / videoScale;
			}
			video.x = (ww - video.width) / 2;
			video.y = (hh - video.height) / 2;
		}
		
		private function setStreamVolume(value:Number):void
		{
			if (netStream)
			{
				var soundTsf:SoundTransform = netStream.soundTransform;
				soundTsf.volume = value;
				netStream.soundTransform = soundTsf;
			}
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
		
		private function close():void
		{
			_metaData = null;
			_playURL = "";
			isLoadComplete = false;
			isLoadSucc = false;
			isFirstBufferFull = false;
			_start_play = false;
			_playing = false;
			_play_end = false;
			
			if (netConnetion)
			{
				netConnetion.close();
				netConnetion.removeEventListener(NetStatusEvent.NET_STATUS, onStatusHlr);
				netConnetion = null;
			}
			if (netStream)
			{
				netStream.close();
				netStream.removeEventListener(NetStatusEvent.NET_STATUS, onStatusHlr);
				netStream = null;
			}
			
			if (playTimer)
				playTimer.reset();
			if (loadTimer)
				loadTimer.reset();
		}
		
		private function onCickHlr(e:MouseEvent):void
		{
			dispatch(EVENT_CLICK);
		}
		
		private function onStatusHlr(nse:NetStatusEvent):void
		{
			var code:String = nse.info.code;
			var level:String = nse.info.level;
			switch (code)
			{
				case "NetStream.Play.Start": 
					playStartHlr();
					break;
				case "NetStream.Buffer.Empty": 
					bufferEmptyHlr();
					break;
				case "NetStream.Buffer.Full": 
					bufferFullHlr();
					break;
				case "NetStream.Buffer.Flush": 
					break;
				case "NetStream.Seek.InvalidTime": 
				case "NetStream.Play.Stop": 
					completeHlr();
					break;
				case "NetStream.Pause.Notify": 
					break;
				case "NetStream.Unpause.Notify": 
					break;
				case "NetStream.Seek.Notify": 
					break;
				case "NetStream.Play.Failed": 
				case "NetStream.Play.StreamNotFound": 
				case "NetStream.Play.FileStructureInvalid": 
				case "NetStream.Play.NoSupportedTrackFound": 
					errorHlr();
					break;
				default: 
					break;
			}
		}
		
		private function playStartHlr():void
		{
			if (!_start_play)
			{
				netStream.pause();
			}
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
				curLoadingTimeout = setTimeout(onVideoLoadingTimeoutHlr, LOADING_TIMEOUT_VALUE);
			}
			dispatch(EVENT_LOAD_SUCCESS);
		}
		
		private function bufferEmptyHlr():void
		{
			if (!isFirstBufferFull)
				return;
			
			if (loadSize < totalSize) //卡
			{
				_playing = false;
				dispatch(EVENT_PLAY_BUFFER_EMPTY);
			}
		}
		
		private function bufferFullHlr():void
		{
			if (!visible)
				visible = true;
			if (!isFirstBufferFull)
			{
				isFirstBufferFull = true;
			}
			_playing = true;
			dispatch(EVENT_PLAY_BUFFER_FULL);
		}
		
		private function completeHlr():void
		{
			_playing = false;
			_play_end = true;
			dispatch(EVENT_PLAY_COMPLETE);
		}
		
		private function errorHlr():void
		{
			_playing = false;
			removeLoadTimer();
			dispatch(EVENT_LOAD_ERROR);
		}
		
		private function onVideoTimeOutHlr():void
		{
			_playing = false;
			removeLoadTimer();
			dispatch(EVENT_LOAD_TIMEOUT);
		}
		
		private function onVideoLoadingTimeoutHlr():void
		{
			onVideoTimeOutHlr();
		}
		
		private function playTimerHandler(event:TimerEvent):void
		{
			if (totalTime == 0)
				return;
			if (!_start_play)
				return;
			if (!_playing)
				return;
			dispatch(EVENT_PLAY_PROGRESS);
		}
		
		private function loadTimerHandler(event:TimerEvent):void
		{
			if (!netStream)
				return;
			if (!netStream.bytesTotal)
				return;
			if (netStream.bytesLoaded < netStream.bytesTotal)
			{
				dispatch(EVENT_LOAD_PROGRESS);
			}
			else
			{
				isLoadComplete = true;
				removeLoadTimer();
				dispatch(EVENT_LOAD_COMPLETE);
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
				netStream.play(url);
				
				playTimer.start();
				loadTimer.start();
				
				if (curConnectTimeout > 0)
				{
					clearTimeout(curConnectTimeout);
				}
				if (CONNECT_TIMEOUT_VALUE > 0)
				{
					curConnectTimeout = setTimeout(onVideoTimeOutHlr, CONNECT_TIMEOUT_VALUE);
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
			if (_play_end)
			{
				replay();
			}
			else
			{
				_playing = true;
				netStream.resume();
			}
		}
		
		public function pause():void
		{
			if (playTimer && playTimer.running)
				playTimer.stop();
			_playing = false;
			netStream.pause();
		}
		
		public function seek(time:Number):void
		{
			if (totalTime > 0 && time >= totalTime)
			{
				return;
			}
			if (time < 0)
				time = 0;
			if (netStream)
			{
				_playing = true;
				_play_end = false;
				netStream.seek(time);
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
			removeEventListener(MouseEvent.CLICK, onCickHlr);
			
			removeLoadTimer();
			removePlayTimer();
		}
		
		public function resize(w:Number, h:Number):void
		{
			setWidthHeight(w, h);
			
			refresh();
		}
		
		public function getSnapshot(flag:Boolean = true):BitmapData
		{
			var snapshotBd:BitmapData;
			if (flag)
			{
				try
				{
					snapshotBd = new BitmapData(background.width, background.height, true, 0x000000);
					snapshotBd.draw(this, null, null, null, null, true);
				}
				catch (error:Error)
				{
					snapshotBd = null;
				}
			}
			else
			{
				try
				{
					snapshotBd = new BitmapData(video.width, video.height, true, 0x000000);
					snapshotBd.draw(this, new Matrix(1, 0, 0, 1, -video.x, -video.y), null, null, null, true);
				}
				catch (error:Error)
				{
					snapshotBd = null;
				}
			}
			return snapshotBd;
		}
		
		public function get loadSize():Number
		{
			if (netStream)
				return netStream.bytesLoaded;
			else
				return 0;
		}
		
		public function get totalSize():Number
		{
			if (_metaData)
				return _metaData.totalSize;
			else if (netStream)
				return netStream.bytesTotal;
			else
				return 0;
		}
		
		public function get playTime():Number
		{
			if (netStream)
				return netStream.time;
			else
				return 0;
		}
		
		public function get totalTime():Number
		{
			return _metaData ? _metaData.totalTime : 0;
		}
		
		public function get metaData():MetaData
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
				setStreamVolume(0);
			else
				setStreamVolume(_volume);
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
			setStreamVolume(_volume);
		}
		
		public function get volume():Number
		{
			return _volume;
		}
	}
}

class MetaData
{
	private static const FILE_SIZE_TAG_NAME:String = "filesize";
	private static const VIDEO_DURATION_TAG_NAME:String = "duration";
	private static const VIDEO_WIDTH_TAG_NAME:String = "width";
	private static const VIDEO_HEIGHT_TAG_NAME:String = "height";
	private var data:Object;
	private var fileSize:Number = 0;
	private var duration:Number = 0;
	private var videoWidth:Number = 400;
	private var videoHeight:Number = 300;
	
	public function MetaData(metadata:Object)
	{
		if (metadata == null)
		{
			trace("MetaData is NULL!");
			return;
		}
		this.data = metadata;
		if (data.hasOwnProperty(VIDEO_WIDTH_TAG_NAME))
		{
			videoWidth = Number(data[VIDEO_WIDTH_TAG_NAME]);
		}
		if (data.hasOwnProperty(VIDEO_HEIGHT_TAG_NAME))
		{
			videoHeight = Number(data[VIDEO_HEIGHT_TAG_NAME]);
		}
		if (data.hasOwnProperty(VIDEO_DURATION_TAG_NAME))
		{
			duration = Number(data[VIDEO_DURATION_TAG_NAME]);
		}
		if (data.hasOwnProperty(FILE_SIZE_TAG_NAME))
		{
			fileSize = Math.max(Number(data[FILE_SIZE_TAG_NAME]), 0);
		}
	}
	
	public function get totalSize():Number
	{
		return fileSize;
	}
	
	public function get totalTime():Number
	{
		return duration;
	}
	
	public function get width():Number
	{
		return videoWidth;
	}
	
	public function get height():Number
	{
		return videoHeight;
	}
}
