package
{
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
	import org.flixel.*;
	
	public class Entity extends FlxSprite
	{
		[Embed(source="../assets/images/FlixelFPS_Spritemap.png")] protected static var imgSprites:Class;
		
		public static const TIPPYTOES:uint = 0;
		public static const ORB_RED:uint = 1;
		public static const ORB_GREEN:uint = 1;
		public static const ORB_BLUE:uint = 1;
		
		protected var _pos:FlxPoint;
		public var target:Player;
		
		public var distance:Number = 0;
		public var viewPos:FlxPoint;
		public var clipRect:Rectangle;
		public var moveSpeed:Number;
		public var timer:FlxTimer;
		public var type:uint;
		//public var posZ:Number = 0; //0 means the bottom of the sprite rests on the ground
		
		public function Entity(X:Number = 22, Y:Number = 12.5, Type:uint = 0)
		{
			super(X, Y);
			
			loadGraphic(imgSprites, true, false, 128, 128);
			addAnimation("orb", [130, 131, 132, 131], 4, true);
			addAnimation("tippytoes_walk", [110, 111], 4, true);
			addAnimation("tippytoes_idle", [111]);
			addAnimation("tippytoes_die", [112, 113], 1, false);
			
			type = Type;
			width = 48;
			height = 48;
			solid = true;
			elasticity = 0;
			
			_pos = new FlxPoint(0, 0);
			viewPos = new FlxPoint(0, 0);
			clipRect = new Rectangle(0, 0, frameWidth, frameHeight);
			timer = new FlxTimer();
			moveSpeed = 9 * 128;
			drag.x = drag.y = 48 * 128;
			
			x = X * 128 + width / 2;
			y = Y * 128 + height / 2;
			
			if (type == TIPPYTOES)
			{
				color = 0xe4edb3;
				play("tippytoes_idle");
				timer.start(0.25 * FlxG.random(), 1, onTimerMove);
			}
			else 
			{
				color = 0xff0000;
				play("orb");
			}
		}
		
		public function onTimerMove(Timer:FlxTimer):void
		{
			Timer.start(0.25, 1, onTimerMove);
			if (target == null) return;
			if (FlxU.getDistance(pos, target.pos) < 128 * 8)
			{
				play("tippytoes_walk");
				var _ang:Number = FlxU.getAngle(pos, target.pos) + 270;
				if (_curFrame == 1) _ang -= 20;
				else _ang += 20;
				_ang = toRadians(_ang);
				velocity.x = moveSpeed * Math.cos(_ang);
				velocity.y = moveSpeed * Math.sin(_ang);
			}
			else play("tippytoes_idle");
		}
		
		public function hitsPlayer(Target:Player):void
		{
			if (FlxObject.separateX(this, Target)) 
			{
				velocity.x = 0;
				x = last.x;
				Target.velocity.x = 0;
				Target.x = Target.last.x;
			}
			if (FlxObject.separateY(this, Target)) 
			{
				velocity.y = 0;
				y = last.y;
				Target.velocity.y = 0;
				Target.y = Target.last.y;
			}
		}
		
		public function hitsEntity(Target:Entity):void
		{
			
		}
		
		public function toRadians(Degrees:Number):Number
		{
			var _rad:Number = Math.abs((Degrees + 360) % 360) % 360;
			return _rad * (Math.PI / 180);
		}
		
		override public function update():void
		{
			if (FlxG.keys.pressed("UP")) velocity.y = -moveSpeed;
			else if (FlxG.keys.pressed("DOWN")) velocity.y = moveSpeed;
			
			if (FlxG.keys.pressed("LEFT")) velocity.x = -moveSpeed;
			else if (FlxG.keys.pressed("RIGHT")) velocity.x = moveSpeed;
		}
		
		override public function draw():void
		{
			if (distance == -1) return;
			var _xx:Number = viewPos.x - frameWidth / 2;
			var _yy:Number = viewPos.y - frameHeight / 2;
			
			if(_flickerTimer != 0)
			{
				_flicker = !_flicker;
				if(_flicker)
					return;
			}
			
			if(dirty)	//rarely 
				calcFrame();
			
			if(cameras == null)
				cameras = FlxG.cameras;
			var camera:FlxCamera;
			var i:uint = 0;
			var l:uint = cameras.length;
			while(i < l)
			{
				camera = cameras[i++];
				//if(!onScreen(camera))
				//	continue;
				_point.x = _xx - offset.x;
				_point.y = _yy - offset.y;
				_point.x += (_point.x > 0)?0.0000001:-0.0000001;
				_point.y += (_point.y > 0)?0.0000001:-0.0000001;
				if(((angle == 0) || (_bakedRotation > 0)) && (scale.x == 1) && (scale.y == 1) && (blend == null)) //&& (skew.x == 0) && (skew.y == 0)
				{	//Simple render
					_flashPoint.x = _point.x;
					_flashPoint.y = _point.y;
					camera.buffer.copyPixels(framePixels,_flashRect,_flashPoint,null,null,true);
				}
				else
				{	//Advanced render
					_matrix.identity();
					//_matrix.concat(new flash.geom.Matrix(1, skew.y, skew.x, 1, 0, 0));//***
					_matrix.translate(-origin.x,-origin.y);
					_matrix.scale(scale.x,scale.y);
					if((angle != 0) && (_bakedRotation <= 0))
						_matrix.rotate(angle * 0.017453293);
					_matrix.translate(_point.x+origin.x,_point.y+origin.y);
					camera.buffer.draw(framePixels,_matrix,null,blend,clipRect,antialiasing);
				}
				//_VISIBLECOUNT++;
				if(FlxG.visualDebug && !ignoreDrawDebug)
					drawDebug(camera);
			}
		}
		
		public function get pos():FlxPoint
		{
			_pos.x = x + width / 2;
			_pos.y = y + height / 2;
			return _pos;
		}
		
		public function light(LightLevel:uint):void
		{
			var _light:Number = LightLevel;
			if (distance >= 8) _light -= int(0.5 * (distance - 6));
			if (_light < 2) _light = 2;
			else if (_light > 10) _light = 10;
			_light /= Map.LIGHT_LEVELS;
			var _red:uint;
			var _green:uint;
			var _blue:uint;
			
			if (type == TIPPYTOES)
			{
				_red = 228 * _light;
				_green = 237 * _light;
				_blue = 179 * _light;
				color = (_red << 16) + (_green << 8) + _blue;
			}
			else if (type == ORB_RED)
			{
				_red = 255 * _light;
				_green = 0 * _light;
				_blue = 0 * _light;
				color = (_red << 16) + (_green << 8) + _blue;
			}
			else if (type == ORB_GREEN)
			{
				_red = 0 * _light
				_green = 255 * _light;
				_blue = 0 * _light;
				color = (_red << 16) + (_green << 8) + _blue;
			}
			else if (type == ORB_BLUE)
			{
				_red = 0 * _light
				_green = 0 * _light;
				_blue = 255 * _light;
				color = (_red << 16) + (_green << 8) + _blue;
			}
		}
	}
}