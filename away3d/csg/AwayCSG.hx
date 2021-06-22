package away3d.csg;

import flash.geom.Vector3D;
import away3d.core.base.*;
import away3d.entities.Mesh;
import away3d.core.base.SubMesh;
import away3d.materials.*;
import away3d.materials.utils.MultipleMaterials;
import away3d.tools.helpers.MeshHelper;
import openfl.Vector;


import away3d.csg.CSG;
import away3d.csg.geom.*;
// import haxe.ds.Vector;

import openfl.geom.Vector3D;
import openfl.utils.Dictionary;

class AwayCSG
{

	private static inline var AWAY3D_VERTEX_CONVERSION_FACTOR = 1;

	//this one works in Main library
	public static function fromMesh(mesh:Mesh):CSG
	{
		var polygons:Array<Polygon> = new Array<Polygon>();
		
		// var i:Int = 0;
		for  (subMesh in mesh.subMeshes) {
			polygons = polygons.concat(fromSubGeometry(mesh, subMesh.subGeometry, subMesh));
		}
		// trace(polygons);
		return CSG.fromPolygons(polygons);
	}  

	//BabylonHX has its own version of fromMesh and toMesh:
	//https://github.com/vujadin/BabylonHx/blob/master/com/babylonhx/mesh/csg/CSG.hx

	
	/**
	 * 
	 */ 
	public static function fromSubGeometry(mesh:Mesh, geometry:ISubGeometry, subMesh:SubMesh):Array<Polygon>
	{
		var polygons:Array<Polygon> = new Array<Polygon>();

		var step = 3;

		var stride = geometry.vertexStride ; //13
		// var skip:Int = stride - 9;
		var uvstride:Int = geometry.UVStride;//2;
		// var uvskip:Int = uvstride - 2;
		//vertices * stride == total vertexData
		var vnstride:Int = geometry.vertexNormalStride;

		var i = 0;
		while(i < geometry.indexData.length) {
		
			var a:Int = geometry.indexData[i+0];
			var b:Int = geometry.indexData[i+1];
			var c:Int = geometry.indexData[i+2];
			var v1:Vector3D = new Vector3D();
			var v2:Vector3D = new Vector3D();
			var v3:Vector3D = new Vector3D();
			var uv1:Vector3D = new Vector3D();
			var uv2:Vector3D = new Vector3D();
			var uv3:Vector3D = new Vector3D();

			//new for fixing texture display:
			var vn1:Vector3D = new Vector3D();
			var vn2:Vector3D = new Vector3D();
			var vn3:Vector3D = new Vector3D();

			var vertices:Array<IVertex> = new Array<IVertex>();

			
			v1.x = geometry.vertexData[(a*stride)+0];
			v1.y = geometry.vertexData[(a*stride)+1];
			v1.z = geometry.vertexData[(a*stride)+2];
			
			v2.x = geometry.vertexData[(b*stride)+0];
			v2.y = geometry.vertexData[(b*stride)+1];
			v2.z = geometry.vertexData[(b*stride)+2];
			
			v3.x = geometry.vertexData[(c*stride)+0];
			v3.y = geometry.vertexData[(c*stride)+1];
			v3.z = geometry.vertexData[(c*stride)+2];
			
			//mesh.transform is a matrix3D
			v1 = mesh.transform.transformVector(v1);
			v2 = mesh.transform.transformVector(v2);
			v3 = mesh.transform.transformVector(v3);
			
			uv1.x = geometry.UVData[(a*uvstride)+0];
			uv1.y = geometry.UVData[(a*uvstride)+1];

			uv2.x = geometry.UVData[(b*uvstride)+0];
			uv2.y = geometry.UVData[(b*uvstride)+1];
			
			uv3.x = geometry.UVData[(c*uvstride)+0];
			uv3.y = geometry.UVData[(c*uvstride)+1];
			
			vn1.x = geometry.vertexNormalData[(a*vnstride)+0];
			vn1.y = geometry.vertexNormalData[(a*vnstride)+1];
			vn2.x = geometry.vertexNormalData[(b*vnstride)+0];
			vn2.y = geometry.vertexNormalData[(b*vnstride)+1];
			vn3.x = geometry.vertexNormalData[(c*vnstride)+0];
			vn3.y = geometry.vertexNormalData[(c*vnstride)+1];
			
			//away3d away3d.csg.geom.Vertex doesn't have its own UV info
			// subGeometry.updateUVData(uvs);
			
			vertices.push(new AwayCSGVertex(v1, vn1, uv1)); //works with a regular vertex
			vertices.push(new AwayCSGVertex(v2, vn2, uv2));
			vertices.push(new AwayCSGVertex(v3, vn3, uv3));
			
			if(subMesh.material != null){
				// trace("material1 scaleU:"+subMesh.subGeometry.scaleU);
				polygons.push(new Polygon(vertices, subMesh.material));
			} else {
				// trace("material2:"+mesh.material);
				polygons.push(new Polygon(vertices, mesh.material));

			}

			i += step;
		}
		return polygons;
	}
	
