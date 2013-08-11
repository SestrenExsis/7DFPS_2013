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
			
			x = X * 128 - width / 2;
			y = Y * 128 - height / 2;
			
			viewPos = new FlxPoint(0, 0);
			clipRect = new Rectangle(0, 0, width, height);
			
			loadGraphic(imgSprites, true, false, 128, 128);
			addAnimation("orb", [21]);
			play("orb");
			FlxG.watch(clipRect, "x");
			FlxG.watch(clipRect, "width");
			FlxG.watch(this, "distance");
			FlxG.watch(this, "visible");
		}
		
		override public function draw():void
		{
			clipRect.x = 0;
			clipRect.width = 128;
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
		
		/*override protected function calcFrame():void
		{
			super.calcFrame();
			var indexX:uint = _curIndex*frameWidth;
			var indexY:uint = 0;
			
			//Handle sprite sheets
			var widthHelper:uint = _flipped?_flipped:_pixels.width;
			if(indexX >= widthHelper)
			{
				indexY = uint(indexX/widthHelper)*frameHeight;
				indexX %= widthHelper;
			}
			//handle reversed sprites
			//if(_flipped && (_facing == LEFT)) indexX = (_flipped<<1)-indexX-frameWidth;
			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = width;
			_flashRect.height = height;
			framePixels.fillRect(_flashRect, 0x00000000);
			//Update display bitmap
			_flashRect.x = indexX + leftClip;
			_flashRect.y = indexY;//
			_flashRect.width = width - leftClip;// - rightClip;
			_flashPoint.x = leftClip;
			_flashPoint.y = 0;
			framePixels.copyPixels(_pixels,_flashRect,_flashPoint);
			_flashRect.x = _flashRect.y = 0;
			if(_colorTransform != null)
				framePixels.colorTransform(_flashRect,_colorTransform);
			if(_callback != null)
				_callback(((_curAnim != null)?(_curAnim.name):null),_curFrame,_curIndex);
			dirty = false;
		}*/
		
		override public function update():void
		{
			super.update();
			
		}
	}
}