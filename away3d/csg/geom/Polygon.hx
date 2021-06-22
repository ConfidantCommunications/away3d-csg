package away3d.csg.geom;
import openfl.geom.*;

// Represents a convex polygon. The vertices used to initialize a polygon must
// be coplanar and form a convex loop.
// 
// Each convex polygon has a `shared` property, which is shared between all
// polygons that are clones of each other or were split from the same polygon.
// This can be used to define per-polygon properties (such as surface color).
class Polygon {
	
	public var vertices:Array<IVertex>;
	public var shared:Any;
	public var plane:Plane;
	

	public function new(vertices:Array<IVertex>, shared:Any = null) {
		this.vertices = vertices;
		this.shared = shared;
		this.plane = Plane.fromPoints(vertices[0].pos, vertices[1].pos, vertices[2].pos);
	}

	inline public function clone():Polygon {
		var vertices = this.vertices.copy(); // this.vertices.map(function(v) { return v.clone(); } ).filter(function(v) { v.plane; } );
		
		return new Polygon(vertices, this.shared);
	}

	public function flip():Void {
		this.vertices.reverse();
		for  (v in this.vertices) {
			v.flip();
		}
		this.plane.flip();
	}
	
}
