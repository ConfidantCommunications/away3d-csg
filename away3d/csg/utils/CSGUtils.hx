package away3d.csg.utils;

	import away3d.csg.geom.IVertex;
	import away3d.csg.geom.Plane;
	import away3d.csg.geom.Polygon;
	import away3d.csg.geom.Vertex;
	
	import openfl.geom.Vector3D;

	class CSGUtils
	{
		/**
		 * Creates a Polygon from an array of points.
		 * 
		 * @param points
		 * @param shared
		 * 
		 * @return Polygon
		 */ 
		public static function createPolygon(points:Array<Vector3D>, shared:Any = null):Polygon
		{
			if (points.length < 2) {
				return null;
			}
			
			var vertices:Array<IVertex> = new Array<IVertex>();
			for (pos in points) {
				vertices.push(new Vertex(pos));
			}
			var polygon:Polygon = new Polygon(vertices, shared);
			
			return polygon;
		}
		
		/**
		 * Extrudes a polygon.
		 * 
		 * @param polygon The polygon to extrude
		 * @param distance Extrusion distance
		 * @param normal Optional normal to extrude along, default is polygon normal
		 * 
		 * @return Array<Polygon>
		 */ 
		public static function extrudePolygon(
			polygon:Polygon, 
			distance:Float, 
			normal:Vector3D = null):Array<Polygon>
		{
			normal = normal || polygon.plane.normal;

			var du:Vector3D = normal.clone(),
				vertices:Array<IVertex> = polygon.vertices,
				top:Array<IVertex> = new Array<IVertex>(),
				bot:Array<IVertex> = new Array<IVertex>(),
				polygons:Array<Polygon> = new Array<Polygon>(),
				invNormal:Vector3D = normal.clone();
			
			du.scaleBy(distance);
			invNormal.negate();
			// invNormal = this.normal.scale(-1);
			for ( i in 0...vertices.length) {
				
				var j:Int = (i+1) % vertices.length,
					p1:Vector3D = vertices[i].pos,
					p2:Vector3D = vertices[j].pos,
					p3:Vector3D = p2.clone().add(du),
					p4:Vector3D = p1.clone().add(du),
					plane:Plane = Plane.fromPoints(p1, p2, p3),
					v1:Vertex = new Vertex(p1, plane.normal),
					v2:Vertex = new Vertex(p2, plane.normal),
					v3:Vertex = new Vertex(p3, plane.normal),
					v4:Vertex = new Vertex(p4, plane.normal),
					poly:Polygon = new Polygon(Array<IVertex>([v1, v2, v3, v4]), polygon.shared);
				polygons.push(poly);
				top.push(new Vertex(p4.clone(), normal));
				bot.unshift(new Vertex(p1.clone(), invNormal));
			}

			polygons.push(new Polygon(top, polygon.shared));
			polygons.push(new Polygon(bot, polygon.shared));
			
			return polygons;
		}
	}
