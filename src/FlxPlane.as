package
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.flixel.*;
	
	public class FlxPlane
	{
		private static var player:Player;
		private static var viewport:FlxSprite;
		private static var map:Map;
		private static var vertexMapX:Dictionary;
		private static var vertexMapY:Dictionary;
		
		private static var _centerPoint:FlxPoint = new FlxPoint();
		protected var _pt0:FlxPoint;
		protected var _pt1:FlxPoint;
		protected var _pt2:FlxPoint;
		protected var _pt3:FlxPoint;
		private var _point:FlxPoint;
		public var uv:Rectangle;
		
		public var posX:uint;
		public var posY:uint;
		public var face:uint;
		
		protected var _t0:Number;
		protected var _t1:Number;
		protected var _t2:Number;
		protected var _t3:Number;
		protected var _w:Number;
		protected var _intersect:FlxPoint;
						
		public function FlxPlane(X:uint, Y:uint, Face:uint)
		{
			_pt0 = new FlxPoint();
			_pt1 = new FlxPoint();
			_pt2 = new FlxPoint();
			_pt3 = new FlxPoint();
			_point = null;
			_intersect = null;
			
			posX = X;
			posY = Y;
			face = Face;

			uv = new Rectangle();
			_t0 = _t1 = _t2 = _t3 = 0;
			_w = 0;
		}
		
		public function assignVertices(Pt0:FlxPoint, Pt1:FlxPoint, Pt2:FlxPoint, Pt3:FlxPoint):void
		{
			_pt0 = Pt0;
			_pt1 = Pt1;
			_pt2 = Pt2;
			_pt3 = Pt3;
			
			_point = intersect;
			if (_point == null) return;

			// Lengths of first diagonal		
			var ll1:Number = FlxU.getDistance(_pt0, _point);
			var ll2:Number = FlxU.getDistance(_point, _pt3);
			
			// Lengths of second diagonal		
			var lr1:Number = FlxU.getDistance(_pt1, _point);
			var lr2:Number = FlxU.getDistance(_point, _pt2);
			
			// Ratio between diagonals
			var f:Number = (ll1 + ll2) / (lr1 + lr2);
			
			_t0 = (1/ll2) * f;
			_t1 = (1/lr2);
			_t2 = (1/lr1);
			_t3 = (1/ll1) * f;
		}
		
		/**
		 * Projects a point in 3d (x, y, z) map space to a point in 2d (x, y) screen space, relative to the Player.
		 * 
		 * @param	SourceX				The x-coordinate in map space of the point to be projected.
		 * @param	SourceY				The y-coordinate in map space of the point to be projected.
		 * @param	SourceZ				The z-coordinate in map space of the point to be projected.
		 * @param	DestinationPoint	The point used to store the screen coordinates after projection.
		 * 
		 * @return	The distance in tile units from the player to the point.
		 */
		public function getScreenCoordinates(SourceX:Number, SourceY:Number, SourceZ:Number, DestinationPoint:FlxPoint):Number
		{			
			var planeX:Number = 0.66 * player.view.x;
			var planeY:Number = 0.66 * player.view.y;
			var invDet:Number = 1.0 / (planeX * player.dir.y - player.dir.x * planeY);
			
			var _x:Number = SourceX - player.pos.x;
			var _y:Number = SourceY - player.pos.y;
			
			var transformX:Number = invDet * (player.dir.y * _x - player.dir.x * _y);
			var transformY:Number = invDet * (-planeY * _x + planeX * _y); //this is actually the depth inside the screen, that what Z is in 3D       
			var _height:Number = viewport.height / transformY;
			//entity.visible = (transformY > 0);
			if (transformY > 0)
			{
				DestinationPoint.x = int((0.5 * viewport.width) * (1 + transformX / transformY));
				DestinationPoint.y = 0.5 * viewport.height;
				if (SourceZ == 0) DestinationPoint.y += 0.5 * _height * map.texHeight;
				else if (SourceZ == 128) DestinationPoint.y -= 0.5 * _height * map.texHeight;
				return 1 / _height;
			}
			else 
			{
				return -1;
			}
		}
		
		public function drawPlane(gr:Graphics, bmp:BitmapData):void
		{
			_point = intersect;
			if (_point == null) return;
			
			// Lengths of first diagonal		
			var ll1:Number = FlxU.getDistance(pt0, _point);
			var ll2:Number = FlxU.getDistance(_point, pt3);
			
			// Lengths of second diagonal		
			var lr1:Number = FlxU.getDistance(pt1, _point);
			var lr2:Number = FlxU.getDistance(_point, pt2);
			
			// Ratio between diagonals
			var f:Number = (ll1 + ll2) / (lr1 + lr2);
			
			// Draws the triangle
			gr.beginBitmapFill(bmp, null, false, false);
			gr.drawTriangles(	Vector.<Number>([pt0.x, pt0.y, pt1.x, pt1.y, pt2.x, pt2.y, pt3.x, pt3.y]),
				Vector.<int>([0,1,2, 1,3,2]), Vector.<Number>([
				uv.x, uv.y, t0,		uv.width, uv.y, t1,		uv.x, uv.height, t2,	uv.width, uv.height, t3	]));
		}
		
		/**
		 * Get the <code>intersect</code> of the diagonals between the four courners of the <code>FlxPlane</code>.
		 */
		public function get intersect():FlxPoint
		{
			// Returns a point containing the intersection between two lines
			// http://keith-hair.net/blog/2008/08/04/find-intersection-point-of-two-lines-in-as3/
			// http://www.gamedev.pastebin.com/f49a054c1
			
			var a1:Number = pt3.y - pt0.y;
			var b1:Number = pt0.x - pt3.x;
			var a2:Number = pt1.y - pt2.y;
			var b2:Number = pt2.x - pt1.x;
			
			var denom:Number = a1 * b2 - a2 * b1;
			if (denom == 0) return null;
			
			var c1:Number = pt3.x * pt0.y - pt0.x * pt3.y;
			var c2:Number = pt1.x * pt2.y - pt2.x * pt1.y;
			
			_intersect = new FlxPoint((b1 * c2 - b2 * c1)/denom, (a2 * c1 - a1 * c2)/denom);
			
			if (FlxU.getDistance(_intersect, pt3) > FlxU.getDistance(pt0, pt3)) return null;
			if (FlxU.getDistance(_intersect, pt0) > FlxU.getDistance(pt0, pt3)) return null;
			if (FlxU.getDistance(_intersect, pt1) > FlxU.getDistance(pt2, pt1)) return null;
			if (FlxU.getDistance(_intersect, pt2) > FlxU.getDistance(pt2, pt1)) return null;
			
			return _intersect;
		}
		
		private function get pt0():FlxPoint
		{
			return _pt0;
		}
		
		private function get pt1():FlxPoint
		{
			return _pt1;
		}
		
		private function get pt2():FlxPoint
		{
			return _pt2;
		}
		
		private function get pt3():FlxPoint
		{
			return _pt3;
		}
		
		private function get t0():FlxPoint
		{
			return _t0;
		}
		
		private function get t1():FlxPoint
		{
			return _t1;
		}
		
		private function get t2():FlxPoint
		{
			return _t2;
		}
		
		private function get t3():FlxPoint
		{
			return _t3;
		}
	}
}