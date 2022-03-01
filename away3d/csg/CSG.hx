package away3d.csg;

import openfl.geom.Vector3D;

import openfl.geom.Matrix3D;
import away3d.csg.geom.IVertex;
import away3d.csg.geom.Node;
import away3d.csg.geom.Polygon;
import away3d.csg.geom.Vertex;

	/** 
	 * Constructive Solid Geometry (CSG) is a modeling technique that uses Boolean
	 * operations like union and intersection to combine 3D solids. This library
	 * implements CSG operations on meshes elegantly and concisely using BSP trees,
	 * and is meant to serve as an easily understandable implementation of the
	 * algorithm. All edge cases involving overlapping coplanar polygons in both
	 * solids are correctly handled.
	 * 
	 * Example usage:
	 * 
	 *     var cube = CSG.cube();
	 *     var sphere = CSG.sphere({ radius: 1.3 });
	 *     var polygons = cube.subtract(sphere).toPolygons();
	 * 
	 * ## Implementation Details
	 * 
	 * All CSG operations are implemented in terms of two functions, `clipTo()` and
	 * `invert()`, which remove parts of a BSP tree inside another BSP tree and swap
	 * solid and empty space, respectively. To find the union of `a` and `b`, we
	 * want to remove everything in `a` inside `b` and everything in `b` inside `a`,
	 * then combine polygons from `a` and `b` into one solid:
	 * 
	 *     a.clipTo(b);
	 *     b.clipTo(a);
	 *     a.build(b.allPolygons());
	 * 
	 * The only tricky part is handling overlapping coplanar polygons in both trees.
	 * The code above keeps both copies, but we need to keep them in one tree and
	 * remove them in the other tree. To remove them from `b` we can clip the
	 * inverse of `b` against `a`. The code for union now looks like this:
	 * 
	 *     a.clipTo(b);
	 *     b.clipTo(a);
	 *     b.invert();
	 *     b.clipTo(a);
	 *     b.invert();
	 *     a.build(b.allPolygons());
	 * 
	 * Subtraction and intersection naturally follow from set operations. If
	 * union is `A | B`, subtraction is `A - B = ~(~A | B)` and intersection is
	 * `A & B = ~(~A | ~B)` where `~` is the complement operator.
	 * 
	 *
	 * class CSG
	 *
	 * Holds a binary space partition tree representing a 3D solid. Two solids can
	 * be combined using the `union()`, `subtract()`, and `intersect()` methods.
	 */ 

class CSG {
	
	private static var currentCSGMeshId:Int = 0;
	
	public var polygons:Array<Polygon>;
	public var matrix:Matrix3D;
	public var position:Vector3D;
	public var rotation:Vector3D;
	public var scaling:Vector3D;
	
	
	public function new() {
		this.polygons = new Array<Polygon>();
	}

	// Construct a CSG solid from a list of `CSG.Polygon` instances.
	public static function fromPolygons(polygons:Array<Polygon>):CSG {
		var csg = new CSG();
		csg.polygons = polygons;
		return csg;
	}

	public function clone():CSG {
		var csg = new CSG();
		csg.polygons = this.polygons.copy();
		// csg.copyTransformAttributes(this);
		return csg;
	}

	public function toPolygons():Array<Polygon> {
		return this.polygons;
	}

	public function union(csg:CSG):CSG {
		var a = new Node(this.clone().polygons);
		var b = new Node(csg.clone().polygons);
		a.clipTo(b);
		b.clipTo(a);
		b.invert();
		b.clipTo(a);
		b.invert();
		a.build(b.allPolygons());
		return CSG.fromPolygons(a.allPolygons());//.copyTransformAttributes(this);
	}

	public function unionInPlace(csg:CSG) {
		var a = new Node(this.polygons);
		var b = new Node(csg.polygons);
		
		a.clipTo(b);
		b.clipTo(a);
		b.invert();
		b.clipTo(a);
		b.invert();
		a.build(b.allPolygons());
		
		this.polygons = a.allPolygons();
	}

	public function subtract(csg:CSG):CSG {
		var a = new Node(this.clone().polygons);
		var b = new Node(csg.clone().polygons);
		a.invert();
		a.clipTo(b);
		b.clipTo(a);
		b.invert();
		b.clipTo(a);
		b.invert();
		a.build(b.allPolygons());
		a.invert();
		return CSG.fromPolygons(a.allPolygons());//.copyTransformAttributes(this);
	}

	public function subtractInPlace(csg:CSG) {
		var a = new Node(this.polygons);
		var b = new Node(csg.polygons);
		
		a.invert();
		a.clipTo(b);
		b.clipTo(a);
		b.invert();
		b.clipTo(a);
		b.invert();
		a.build(b.allPolygons());
		a.invert();
		
		this.polygons = a.allPolygons();
	}

