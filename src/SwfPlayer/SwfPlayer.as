package
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.Timer;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	/**
	 * support swf/jpg/png
	 */
	public class SwfPlayer extends Sprite
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
		
		private static const PLAYER_CLOCK:Number = 250;
		private static const LOADING_TIMEOUT_VALUE:Number = 4000;
		
		private var _playURL:String;
		private var _start_play:Boolean = false;
		
		private var background:Shape;
		private var loader:Loader;
		private var primary:DisplayObject;
		private var primaryWW:Number;
		private var primaryHH:Number;
		
		private var playTimer:Timer;
		private var loadTimer:Timer;
		
		private var curLoadingTimeOut:Number;
		
		public function SwfPlayer(ww:Number = 400, hh:Number = 300)
		{
			var thisMask:DisplayObject = getShape(ww, hh, 0x000000, 0.6);
			this.mask = thisMask;
			addChild(thisMask);
			
			background = getShape(ww, hh, 0x000000, 0);
			addChild(background);
			
			if (!loadTimer)
			{
				loadTimer = new Timer(PLAYER_CLOCK);
				loadTimer.addEventListener(TimerEvent.TIMER, onLoadTimerHlr);
			}
			
			if (!playTimer)
			{
				playTimer = new Timer(PLAYER_CLOCK);
				playTimer.addEventListener(TimerEvent.TIMER, onPlayTimerHlr);
			}
			
			addEventListener(MouseEvent.CLICK, onAdClickHlr);
			
			visible = false;
			buttonMode = true;
			
			curLoadingTimeOut = 0;
			
			loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHlr);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, errorHlr);
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
		
		private function onLoadTimerHlr(e:TimerEvent):void
		{
			dispatch(EVENT_LOAD_PROGRESS);
		}
		
		private function onPlayTimerHlr(e:TimerEvent):void
		{
			dispatch(EVENT_PLAY_PROGRESS);
		}
		
		private function completeHlr(e:Event):void
		{
			if (curLoadingTimeOut > 0)
			{
				clearTimeout(curLoadingTimeOut);
			}
			loadTimer.reset();
			
			primary = loader;
			try
			{
				primaryWW = loader.contentLoaderInfo.width;
				primaryHH = loader.contentLoaderInfo.height;
			}
			catch (e:Error)
			{
				primaryWW = width;
				primaryHH = height;
			}
			dispatch(EVENT_LOAD_SUCCESS);
			dispatch(EVENT_LOAD_COMPLETE);
			dispatch(EVENT_METADATA);
			
			if (_start_play && !contains(primary))
			{
				play();
			}
		}
		
		private function errorHlr(e:IOErrorEvent):void
		{
			if (curLoadingTimeOut > 0)
			{
				clearTimeout(curLoadingTimeOut);
			}
			
			dispatch(EVENT_LOAD_ERROR);
		}
		
		private function onSwfTimeOutHlr():void
		{
			if (curLoadingTimeOut > 0)
			{
				clearTimeout(curLoadingTimeOut);
			}
			
			if (loadTimer)
				loadTimer.reset();
			dispatch(EVENT_LOAD_TIMEOUT);
		}
		
		private function onAdClickHlr(e:MouseEvent):void
		{
			dispatch(EVENT_CLICK);
		}
		
		private function refresh():void
		{
			if (!primary)
				return;
			var primaryAspectRatio:Number = primaryWW / primaryHH;
			var containerAspectRatio:Number = mask.width / mask.height;
			
			var scale:Number = 1;
			if (containerAspectRatio > primaryAspectRatio)
			{
				scale = mask.height / primaryHH;
			}
			else
			{
				scale = mask.width / primaryWW;
			}
			primary.scaleX = primary.scaleY = scale;
			primary.x = (mask.width - primaryWW * scale) / 2;
			primary.y = (mask.height - primaryHH * scale) / 2;
		}
		
		private function dispatch(eventType:String):void
		{
			dispatchEvent(new Event(eventType));
		}
		
		public function load(url:String):void
		{
			if (!url || url == "")
			{
				errorHlr(null);
			}
			
			_playURL = url;
			
			loadTimer.reset();
			loadTimer.start();
			
			loader.load(new URLRequest(url), new LoaderContext(true));
			dispatch(EVENT_LOAD_START);
			
			if (curLoadingTimeOut > 0)
			{
				clearTimeout(curLoadingTimeOut);
			}
			curLoadingTimeOut = setTimeout(onSwfTimeOutHlr, LOADING_TIMEOUT_VALUE);
		}
		
		public function play():void
		{
			_start_play = true;
			if (primary && !contains(primary))
			{
				addChild(primary);
				refresh();
				visible = true;
				
				playTimer.reset();
				playTimer.start();
				
				dispatch(EVENT_PLAY_START);
				dispatch(EVENT_PLAY_BUFFER_FULL);
			}
			else
			{
				
			}
		}
		
		public function pause():void
		{
			if (primary)
			{
				if (playTimer)
					playTimer.stop();
				primary.visible = false;
			}
		}
		
		public function resume():void
		{
			if (primary)
			{
				if (playTimer)
					playTimer.start();
				primary.visible = true;
			}
		}
		
		public function seek(time:Number):void
		{
		
		}
		
		public function replay():void
		{
			destroy();
			
			load(_playURL);
		}
		
		public function destroy():void
		{
			visible = false;
			
			if (primary)
			{
				if (contains(primary))
					removeChild(primary);
				primary = null;
			}
		}
		
		public function resize(ww:Number, hh:Number):void
		{
			mask.width = ww;
			mask.height = hh;
			background.width = ww;
			background.height = hh;
			
			refresh();
		}
		
		public function getSnapshot(flag:Boolean = true):BitmapData
		{
			var snapshotBd:BitmapData;
			if (flag)
			{
				try
				{
					snapshotBd = new BitmapData(width, height, true, 0x000000);
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
					snapshotBd = new BitmapData(primary.width, primary.height, true, 0x000000);
					snapshotBd.draw(this, new Matrix(1, 0, 0, 1, -primary.x, -primary.y), null, null, null, true);
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
			return loader.contentLoaderInfo.bytesLoaded;
		}
		
		public function get totalSize():Number
		{
			return loader.contentLoaderInfo.bytesTotal;
		}
		
		public function get playTime():Number
		{
			return PLAYER_CLOCK * playTimer.currentCount / 1000;
		}
		
		public function get totalTime():Number
		{
			return -1;
		}
		
		public function get metaData():Object
		{
			return null;
		}
		
		public function get playing():Boolean
		{
			if (primary && primary.visible)
				return true;
			else
				return false;
		}
		
		public function set mute(value:Boolean):void
		{
		}
		
		public function get mute():Boolean
		{
			return false;
		}
		
		public function get volume():Number
		{
			return 0;
		}
		
		public function set volume(value:Number):void
		{
		
		}
	}

}