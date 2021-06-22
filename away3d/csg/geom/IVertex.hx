package away3d.csg.geom;

	import openfl.geom.Vector3D;

	interface IVertex
	{
		public var pos(get,set):Vector3D;

		// function get_pos():Vector3D {return pos;}
		// function set_pos(value:Vector3D):Void {this.pos = value;}
		function clone():IVertex;
		function flip():Void;
		function interpolate(other:IVertex, t:Float):IVertex;
	}
