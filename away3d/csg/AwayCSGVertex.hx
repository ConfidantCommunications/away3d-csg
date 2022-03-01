package away3d.csg;

	import away3d.csg.geom.IVertex;
	import away3d.csg.geom.Vertex;
	
	import openfl.geom.Vector3D;

	class AwayCSGVertex extends Vertex implements IVertex
	{
		@:isVar public var uv(get,set):Vector3D;
		
		public function get_uv():Vector3D
		{
			return this.uv;
		}
		public function set_uv(value:Vector3D):Vector3D
		{
			return this.uv = value;
		}
		
		public function new(pos:Vector3D, normal:Vector3D=null, uv:Vector3D=null)
		{
			super(pos, normal);
			this.uv = (uv != null) ? uv : new Vector3D();
		}
		
		override public function clone():IVertex
		{
			return new AwayCSGVertex(pos.clone(), normal.clone(), uv.clone());	
		}
		
		override public function interpolate(other:IVertex, t:Float):IVertex
		{
			return new AwayCSGVertex(
					lerp(this.pos, cast(other,AwayCSGVertex).pos, t),
					lerp(this.normal, cast(other,AwayCSGVertex).normal, t),
					lerp(this.uv, cast(other,AwayCSGVertex).uv, t)//Vector Vector Float
				);
		}
		
	}
