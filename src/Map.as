package
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.flixel.*;
	
	public class Map extends FlxTilemap
	{
		public static const FLOOR:uint = 0;
		public static const NORTH:uint = 1;
		public static const EAST:uint = 2;
		public static const SOUTH:uint = 3;
		public static const WEST:uint = 4;
		public static const CEILING:uint = 5;
		
		[Embed(source="../assets/images/FlixelFPS_Spritemap.png")] protected static var imgWalls:Class;
		[Embed(source="../assets/maps/testMap.csv", mimeType = "application/octet-stream")] protected var mapLevel1:Class;
		
		public var textures:FlxSprite;
		public var texWidth:Number = 128;
		public var texHeight:Number = 128;
		
		public var mapWidth:uint = 24;
		public var mapHeight:uint = 24;
		
		public var vismap:Dictionary;
		public var orderTree:Dictionary;
		public var vertexMapX:Dictionary;
		public var vertexMapY:Dictionary;
				
		public function Map(Canvas:Sprite, Plyr:Player)
		{
			super();
			
			loadMap(new mapLevel1, imgWalls, texWidth, texHeight, FlxTilemap.OFF, 0, 1, 1);
			
			textures = new FlxSprite();
			textures.loadGraphic(imgWalls);
			//visible = false;
			FlxG.worldBounds.make(0, 0, width, height);
			
			vismap = new Dictionary();
			orderTree = new Dictionary();
			vertexMapX = new Dictionary();
			vertexMapY = new Dictionary();
		}
		
		override public function update():void
		{
			super.update();
			
			visible = FlxG.visualDebug;
			//planes.sort(sortByDistance);
		}
		
		override public function draw():void
		{
			super.draw();
		}
	}
}