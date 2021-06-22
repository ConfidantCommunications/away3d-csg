 package away3d.csg.geom;

	import openfl.geom.Vector3D;

	/**
	 *class Vertex
	 * 
	 * Represents a vertex of a polygon. Use your own vertex class instead of this
	 * one to provide additional features like texture coordinates and vertex
	 * colors. Custom vertex classes need to implement the IVertex interface.
	 * 
	 * @see away3d.csg.IVertex
	 */
	class Vertex implements IVertex
	{
		@:isVar public var pos(get,set):Vector3D;
		@:isVar public var normal(get,set):Vector3D;
		
		public function new(pos:Vector3D, normal:Vector3D)
		{
			this.pos = (pos != null) ? pos : new Vector3D();
			this.normal = (normal != null) ? normal : new Vector3D();
		}
		
		public function get_normal():Vector3D
		{
			return this.normal;
		}

		public function set_normal(value:Vector3D):Vector3D
		{
			return this.normal = value;
		}

		public function get_pos():Vector3D
		{
			return this.pos;
		}

		public function set_pos(value:Vector3D):Vector3D
		{
			return this.pos = value;
		}

		public function clone():IVertex
		{
			return new Vertex(this.pos.clone(), this.normal.clone());
		}
		
		public function flip():Void
		{
			this.normal.negate();
			// this.normal = this.normal.scale(-1);
		}
		
		public function interpolate(other:IVertex, t:Float):IVertex
		{
			return new Vertex(
				lerp(this.pos, other.pos, t), 
				lerp(this.normal, cast(other,Vertex).normal, t)
			);
			
		}
		
		private function lerp(a:Vector3D, b:Vector3D, t:Float):Vector3D
		{
			var ab:Vector3D = b.subtract(a);
			ab.scaleBy(t);
			return a.add(ab);
		}
	}
