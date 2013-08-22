package
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import org.flixel.*;
	import org.flixel.system.FlxTile;
	
	public class GameState extends ScreenState
	{
		[Embed(source="../assets/images/FlixelFPS_Spritemap.png")] protected static var imgWalls:Class;
		[Embed(source="../assets/images/FlixelFPS_FirstPerson.png")] protected static var imgPOV:Class;
		
		private static var zoomLevel:Number = 1;
		
		private var sourceRect:Rectangle;
		private var floorSourceRect:Rectangle;
		private var destRect:Rectangle;
		private var ceilingRect:Rectangle;
		private var floorRect:Rectangle;
		private var oldSourceX:Number;
		
		private var debugState:uint = 0;
		
		private var player:Player;
		private var map:Map;
		private var entities:FlxGroup;
		private var entity:Entity;
		private var meta:FlxGroup;
		private var playerSprite:FlxSprite;
		
		//for drawing triangles
		private var canvas:Sprite;
		private var pt0:FlxPoint;
		private var pt1:FlxPoint;
		private var pt2:FlxPoint;
		private var pt3:FlxPoint;
		private var floorPt0:FlxPoint;
		private var floorPt1:FlxPoint;
		private var floorPt2:FlxPoint;
		private var floorPt3:FlxPoint;
		private var uv:Rectangle;
		private var _point:FlxPoint;
		private var _pt:FlxPoint;
		protected var _intersect:FlxPoint;
		
		private var negative:int = 1;
		private var orderTreeMin:int = 0;
		private var orderTreeMax:int = 0;
		
		private var side:int;
		private var drawStart:uint;
		private var drawEnd:uint;
		private var lineHeight:uint;
		
		//texturing calculations
		private var texNum:uint;
		private var wallX:Number;
		
		private var showTriangleEdges:Boolean = false;
		private var useVertexDictionary:Boolean = true;
		private var aspectRatio:Number;
		private var maxRenderDistance:Number;
		
		private var zBuffer:Array;
		
		public function GameState()
		{
			super();
		}
		
		override public function create():void
		{
			super.create();
			
			viewport = new FlxSprite(0, 0);
			viewport.scrollFactor.make(0, 0);
			viewport.makeGraphic(FlxG.width, FlxG.height, 0xffff0000);
			aspectRatio = viewport.width / viewport.height;
			
			//for drawing triangles
			canvas = new Sprite();
			canvas.width = viewport.width;
			canvas.height = viewport.height;
			pt0 = new FlxPoint();
			pt1 = new FlxPoint();
			pt2 = new FlxPoint();
			pt3 = new FlxPoint();
			floorPt0 = new FlxPoint();
			floorPt1 = new FlxPoint();
			floorPt2 = new FlxPoint();
			floorPt3 = new FlxPoint();
			uv = new Rectangle();
			_point = new FlxPoint();
			_pt = new FlxPoint();
			_intersect = new FlxPoint();
			player = new Player();
			playerSprite = new FlxSprite();
			playerSprite.loadGraphic(imgPOV, true, false, 128, 128);
			playerSprite.addAnimation("cast", [0, 1], 1, false);
			playerSprite.addAnimation("idle", [0]);
			playerSprite.play("idle");
			playerSprite.scale.x = playerSprite.scale.y = 3;
			playerSprite.x = viewport.width - 192;
			playerSprite.y = viewport.height - 192;
			playerSprite.scrollFactor.x = playerSprite.scrollFactor.y = 0;
			
			FlxG.camera.follow(player);

			entities = new FlxGroup();
			for (var i:uint = 0; i < 100; i++)
			{
				entity = new Entity();
				entity.target = player;
				entities.add(entity);
			}
			
			for (i = 0; i < 6; i++)
			{
				entity = Entity(entities.getFirstAvailable(Entity));
				if (entity) 
				{
					entity.spawn(int(FlxG.random() * 48 * 128), int(FlxG.random() * 24 * 128), Entity.TIPPYTOES);
				}
			}
			
			map = new Map(canvas, player);
			sourceRect = new Rectangle(0, 0, map.uvWidth, map.uvHeight);
			floorSourceRect = new Rectangle(0, 0, map.uvWidth, map.uvHeight);
			destRect = new Rectangle(0, 0, 1, 0);
			ceilingRect = new Rectangle(0, 0, FlxG.width, FlxG.height / 2);
			floorRect = new Rectangle(0, FlxG.height / 2, FlxG.width, FlxG.height / 2);
			
			displayText = new FlxText(0, 0, FlxG.width, "");
			displayText.scrollFactor.make(0, 0);
			
			add(viewport);
			add(map);
			
			meta = new FlxGroup();
			meta.add(player);
			meta.add(entities);
			add(meta);
			
			add(displayText);
			add(playerSprite);

			zBuffer = new Array(viewport.width);
			maxRenderDistance = 30;
		}
		
		override public function update():void
		{	
			super.update();
			
			if (FlxG.keys.justPressed("SPACE"))
			{
				entity = Entity(entities.getFirstAvailable(Entity));
				if (entity) 
				{
					var _ammoSource:int = player.attack();
					if (_ammoSource == -1) return;
					entity.spawn(player.pos.x + player.dir.x * 64, player.pos.y + player.dir.y * 64, _ammoSource);
					entity.move(player.dir.x, player.dir.y);
				}
			}
						
			FlxG.overlap(meta, map, collideWithMap);
			FlxG.overlap(meta, meta, objectsCollide, circularCollisionCheck);
			
			viewport.fill(0xff000000);
			viewport.pixels.fillRect(ceilingRect, 0xff000000);
			viewport.pixels.fillRect(floorRect, 0xff000000);
			//displayText.text = "";
			if (FlxG.keys.justPressed("T")) showTriangleEdges = !showTriangleEdges;
			if (FlxG.keys.justPressed("Y")) 
			{
				useVertexDictionary = !useVertexDictionary;
			}
			drawViewWithFaces();
			displayText.text = player.health + "  " + player.armor + "  " + player.ammo;
		}
		
		private function objectsCollide(Object1:FlxObject, Object2:FlxObject):void
		{
			if (Object2 is Player) objectsCollide(Object2, Object1);
			
			if (Object1 is Player) (Object2 as Entity).hitsPlayer(Object1 as Player);
			else (Object2 as Entity).hitsEntity(Object1 as Entity);
		}
		
		private function collideWithMap(Object1:FlxObject, Object2:FlxObject):void
		{
			if (FlxObject.separate(Object1, Object2))
			{
				if (Object1 is Entity) (Object1 as Entity).hitsWall();
				else if (Object2 is Entity) (Object2 as Entity).hitsWall();
			}
		}
		
		private function circularCollisionCheck(Object1:FlxObject,Object2:FlxObject):Boolean
		{
			var _xx:Number = Object1.x + 0.5 * Object1.width - (Object2.x + 0.5 * Object2.width);
			var _yy:Number = Object1.y + 0.5 * Object1.height - (Object2.y + 0.5 * Object2.height);
			
			if (Math.sqrt(_xx * _xx + _yy * _yy) < 0.5 * (Object1.width + Object2.width)) return true;
			else return false;
		}
		
		private function drawViewWithFaces():void
		{
			map.vismap = new Dictionary();
			map.orderTree = new Dictionary();
			orderTreeMin = orderTreeMax = 0;
			canvas.graphics.clear();
			if (showTriangleEdges) canvas.graphics.lineStyle(1, 0x00ff00);
			else canvas.graphics.lineStyle();
			addFacesToBuffer(viewport.width);
			
			var _x:uint;
			var _y:uint;
			var _index:int;
			var _face:uint;
			for (var _order:int = orderTreeMin; _order <= orderTreeMax; _order++)
			{
				if (_order == 0) _order += 1;
				_index = map.orderTree[_order];
				_face = map.vismap[_index];
				if (_index < 0) _index *= -1;
				_x = _index % map.widthInTiles;
				_y = int(_index / map.widthInTiles);
				renderWall(_x, _y, _face);
			}

			renderEntities();
			viewport.pixels.draw(canvas);
		}
		
		private function addFacesToBuffer(SearchResolution:uint):void
		{
			//****************************************************************************
			// A lot of this code is borrowed from http://lodev.org/cgtutor/raycasting.html.
			// Many thanks to them for the great tutorial.
			//****************************************************************************
			
			//x-coordinate in camera space
			var cameraX:Number;
			//length of ray from current position to next x or y-side
			var sideDistX:Number;
			var sideDistY:Number;
			//length of ray from one x or y-side to next x or y-side
			var deltaDistX:Number;
			var deltaDistY:Number;
			var perpWallDist:Number;
			//what direction to step in x or y-direction (either +1 or -1)
			var stepX:int;
			var stepY:int;
			//var side:int; //was a NS or a EW wall hit?
			var lineHeight:int;
			var drawStart:int;
			var drawEnd:int;
			var texNum:int;
			//var wallX:Number; //where exactly the wall was hit
			var texX:Number;
			//var texY:int;
			var color:uint;
			var y:int;
			var playerPosX:Number;
			var playerPosY:Number;
			var tileX:int;
			var tileY:int;
			//used to combine strips for a drawTriangles() call
			var lastTileX:int = -1;
			var lastTileY:int = -1;
			var lastSide:int = -1;
			var lastWallDistance:Number;
			var wallDistance:Number;
			var _renderDistance:Number;
			var _distX:Number;
			var _distY:Number;
			
			playerPosX = player.pos.x / map.texWidth;
			playerPosY = player.pos.y / map.texHeight;
			
			for (var x:uint = 0; x < SearchResolution; x += 1)
			{
				cameraX = 2 * (x / SearchResolution) - 1;
				
				player.setRayDir(cameraX);
				
				//which box of the map we're in  
				tileX = int(playerPosX);
				tileY = int(playerPosY);
				
				//calculate length of ray from one x or y-side to next x or y-side
				deltaDistX = Math.sqrt(1 + (player.rayDir.y * player.rayDir.y) / (player.rayDir.x * player.rayDir.x));
				deltaDistY = Math.sqrt(1 + (player.rayDir.x * player.rayDir.x) / (player.rayDir.y * player.rayDir.y));
				
				//calculate step and initial sideDist
				if (player.rayDir.x < 0)
				{
					stepX = -1;
					sideDistX = (playerPosX - tileX) * deltaDistX;
				}
				else
				{
					stepX = 1;
					sideDistX = (tileX + 1.0 - playerPosX) * deltaDistX;
				}      
				if (player.rayDir.y < 0)
				{
					stepY = -1;
					sideDistY = (playerPosY - tileY) * deltaDistY;
				}
				else
				{
					stepY = 1;
					sideDistY = (tileY + 1.0 - playerPosY) * deltaDistY;
				}
				//perform DDA
				passedThroughTile(tileX, tileY);
				do {//jump to next map square, OR in x-direction, OR in y-direction
					if (sideDistX < sideDistY)
					{
						sideDistX += deltaDistX;
						tileX += stepX;
						side = 0;
						//if (stepX
					}
					else
					{
						sideDistY += deltaDistY;
						tileY += stepY;
						side = 1;
					}
					_distX = playerPosX - tileX;
					_distY = playerPosY - tileY;
					_renderDistance = Math.sqrt(_distX * _distX + _distY * _distY);
				} while (passedThroughTile(tileX, tileY) == 0 && _renderDistance < maxRenderDistance); //Check if ray has hit a wall
				
				if (_renderDistance <= maxRenderDistance)
				{
					if (side == 0) wallDistance = Math.abs((tileX - playerPosX + (1 - stepX) / 2) / player.rayDir.x);
					else wallDistance= Math.abs((tileY - playerPosY + (1 - stepY) / 2) / player.rayDir.y);
					zBuffer[x] = wallDistance;
					if (lastTileX != tileX || lastTileY != tileY || lastSide != side)
					{
						if (wallDistance < lastWallDistance)
						{
							orderTreeMax += 1;
							map.orderTree[orderTreeMax] = negative * (tileX + tileY * map.widthInTiles);
						}
						else
						{
							orderTreeMin -= 1;
							map.orderTree[orderTreeMin] = negative * (tileX + tileY * map.widthInTiles);
						}
						//FlxG.log(negative);
						lastWallDistance = wallDistance;
						lastTileX = tileX;
						lastTileY = tileY;
						lastSide = side;
					}
				}
				else zBuffer[x] = maxRenderDistance;
			}
		}
		
		public function passedThroughTile(TileX:uint, TileY:uint):uint
		{
			var _tile:uint = map.getTile(TileX, TileY);
			var _index:uint = TileX + TileY * map.widthInTiles;
			var _face:uint = 0;
			negative = 1;
			
			if (_tile == 0) //floor tile
			{
				var _tileX:int = (player.pos.x / map.texWidth);
				var _tileY:int = (player.pos.y / map.texHeight);
				_face = Map.FLOOR;
				if (map.vismap[_index] != _face) renderFloor(TileX, TileY, TileX + 1, TileY + 1, 2);
			}
			else //wall tile
			{
				if (side == 1) //north or south faces
				{
					negative = 1;
					if (player.rayDir.y < 0) _face = Map.SOUTH;
					else _face = Map.NORTH;
				}
				else //east or west faces
				{
					negative = -1;
					if (player.rayDir.x > 0) _face = Map.WEST;
					else _face = Map.EAST;
				}
			}
			map.vismap[negative * _index] = _face;
			return _tile;
		}
		
		private function renderFloor(StartTileX:Number, StartTileY:Number, EndTileX:Number, EndTileY:Number, IterationsLeft:uint = 2):void
		{
			var _pX:Number = player.pos.x / map.texWidth;
			var _pY:Number = player.pos.y / map.texHeight;
			var _tX:Number = 0.5 * (StartTileX + EndTileX);
			var _tY:Number = 0.5 * (StartTileY + EndTileY);
			
			var _tileDistance:Number = Math.sqrt((_pX - _tX) * (_pX - _tX) + (_pY - _tY) * (_pY - _tY));
			
			var _badPt0:Boolean = false;
			var _badPt1:Boolean = false;
			var _badPt2:Boolean = false;
			var _badPt3:Boolean = false;
			var _badPointExists:Boolean = false;
			var _ptDistance:Number = 0;
			var _closestGoodPt:int = -1;
			var _minDistance:Number = 10;
			var _offScreenCount:uint = 0;
			
			//distance to upper-left corner of tile
			_pt.x = StartTileX * map.texWidth;
			_pt.y = StartTileY * map.texHeight;
			_ptDistance = projectPointToScreen(_pt.x, _pt.y, 0, floorPt0)
			if (_ptDistance == -1) _badPt0 = _badPointExists = true;
			else if (_ptDistance < _minDistance)
			{
				_closestGoodPt = 0;
				_minDistance = _ptDistance;
			}
			
			//distance to upper-right corner of tile
			_pt.x = EndTileX * map.texWidth;
			_ptDistance = projectPointToScreen(_pt.x, _pt.y, 0, floorPt1)
			if (_ptDistance == -1) _badPt1 = _badPointExists = true;
			else if (_ptDistance < _minDistance)
			{
				_closestGoodPt = 1;
				_minDistance = _ptDistance;
			}
			
			//distance to lower-right corner of tile
			_pt.y = EndTileY * map.texHeight;
			_ptDistance = projectPointToScreen(_pt.x, _pt.y, 0, floorPt3)
			if (_ptDistance == -1) _badPt3 = _badPointExists = true;
			else if (_ptDistance < _minDistance)
			{
				_closestGoodPt = 3;
				_minDistance = _ptDistance;
			}
			
			//distance to lower-left corner of tile
			_pt.x = StartTileX * map.texWidth;
			_ptDistance = projectPointToScreen(_pt.x, _pt.y, 0, floorPt2)
			if (_ptDistance == -1) _badPt2 = _badPointExists = true;
			else if (_ptDistance < _minDistance)
			{
				_closestGoodPt = 2;
				_minDistance = _ptDistance;
			}
			
			if (_badPointExists)
			{
				if (IterationsLeft == 0) return;
				//invalidate the closest good point, so we can figure out whether to cut it in half or in quadrants, as well as
				//which quadrant or half to use
				if (_closestGoodPt == 0) _badPt0 = true;
				else if (_closestGoodPt == 1) _badPt1 = true;
				else if (_closestGoodPt == 2) _badPt2 = true;
				else if (_closestGoodPt == 3) _badPt3 = true;

				var _sX:Number = StartTileX;
				var _sY:Number = StartTileY;
				var _eX:Number = EndTileX;
				var _eY:Number = EndTileY;
				if 		(_badPt0 && _badPt1) _sY = StartTileY + 0.4 * (EndTileY - StartTileY);
				else if (_badPt2 && _badPt3) _eY = StartTileY + 0.6 * (EndTileY - StartTileY);
				if 		(_badPt0 && _badPt2) _sX = StartTileX + 0.4 * (EndTileX - StartTileX);
				else if (_badPt1 && _badPt3) _eX = StartTileX + 0.6 * (EndTileX - StartTileX);
				if (IterationsLeft > 0) renderFloor(_sX, _sY, _eX, _eY, IterationsLeft - 1);
			}
			else
			{
				var _light:int = 10 - map.lightmap[int(StartTileX) + int(StartTileY) * map.widthInTiles];
				if (_tileDistance >= 8) _light += int(0.5 * (_tileDistance - 6));
				if (_light >= 10) return;//_light = 5;
				var _startTexX:Number = map.uvWidth * (StartTileX - int(StartTileX));
				var _startTexY:Number = map.uvHeight * (StartTileY - int(StartTileY));
				var _endTexX:Number = map.uvWidth * (EndTileX - int(StartTileX));
				var _endTexY:Number = map.uvHeight * (EndTileY - int(StartTileY));
				floorSourceRect.x = 2 * map.uvWidth + _startTexX;
				floorSourceRect.y = map.uvHeight * _light + _startTexY;
				floorSourceRect.width = 2 * map.uvWidth + _endTexX;
				floorSourceRect.height = map.uvHeight * _light + _endTexY;
				drawPlaneToCanvas(floorPt0, floorPt1, floorPt2, floorPt3, floorSourceRect);
				
				floorPt0.y = viewport.height - floorPt0.y;
				floorPt1.y = viewport.height - floorPt1.y;
				floorPt2.y = viewport.height - floorPt2.y;
				floorPt3.y = viewport.height - floorPt3.y;
				
				floorSourceRect.x = 3 * map.uvWidth + _startTexX;
				floorSourceRect.width = 3 * map.uvWidth + _endTexX;
				drawPlaneToCanvas(floorPt0, floorPt1, floorPt2, floorPt3, floorSourceRect);
			}
		}
		
		private function renderWall(TileX:uint, TileY:uint, Face:uint):void
		{
			var _pX:Number = player.pos.x / map.texWidth;
			var _pY:Number = player.pos.y / map.texHeight;
			var _tX:Number = TileX + 0.5;
			var _tY:Number = TileY + 0.5;
			var _tileDistance:Number = Math.sqrt((_pX - _tX) * (_pX - _tX) + (_pY - _tY) * (_pY - _tY));
			
			var _index:uint = TileX + TileY * map.widthInTiles;
			var _light:int;
			//Use the lighting of the square that is adjacent to this particular wall face
			if (Face == Map.WEST) _light = 10 - map.lightmap[_index - 1];
			else if (Face == Map.EAST) _light = 10 - map.lightmap[_index + 1];
			else if (Face == Map.NORTH) _light = 10 - map.lightmap[_index - map.widthInTiles];
			else if (Face == Map.SOUTH) _light = 10 - map.lightmap[_index + map.widthInTiles];
			if (_tileDistance >= 8) _light += int(0.5 * (_tileDistance - 6));
			if (_light >= 10) return;//_light = 5;
			var _tileIndex:uint = map.getTile(TileX, TileY);

			//move downward on the texture file based on how dark it needs to be.
			sourceRect.x = map.uvWidth * int(_tileIndex % 10);
			sourceRect.y = map.uvHeight * _light;
			sourceRect.width = sourceRect.x + map.uvWidth;
			sourceRect.height = sourceRect.y + map.uvHeight;
			
			var _ptDistance:Number = 0;
			//distance to upper-left corner of face
			_pt.x = TileX * map.texWidth;
			_pt.y = TileY * map.texHeight;
			if (Face == Map.EAST || Face == Map.SOUTH) _pt.x += map.texWidth;
			if (Face == Map.WEST || Face == Map.SOUTH) _pt.y += map.texHeight;
			_ptDistance = projectPointToScreen(_pt.x, _pt.y, map.texHeight, pt1)
			if (_ptDistance == -1)
			{
				sourceRect.width -= 0.25 * map.uvWidth;
				if (Face == Map.NORTH) _pt.x += 0.25 * map.texWidth;
				else if (Face == Map.EAST) _pt.y += 0.25 * map.texHeight;
				else if (Face == Map.SOUTH) _pt.x -= 0.25 * map.texWidth;
				else if (Face == Map.WEST) _pt.y -= 0.25 * map.texHeight;
				_ptDistance = projectPointToScreen(_pt.x, _pt.y, map.texHeight, pt1);
				if (_ptDistance == -1)
				{	// If the distance is negative, then the point is behind the player, and will not render properly. So, we need to cut
					//part of the wall off and try again
					sourceRect.width -= 0.25 * map.uvWidth;
					if (Face == Map.NORTH) _pt.x += 0.25 * map.texWidth;
					else if (Face == Map.EAST) _pt.y += 0.25 * map.texHeight;
					else if (Face == Map.SOUTH) _pt.x -= 0.25 * map.texWidth;
					else if (Face == Map.WEST) _pt.y -= 0.25 * map.texHeight;
					_ptDistance = projectPointToScreen(_pt.x, _pt.y, map.texHeight, pt1);
					if (_ptDistance == -1)
					{
						sourceRect.width -= 0.25 * map.uvWidth;
						if (Face == Map.NORTH) _pt.x += 0.25 * map.texWidth;
						else if (Face == Map.EAST) _pt.y += 0.25 * map.texHeight;
						else if (Face == Map.SOUTH) _pt.x -= 0.25 * map.texWidth;
						else if (Face == Map.WEST) _pt.y -= 0.25 * map.texHeight;
						_ptDistance = projectPointToScreen(_pt.x, _pt.y, map.texHeight, pt1);
					}
				}
			}
			if (_ptDistance == -1) return;
			
			//distance to lower-left corner of face
			pt3.x = pt1.x;
			pt3.y = viewport.height - pt1.y;
			
			//distance to upper-right corner of face
			_pt.x = TileX * map.texWidth;
			_pt.y = TileY * map.texHeight;
			if (Face == Map.NORTH || Face == Map.EAST) _pt.x += map.texWidth;
			if (Face == Map.EAST || Face == Map.SOUTH) _pt.y += map.texHeight;
			_ptDistance = projectPointToScreen(_pt.x, _pt.y, map.texHeight, pt0);
			
			if (_ptDistance == -1)
			{	// If the distance is negative, then the point is behind the player, and will not render properly. So, we need to cut
				//part of the wall off and try again
				sourceRect.x += 0.25 * map.uvWidth;
				if (Face == Map.NORTH) _pt.x -= 0.25 * map.texWidth;
				else if (Face == Map.EAST) _pt.y -= 0.25 * map.texHeight;
				else if (Face == Map.SOUTH) _pt.x += 0.25 * map.texWidth;
				else if (Face == Map.WEST) _pt.y += 0.25 * map.texHeight;
				_ptDistance = projectPointToScreen(_pt.x, _pt.y, map.texHeight, pt0);
				if (_ptDistance == -1)
				{
					sourceRect.x += 0.25 * map.uvWidth;
					if (Face == Map.NORTH) _pt.x -= 0.25 * map.texWidth;
					else if (Face == Map.EAST) _pt.y -= 0.25 * map.texHeight;
					else if (Face == Map.SOUTH) _pt.x += 0.25 * map.texWidth;
					else if (Face == Map.WEST) _pt.y += 0.25 * map.texHeight;
					_ptDistance = projectPointToScreen(_pt.x, _pt.y, map.texHeight, pt0);
					if (_ptDistance == -1)
					{
						sourceRect.x += 0.25 * map.uvWidth;
						if (Face == Map.NORTH) _pt.x -= 0.25 * map.texWidth;
						else if (Face == Map.EAST) _pt.y -= 0.25 * map.texHeight;
						else if (Face == Map.SOUTH) _pt.x += 0.25 * map.texWidth;
						else if (Face == Map.WEST) _pt.y += 0.25 * map.texHeight;
						_ptDistance = projectPointToScreen(_pt.x, _pt.y, map.texHeight, pt0);
					}
				}
			}
			if (_ptDistance == -1) return;
			
			//distance to lower-right corner of face
			pt2.x = pt0.x;
			pt2.y = viewport.height - pt0.y;
			
			drawPlaneToCanvas(pt0, pt1, pt2, pt3, sourceRect);
		}
		
		public function drawPlaneToCanvas(Point0:FlxPoint, Point1:FlxPoint, Point2:FlxPoint, Point3:FlxPoint, SourceRect:Rectangle):void
		{
			//Many thanks to http://zehfernando.com/2010/the-best-drawplane-distortimage-method-ever/ for this!
			
			var _indentX:Number = 0.000390625;//1/128/10/2;
			var _indentY:Number = 0.000390625;//1/128/20/2;
			_point = intersect(Point0, Point1, Point2, Point3);
			if (_point == null) return;
			
			// Lengths of first diagonal		
			var ll1:Number = FlxU.getDistance(Point0, _point);
			var ll2:Number = FlxU.getDistance(_point, Point3);
			
			// Lengths of second diagonal		
			var lr1:Number = FlxU.getDistance(Point1, _point);
			var lr2:Number = FlxU.getDistance(_point, Point2);
			
			// Ratio between diagonals
			var f:Number = (ll1 + ll2) / (lr1 + lr2);

			// Draws the triangle
			canvas.graphics.beginBitmapFill(map.textures.pixels, null, false, false);
			canvas.graphics.drawTriangles(
				Vector.<Number>([Point0.x, Point0.y, Point1.x, Point1.y, Point2.x, Point2.y, Point3.x, Point3.y]),
				Vector.<int>([0, 1, 2, 1, 3, 2]),
				Vector.<Number>([
					SourceRect.x + _indentX,		SourceRect.y + _indentY,		(1/ll2)*f,
					SourceRect.width - _indentX,	SourceRect.y + _indentY,		(1/lr2), 
					SourceRect.x + _indentX,		SourceRect.height - _indentY,	(1/lr1),
					SourceRect.width - _indentX,	SourceRect.height - _indentY,	(1/ll1)*f ])
			);
		}
		
		/**
		 * Get the <code>intersect</code> of the diagonals between the four courners of the 3D face we're wanting to draw.
		 */
		public function intersect(Point0:FlxPoint, Point1:FlxPoint, Point2:FlxPoint, Point3:FlxPoint):FlxPoint
		{
			// Returns a point containing the intersection between two lines
			// http://keith-hair.net/blog/2008/08/04/find-intersection-point-of-two-lines-in-as3/
			
			var a1:Number = Point3.y - Point0.y;
			var b1:Number = Point0.x - Point3.x;
			var a2:Number = Point1.y - Point2.y;
			var b2:Number = Point2.x - Point1.x;
			
			var denom:Number = a1 * b2 - a2 * b1;
			if (denom == 0) return null;
			
			var c1:Number = Point3.x * Point0.y - Point0.x * Point3.y;
			var c2:Number = Point1.x * Point2.y - Point2.x * Point1.y;
			
			_intersect.make((b1 * c2 - b2 * c1)/denom, (a2 * c1 - a1 * c2)/denom);
			
			if (FlxU.getDistance(_intersect, Point3) > FlxU.getDistance(Point0, Point3)) return null;
			if (FlxU.getDistance(_intersect, Point0) > FlxU.getDistance(Point0, Point3)) return null;
			if (FlxU.getDistance(_intersect, Point1) > FlxU.getDistance(Point2, Point1)) return null;
			if (FlxU.getDistance(_intersect, Point2) > FlxU.getDistance(Point2, Point1)) return null;
			
			return _intersect;
		}
		
		public function renderEntities():void
		{
			var _clipLeft:uint;
			var _clipWidth:uint;
			var _leftEdge:int;
			var _rightEdge:int;
			var _width:int;
			var _posX:uint;
			var _posY:uint;
			
			var _light:Number = map.lightmap[int(player.pos.x / map.texWidth) + int(player.pos.y / map.texHeight) * map.widthInTiles]
			if (_light < 2) _light = 3;
			else if (_light > 10) _light = 10;
			_light /= Map.LIGHT_LEVELS;
			var _shade:uint = 255 * _light;
			playerSprite.color = (_shade << 16) + (_shade << 8) + _shade;
			for (var i:uint = 0; i < entities.length; i++)
			{
				entity = entities.members[i];
				if (entity.exists)
				{
					entity.distance = projectPointToScreen(entity.x, entity.y, 64, entity.viewPos, entity);
					if (entity.distance > 0) 
					{
						_width = entity.frameWidth * entity.scale.x;
						
						_leftEdge = int(entity.viewPos.x - 0.5 * _width);
						if (_leftEdge < 0) _leftEdge = 0;
						_clipLeft = _leftEdge;
						_rightEdge = int(entity.viewPos.x + 0.5 * _width);
						if (_rightEdge >= viewport.width) _rightEdge = viewport.width - 1;
						while ((_clipLeft < _rightEdge) && (_clipLeft + _leftEdge < zBuffer.length) 
							&& (zBuffer[_clipLeft] < entity.distance)) _clipLeft += 1;
						
						entity.clipRect.x = _clipLeft;
						_clipWidth = _rightEdge - _clipLeft;
						if (_clipWidth > viewport.width - _clipLeft) _clipWidth = viewport.width - _clipLeft;
						while ((_clipWidth > 0) && (_clipLeft + _clipWidth < zBuffer.length) 
							&& (zBuffer[_clipLeft + _clipWidth] < entity.distance)) _clipWidth -= 1;
						
						if (_clipWidth > 0)
						{
							entity.clipRect.width = _clipWidth + 1;
							entity.clipRect.x -= 1;
							entity.clipRect.height = viewport.height;
							
							_posX = int(entity.pos.x / map.texWidth);
							_posY = int(entity.pos.y / map.texHeight);
							entity.light(map.lightmap[_posX + _posY * map.widthInTiles] + 1);
						}
						else entity.distance = -1;
					}
				}
			}
			entities.sort("distance", DESCENDING);
		}
		
		/**
		 * Projects a point in 3d (x, y, z) map space to a point in 2d (x, y) screen space, relative to the Player.
		 * 
		 * @param	SourceX				The x-coordinate in map space of the point to be projected.
		 * @param	SourceY				The y-coordinate in map space of the point to be projected.
		 * @param	SourceZ				The z-coordinate in map space of the point to be projected.
		 * @param	DestinationPoint	The point used to store the screen coordinates after projection.
		 * @param	GameEntity			If present, it means this Entity needs to be resized after its distance has been calculated.
		 * 
		 * @return	The distance in tile units from the player to the point.
		 */
		public function projectPointToScreen(SourceX:Number, SourceY:Number, SourceZ:Number, DestinationPoint:FlxPoint, GameEntity:Entity = null):Number
		{
			var planeX:Number = player.magView * player.view.x;
			var planeY:Number = player.magView * player.view.y;
			var invDet:Number = 1.0 / (planeX * player.dir.y - player.dir.x * planeY);
			
			var _x:Number = SourceX - player.pos.x;
			var _y:Number = SourceY - player.pos.y;
			
			var transformX:Number = invDet * (player.dir.y * _x - player.dir.x * _y);
			var transformY:Number = invDet * (-planeY * _x + planeX * _y); 
			var _height:Number = viewport.height / transformY;
			
			if (transformY > 0)
			{
				DestinationPoint.x = int((0.5 * viewport.width) * (1 + transformX / transformY));
				
				//if we're projecting a singular point that is representing a game sprite, we need to adjust its scale
				if (GameEntity) GameEntity.scale.x = GameEntity.scale.y = Math.abs(_height);
				
				DestinationPoint.y = 0.5 * viewport.height;
				DestinationPoint.y -= (SourceZ / map.texHeight - 0.5) * map.texHeight * _height;
				
				//if (SourceZ == 0) DestinationPoint.y += 0.5 * map.texHeight * _height;
				//else if (SourceZ == map.texHeight) DestinationPoint.y -= 0.5 * map.texHeight * _height;
				return transformY / map.texHeight;
			}
			else 
			{
				return -1;
			}
		}
	}
}