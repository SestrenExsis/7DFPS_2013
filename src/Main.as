package
{
	import org.flixel.FlxGame;
	import ScreenState;
	[SWF(width="640", height="480", backgroundColor="#222222")]
	
	//1) find all visible planes (walls, floors, ceilings, and sprites)
	//   visMap (1 ... n) --> (ID) [n = total number of visible planes]
	//   visMapIndex (ID) --> (1 ... n)
	//   For sprites, ID is -1 * their index position in the FlxGroup
	//   For walls, floors, and ceilings, ID is mapIndex * 6 + tileFace
	//2) update screen positions for all visible vertices
	//   vertexMapX (
	//
	//m) sort all visible planes by distance Array.sort()?
	//n) go through all the planes, now sorted by view distance, and render them to the screen
	
	public class Main extends FlxGame
	{
		public function Main()
		{
			super(640, 480, GameState, 1, 60, 60, true);
			forceDebugger = true;
		}
	}
}