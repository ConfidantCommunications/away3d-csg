package away3d.csg.geom;

// import com.babylonhx.math.Vector3;
import haxe.ds.Vector;
import openfl.geom.Vector3D;// as Vector3;

// Represents a plane in 3D space.
class Plane {
	
	static inline var COPLANAR:Int = 0;
	static inline var FRONT:Int = 1;
	static inline var BACK:Int = 2;
	static inline var SPANNING:Int = 3;
	
	// EPSILON is the tolerance used by `splitPolygon()` to decide if a
	// point is on the plane.
	public static var EPSILON:Float = 1e-5;
	
	public var normal:Vector3D;
	public var w:Float;
	
	
	public function new(normal:Vector3D, w:Float) {
		this.normal = normal;
		this.w = w;
	}
	public static function fromPoints(a:Vector3D, b:Vector3D, c:Vector3D):Plane
		{
			var n:Vector3D = b.subtract(a).crossProduct(c.subtract(a));
			n.normalize();
			return new Plane(n, n.dotProduct(a));
		} 

	public function clone():Plane {
		return new Plane(this.normal.clone(), this.w);
	}

	public function flip() {
		// this.normal.scaleInPlace(-1);
		// this.w = -this.w;

		this.normal.negate();
		// this.normal = this.normal.scale(-1);
		this.w = -this.w;
	}

	// Split `polygon` by this plane if needed, then put the polygon or polygon
	// fragments in the appropriate lists. Coplanar polygons go into either
	// `coplanarFront` or `coplanarBack` depending on their orientation with
	// respect to this plane. Polygons in front or in back of this plane go into
	// either `front` or `back`.
	public function splitPolygon(polygon:Polygon, coplanarFront:Array<Polygon>, coplanarBack:Array<Polygon>, front:Array<Polygon>, back:Array<Polygon>):Void {
		// Classify each point as well as the entire polygon into one of the above
		// four classes.
		var polygonType:Int = 0;
		var types:Array<Int> = [];
		for (i in 0...polygon.vertices.length) {
			// var t = Vector3.Dot(this.normal, polygon.vertices[i].pos) - this.w;
			var t = this.normal.dotProduct(polygon.vertices[i].pos) - this.w;
			var type = (t < -Plane.EPSILON) ? Plane.BACK :(t > Plane.EPSILON) ? Plane.FRONT : Plane.COPLANAR;
			polygonType |= type;
			types.push(type);
		}
		
		// Put the polygon in the correct list, splitting it when necessary.
		switch (polygonType) {
			case Plane.COPLANAR:
				// (Vector3.Dot(this.normal, polygon.plane.normal) > 0 ? coplanarFront : coplanarBack).push(polygon);
				(this.normal.dotProduct(polygon.plane.normal) > 0 ? coplanarFront : coplanarBack).push(polygon);
				 
				
			case Plane.FRONT:
				front.push(polygon);
				
			case Plane.BACK:
				back.push(polygon);
				
			case Plane.SPANNING:
				var f:Array<IVertex> = [];
				var b:Array<IVertex> = [];
				for (i in 0...polygon.vertices.length) {
					var j = (i + 1) % polygon.vertices.length;
					var ti = types[i], tj = types[j];
					var vi = polygon.vertices[i], vj = polygon.vertices[j];
					if (ti != Plane.BACK) f.push(vi);
					if (ti != Plane.FRONT) b.push(ti != BACK ? vi.clone() : vi);
					if ((ti | tj) == Plane.SPANNING) {
						// var t = (this.w - Vector3.Dot(this.normal, vi.pos)) / Vector3.Dot(this.normal, vj.pos.subtract(vi.pos));
						var t = (this.w - this.normal.dotProduct(vi.pos)) / this.normal.dotProduct(vj.pos.subtract(vi.pos));
						var v = vi.interpolate(vj, t);
						f.push(v);
						b.push(v.clone());
					}
				}
				
				if (f.length >= 3) {
					var poly = new Polygon(f, polygon.shared);
					
					if (poly.plane != null)
						front.push(poly);
				}
				
				if (b.length >= 3) {
					var poly = new Polygon(b, polygon.shared);
					
					if (poly.plane != null)
						back.push(poly);
				}
				
		}
	}
	
}