	/* 
	public static function toRandomColorMesh(csg:CSG):Mesh {
		var polygons:Array<Polygon> = csg.toPolygons();
		var mesh = new Mesh(null, null);
		for (polygon in polygons) {
			var subGeometry:SubGeometry = toSubGeometry(polygon);
			mesh.subMeshes.push(new SubMesh(subGeometry, mesh, randomColorMaterial()));
		}
		function randomColorMaterial():ColorMaterial {
			var color = '#';
			for ( i in 0...6){
			   var random = Math.random();
			   var bit = Math.floor(random * 16) | 0;
			   color += Std.str(bit).toString(16);
			};
			return color;
		 };
		 return mesh;
	} */

	public static function toMesh(csg:CSG):Mesh
		{
			var polygons:Array<Polygon> = csg.toPolygons();

			//once I tried: var byMaterial:Map<MaterialBase,Array<SubGeometry>>
			var byMaterial:Dictionary<Any,Array<SubGeometry>> = new Dictionary<Any,Array<SubGeometry>>();
			// var mesh:Mesh = null;
			var mesh = new Mesh(null, null);
			//first collect all the polygons of like material into single arrays
			for (polygon in polygons) {
				var subGeometry:SubGeometry = toSubGeometry(polygon);
				if (Std.is(polygon.shared, MaterialBase)) {
					if (byMaterial[polygon.shared]==null) {
						byMaterial[polygon.shared] = [];
					}
					byMaterial[polygon.shared].push(subGeometry);
				}
			}
			//now for each material, make a single submesh
			
			for (key in byMaterial) {
				//these should be materials. find out what kind
				// if (Std.is(key, TextureMaterial))
				// var material:MaterialBase = cast(key, MaterialBase); //	we are losing the Texture Materials!
				var	geometry:Geometry = new Geometry();
				var	subGeometries:Array<SubGeometry> = byMaterial[key];
				
				for (sub in subGeometries) {
					mesh.subMeshes.push(new SubMesh(sub, mesh, key));
					
				}
			}
			return mesh;
			 
		}
	
	/**
	 * Creates a sub-geometry from a Polygon.
	 * 
	 * @param polygon
	 * 
	 * @return SubGeometry
	 */ 
	public static function toSubGeometry(polygon:Polygon):SubGeometry
	{
		var geometry:SubGeometry = new SubGeometry();
		var numVertices:Int = polygon.vertices.length;
		var vertices:Vector<Float> = new Vector<Float>(numVertices * 3);
		var normals:Vector<Float> = new Vector<Float>(numVertices * 3);
		var uvs:Vector<Float> = new Vector<Float>(numVertices * 2);
		var indices:Vector<Int> = new Vector<Int>(numVertices * 3);
		var normal:Vector3D = polygon.plane.normal;
		var index:Int = 0;
		
		
		for(i in 0...numVertices) {
			
		// for (var i:int = 0; i < numVertices; i++) {
			var v:Vector3D = polygon.vertices[i].pos;
			var vert = new AwayCSGVertex(cast(polygon.vertices[i])); //not sure about the cast
			var uv = vert.uv;
			
			vertices[(i*3)+0] = v.x * AWAY3D_VERTEX_CONVERSION_FACTOR;
			vertices[(i*3)+1] = v.y * AWAY3D_VERTEX_CONVERSION_FACTOR;
			vertices[(i*3)+2] = v.z * AWAY3D_VERTEX_CONVERSION_FACTOR;
			
			normals[(i*3)+0] = normal.x;
			normals[(i*3)+1] = normal.y;
			normals[(i*3)+2] = normal.z;
			
			uvs[(i*2)+0] = uv.x;
			uvs[(i*2)+1] = uv.y;

			indices[index++] = 0;
			indices[index++] = (i+1) % numVertices;
			indices[index++] = (i+2) % numVertices;

		}

		geometry.updateVertexData(vertices);
		geometry.updateVertexNormalData(normals);
		geometry.updateUVData(uvs);
		geometry.updateIndexData(indices);
		geometry.autoDeriveVertexTangents = true;
		// trace("material1 scaleU after:"+geometry.scaleU);
		
		return geometry;
	}
}
