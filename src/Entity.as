package
{
	import flash.display.Graphics;
	import flash.geom.Rectangle;
	
	import org.flixel.*;
	
	public class Entity extends FlxSprite
	{
		[Embed(source="../assets/images/FlixelFPS_Spritemap.png")] protected static var imgSprites:Class;
		
		public var distance:Number = 0;
		public var viewPos:FlxPoint;
		public var clipRect:Rectangle;
		//public var posZ:Number = 0; //0 means the bottom of the sprite rests on the ground
		
		public function Entity(X:Number = 22, Y:Number = 12.5)
		{
			super(X, Y);
						
			width = 128;
			height = 128;
			
			x = X * 128 + width / 2;
			y = Y * 128 + height / 2;
			
			viewPos = new FlxPoint(0, 0);
			clipRect = new Rectangle(0, 0, width, height);
			
			loadGraphic(imgSprites, true, false, 128, 128);
			addAnimation("orb", [21]);
			play("orb");
		}
		
		override public function update():void
		{
			if (FlxG.keys.pressed("UP")) 
			{
				if (FlxG.keys.pressed("SHIFT")) y -= 1;
				else y -= 8;
			}
			else if (FlxG.keys.pressed("DOWN"))
			{
				if (FlxG.keys.pressed("SHIFT")) y += 1;
				else y += 8;
			}
			
			if (FlxG.keys.pressed("LEFT"))
			{
				if (FlxG.keys.pressed("SHIFT")) x -= 1;
				else x -= 8;
			}
			else if (FlxG.keys.pressed("RIGHT"))
			{
				if (FlxG.keys.pressed("SHIFT")) x += 1;
				else x += 8;
			}
		}
		
		override public function draw():void
		{
			//super.draw();
			if (distance == -1) return;
			var _xx:Number = viewPos.x - width / 2;
			var _yy:Number = viewPos.y - height / 2;
			
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
	}
}