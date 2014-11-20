package  
{
	import flash.display.Stage;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.utils.Dictionary;
	
	public class ShortcutKeys extends EventDispatcher
	{
		public function ShortcutKeys(lock:Class = null)
		{
			if (lock != ConstructorLock)
			{
				throw new IllegalOperationError("ShortcutKeys 是单例模式，禁止实例化！!");
			}
			
			registered = { };
		}
		
		public static function getInstance(stage:Stage=null):ShortcutKeys
		{
			
			instance ||= new ShortcutKeys(ConstructorLock);
			
			if (stage)
			{
				instance._stage = stage;
				instance.enabled = true;
			}
			
			if (instance._stage == null)
			{
				throw new ArgumentError("快捷键未被注册使用, 获取实例时需要 stage 参数！！");
			}
			
			return instance;
		}
		
		private var defaultOptions:Object = 
			{ "type": "keyDown"
			, "disable_in_input": false
			, "keycode": false
			};
		
		//Shift+数字键 与 对应的字符
		private var shiftNums:Object = 
			{ "`":"~"
			, "1":"!"
			, "2":"@"
			, "3":"#"
			, "4":"$"
			, "5":"%"
			, "6":"^"
			, "7":"&"
			, "8":"*"
			, "9":"("
			, "0":")"
			, "-":"_"
			, "=":"+"
			, ";":":"
			, "'":"\""
			, ",":"<"
			, ".":">"
			, "/":"?"
			, "\\":"|"
			};
		
		//特殊键 和 对应的代码
		private var specialKeys:Object =
			{ "esc":27
			, "tab":9
			, "space":32
			, "enter":13
			, "backspace":8
			
			, "scrolllock":145
			, "capslock":20
			, "numlock":144
			, "break":19
			
			, "insert":45
			, "home":36
			, "delete":46
			, "end":35
			, "pageup":33
			, "pagedown":34
			
			, "left":37
			, "up":38
			, "right":39
			, "down":40
			
			, "f1":112
			, "f2":113
			, "f3":114
			, "f4":115
			, "f5":116
			, "f6":117
			, "f7":118
			, "f8":119
			, "f9":120
			, "f10":121
			, "f11":122
			, "f12":123
			};
		
		private function keyDown(evt:KeyboardEvent):void
		{
			var code:uint = evt.keyCode;
			var character:String = String.fromCharCode(code).toLowerCase();
			
			for (var key:String in specialKeys)
			{
				if (code == specialKeys[key]) character = key;
			}
			
			if (registered.hasOwnProperty(character))
			{
				registered[character]();
			}
			else {
				for (var shortcut:String in registered)
				{
					var keys:Array = shortcut.split("+");
					var k:String;
					var kp:int = 0;
					
					var modifiers:Object = 
					{ shift: { wanted:false, pressed:false }
					, ctrl : { wanted:false, pressed:false }
					, alt  : { wanted:false, pressed:false }
					};
						
					if (evt.ctrlKey) modifiers.ctrl.pressed = true;
					if (evt.shiftKey) modifiers.shift.pressed = true;
					if (evt.altKey) modifiers.alt.pressed = true;
					
					for (var i:int = 0; i < keys.length; i++)
					{
						k = keys[i];
						if(k == 'ctrl' || k == 'control') {
							kp++;
							modifiers.ctrl.wanted = true;
						}
						else if(k == 'shift') {
							kp++;
							modifiers.shift.wanted = true;
						}
						else if(k == 'alt') {
							kp++;
							modifiers.alt.wanted = true;
						}
						else {
							if(character == k) kp++;
						}
					}
					
					if ( kp == keys.length
						&& modifiers.ctrl.pressed == modifiers.ctrl.wanted
						&& modifiers.shift.pressed == modifiers.shift.wanted
						&& modifiers.alt.pressed == modifiers.alt.wanted
						)
					{
						registered[shortcut]();
					}
				}
			}
		}
		
		public function add(keys:String, callback:Function):void
		{
			var shortcut:String = keys.toLowerCase();
			
			if (!registered.hasOwnProperty(shortcut)) num++;
			
			registered[shortcut] = callback;
		}
		
		/**
		 * 删除快捷键
		 * 
		 * @param	keys:String 快捷键的字符
		 */
		public function remove(keys:String):void
		{
			var shortcut:String = keys.toLowerCase();
			
			if (registered.hasOwnProperty(shortcut))
			{
				delete registered[shortcut];
				num--;
			}
		}
		
		protected function processEnabledChange():void
		{
			if (enabled)
			{
				_stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown, false, 0, true);
			}
			else {
				_stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
			}
		}
		
		public function set enabled(value:Boolean):void
		{
			_enabled = value;
			processEnabledChange();
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		override public function toString():String
		{
			var str:String = "";
			
			for (var key:String in registered)
			{
				str += key + " -> " + registered[key].type+"\n";
			}
			return str;
		}
		
		private static var instance:ShortcutKeys;
		private var _enabled:Boolean = true;
		private var _stage:Stage;
		
		private var registered:Object;
		private var num:int;
	}

}

class ConstructorLock {};