	public function intersect(csg:CSG):CSG {
		var a = new Node(this.clone().polygons);
		var b = new Node(csg.clone().polygons);
		a.invert();
		b.clipTo(a);
		b.invert();
		a.clipTo(b);
		b.clipTo(a);
		a.build(b.allPolygons());
		a.invert();
		
		return CSG.fromPolygons(a.allPolygons());//.copyTransformAttributes(this);
	}

	public function intersectInPlace(csg:CSG) {
		var a = new Node(this.polygons);
		var b = new Node(csg.polygons);
		
		a.invert();
		b.clipTo(a);
		b.invert();
		a.clipTo(b);
		b.clipTo(a);
		a.build(b.allPolygons());
		a.invert();
		
		this.polygons = a.allPolygons();
	}

	// Return a new CSG solid with solid and empty space switched. This solid is
	// not modified.
	
	public function inverse():CSG
		{
			var csg:CSG = this.clone();
			for (p in csg.polygons) {
				p.flip();
			}
			return csg;
		}
// This is used to keep meshes transformations so they can be restored
	// when we build back a  Mesh
	// NB :All CSG operations are performed in world coordinates
	/* public function copyTransformAttributes(csg:CSG):CSG {
		this.matrix = csg.matrix;
		this.position = csg.position;
		this.rotation = csg.rotation;
		this.scaling = csg.scaling;
		
		return this;
	}  */

	//
		/**
		 * Cube
		 * 
		 * @param center
		 * @param radius
		 * 
		 * @return CSG
		 */ 
		public static function cube(center:Vector3D=null, radius:Vector3D=null):CSG
			{
				var c:Vector3D = (center!=null) ? center : new Vector3D();
				var r:Vector3D = (radius!=null) ? radius : new Vector3D(1, 1, 1);
				var polygons:Array<Polygon> = new Array<Polygon>();
				var data:Array<Array<Array<Int>>> = [
				 [[0, 4, 6, 2], [-1, 0, 0]],
				 [[1, 3, 7, 5], [1, 0, 0]],
				 [[0, 1, 5, 4], [0, -1, 0]],
				 [[2, 6, 7, 3], [0, 1, 0]],
				 [[0, 2, 3, 1], [0, 0, -1]],
				 [[4, 5, 7, 6], [0, 0, 1]]
				];
				for  (array in data) {
					var v:Array<Int> = array[0];
					var n:Vector3D = new Vector3D(array[1][0], array[1][1], array[1][2]);
					var verts = v.map(
								function(elem:Int):IVertex {
									var i:Int = elem;
									return new Vertex(new Vector3D(
										c.x + (r.x * (2 * ((i & 1 >0) ? 1:0) - 1)), 
										c.y + (r.y * (2 * ((i & 2 >0) ? 1:0) - 1)),
										c.z + (r.z * (2 * ((i & 4 >0) ? 1:0) - 1))),
										n
									);
								}
							);
					// polygons.push(new Polygon(verts));
					polygons.push(
							new Polygon(
								verts
							)
						);
				}
				return CSG.fromPolygons(polygons);
			}
			
			/**
			 * Sphere
			 * 
			 * @param center
			 * @param radius
			 * @param slices
			 * @param stacks
			 * 
			 * @return CSG
			 */ 
			public static function sphere(center:Vector3D=null, radius:Float=1, slices:Int=16, stacks:Int=8):CSG
			{
				var c:Vector3D = (center!=null) ? center : new Vector3D();
				var r:Float = radius;
				var polygons:Array<Polygon> = new Array<Polygon>();
				var vertices:Array<IVertex> = [];
				
				function vertex(theta:Float, phi:Float):Void {
					theta *= Math.PI * 2;
					phi *= Math.PI;
					var dir:Vector3D = new Vector3D(
						Math.cos(theta) * Math.sin(phi),
						Math.cos(phi),
						Math.sin(theta) * Math.sin(phi)
					);
					var sdir:Vector3D = dir.clone();
					sdir.scaleBy(r);
					vertices.push(new Vertex(c.add(sdir), dir));
				}
				
				for (i in 0...slices) {
					
					
					for (j in 0...stacks) {
						
						vertices = new Array<IVertex>();
						vertex(i / slices, j / stacks);
						if (j > 0) vertex((i + 1) / slices, j / stacks);
						if (j < stacks - 1) vertex((i + 1) / slices, (j + 1) / stacks);
						vertex(i / slices, (j + 1) / stacks);
						polygons.push(new Polygon(vertices));
						
					}
					
				}
				return CSG.fromPolygons(polygons);
			}
	
}
