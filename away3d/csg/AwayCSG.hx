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

// GC:
// Introduced new CompactSubGeometry data holder
// to accumulate all the verts, normals, uvs and indexes
// for a SubMesh
typedef CompactSubGeomData = {
	var verts:Vector<Float>;
	var uvs:Vector<Float>;
	var normals:Vector<Float>;
	var indices:Vector<Int>;
}

class AwayCSG
{

	private static inline var AWAY3D_VERTEX_CONVERSION_FACTOR = 1;

	//this one works in Main library
	public static function fromMesh(mesh:Mesh):CSG
	{
		var polygons:Array<Polygon> = new Array<Polygon>();
		trace("csg from mesh");
		var i:Int = 0;
		for  (subMesh in mesh.subMeshes) {
			polygons = polygons.concat(fromSubGeometry(mesh, subMesh.subGeometry, subMesh));
		}
		// trace(polygons);
		return CSG.fromPolygons(polygons);
	} 
	
	/**
	 * 
	 */ 
	public static function fromSubGeometry(mesh:Mesh, geometry:ISubGeometry, subMesh:SubMesh):Array<Polygon>
	{
		var polygons:Array<Polygon> = new Array<Polygon>();

		var step = 3;

		var stride = geometry.vertexStride ; //13
		var uvoffset:Int = geometry.UVOffset;//2;
		var vnoffset:Int = geometry.vertexNormalOffset;

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
			
			uv1.x = geometry.UVData[(a*stride)+uvoffset+0];
			uv1.y = geometry.UVData[(a*stride)+uvoffset+1];

			uv2.x = geometry.UVData[(b*stride)+uvoffset+0];
			uv2.y = geometry.UVData[(b*stride)+uvoffset+1];

			uv3.x = geometry.UVData[(c*stride)+uvoffset+0];
			uv3.y = geometry.UVData[(c*stride)+uvoffset+1];
			
			vn1.x = geometry.vertexNormalData[(a*stride)+vnoffset+0];
			vn1.y = geometry.vertexNormalData[(a*stride)+vnoffset+1];
			vn1.z = geometry.vertexNormalData[(a*stride)+vnoffset+2];
			vn2.x = geometry.vertexNormalData[(b*stride)+vnoffset+0];
			vn2.y = geometry.vertexNormalData[(b*stride)+vnoffset+1];
			vn2.z = geometry.vertexNormalData[(b*stride)+vnoffset+2];
			vn3.x = geometry.vertexNormalData[(c*stride)+vnoffset+0];
			vn3.y = geometry.vertexNormalData[(c*stride)+vnoffset+1];
			vn3.z = geometry.vertexNormalData[(c*stride)+vnoffset+2];
			
			vertices.push(new AwayCSGVertex(v1, vn1, uv1)); //works with a regular vertex
			vertices.push(new AwayCSGVertex(v2, vn2, uv2));
			vertices.push(new AwayCSGVertex(v3, vn3, uv3));
			
			if(subMesh.material != null){
				polygons.push(new Polygon(vertices, subMesh.material));
			} else {
				polygons.push(new Polygon(vertices, mesh.material));
			}

			i += step;
		}
		return polygons;
	}
	
	public static function toMesh(csg:CSG):Mesh
	{
		var polygons:Array<Polygon> = csg.toPolygons();
		// GC: Changed the byMaterial to use the CompactSubGeomData
		var byMaterial:Dictionary<Any,CompactSubGeomData> = new Dictionary<Any,CompactSubGeomData>();
		var mesh = new Mesh(null, null);

		// GC: Iterate over the polgons and add each to the corresponding 
		// material compactSubGeomData object
		for (p in polygons) {
			if (Std.is(p.shared, MaterialBase)) {
				if (byMaterial[p.shared]==null) {
					byMaterial[p.shared] = { verts: null, uvs: null, normals: null, indices: null };
					byMaterial[p.shared].verts = new Vector<Float>();
					byMaterial[p.shared].uvs = new Vector<Float>();
					byMaterial[p.shared].normals = new Vector<Float>();
					byMaterial[p.shared].indices = new Vector<Int>();
				}
				addPoly(byMaterial[p.shared], p);
			}
		}

		// GC: Once all the polygons have been processed into each
		// compactsubgeomdata, build the actual CompactSubGeometry
		for (matKey in byMaterial) {
			var csgData = byMaterial[matKey];
			var csg = new CompactSubGeometry();
			csg.fromVectors( csgData.verts, csgData.uvs, csgData.normals, null );
			csg.updateIndexData( csgData.indices );
			csg.autoDeriveVertexTangents = true;
			mesh.subMeshes.push( new SubMesh(csg, mesh, matKey) );
			mesh.geometry.subGeometries.push( csg );
		}

		return mesh;
	}
	
	/*
	  Add the Polygon faces to the CompactSubGeomData and build it up
	  until there is a complete set of faces for the mesh
	*/
	private static function addPoly( csgd:CompactSubGeomData, poly:Polygon) {
		var numVertices = poly.vertices.length;
		var baseIndex = Std.int(csgd.verts.length / 3);
		
		// Add the main vertex data
		for (i in 0...numVertices) {
			var p:AwayCSGVertex = cast poly.vertices[i];
			var v = p.pos;
			var uv = p.uv;
			var normal = p.normal;

			csgd.verts = csgd.verts.concat( Vector.ofArray([ v.x * AWAY3D_VERTEX_CONVERSION_FACTOR, v.y * AWAY3D_VERTEX_CONVERSION_FACTOR, v.z * AWAY3D_VERTEX_CONVERSION_FACTOR ]));
			csgd.normals = csgd.normals.concat( Vector.ofArray([ normal.x, normal.y, normal.z ]) );
			csgd.uvs = csgd.uvs.concat( Vector.ofArray([ uv.x, uv.y ]) );
		}

		// Establish the indices data/vertex order
		var indices = [0, 1, 2];
		if (numVertices > 3)
			for (i in 2...numVertices-1)
				indices = indices.concat([0, i, i+1]);
		
		// Add the index using the vertex offset from the previous polygon 
		// (baseIndex : num of verts so far / 3)
		for (i in 0...indices.length)
			csgd.indices.push( baseIndex + indices[i] );
	}
}
