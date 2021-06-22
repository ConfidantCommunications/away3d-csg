package;

import flash.geom.Vector3D;
import away3d.csg.AwayCSG;

import away3d.containers.ObjectContainer3D;
import away3d.containers.View3D;
import away3d.core.base.*;
import away3d.entities.Mesh;
import away3d.lights.DirectionalLight;
import away3d.materials.*;
import away3d.materials.lightpickers.StaticLightPicker;
import away3d.primitives.CubeGeometry;
import away3d.primitives.SphereGeometry;
import away3d.utils.Cast;
import away3d.tools.helpers.MeshHelper;
import away3d.csg.CSG;
import openfl.Assets;
import openfl.display.*;

// import openfl.display.Sprite;
// import openfl.display.StageAlign;
// import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.geom.Vector3D;
// import flash.utils.getTimer;
// import openfl.utils.

@:access(away3d.core.base.ISubGeometry)
class Main extends Sprite
{
	//engine variables
	private var _view:View3D;
	
	//light objects
	private var light1:DirectionalLight;
	private var light2:DirectionalLight;
	private var lightPicker:StaticLightPicker;
	
	//scene objects
	private var _mesh:Mesh;
	private var mesh1:Mesh;
	
	public function new()
	{
		super();
		
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		//setup the view
		_view = new View3D();
		addChild(_view);
		
		//setup the camera
		_view.camera.z = -100;
		_view.camera.y = 50;
		_view.camera.lookAt(new Vector3D());
		
		_view.antiAlias = 4;
		
		initLights();
		
		stage.addEventListener(Event.RESIZE, onResize);
		onResize();
		
		//setup the render loop
		_view.addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		
		test();
	}
	
	private function test():Void
	{
		var material1:ColorMaterial = new ColorMaterial(0xff0000);//red
		var material2:ColorMaterial = new ColorMaterial(0x00ff00);//green
		var material3:ColorMaterial = new ColorMaterial(0x0000ff);//blue
		var grassMaterial:TextureMaterial = new TextureMaterial(Cast.bitmapTexture("assets/grass.jpg"));//grass
		
		
		material1.lightPicker = lightPicker;
		material2.lightPicker = lightPicker;
		material3.lightPicker = lightPicker;
		grassMaterial.lightPicker = lightPicker;
		
		mesh1 = new Mesh(new CubeGeometry(1,1,1), grassMaterial);//grass
		// GC:Debug 
		// trace("MESH1 ====================");
		// dumpGeom( mesh1 );
		var mesh1b:Mesh = new Mesh(new CubeGeometry(1,1,1), material1);//red
		var mesh2:Mesh = new Mesh(new SphereGeometry(1), material2);//green
		mesh2.y = mesh2.z = 0.5;
		mesh2.x = 0.2;
		// var mesh2:Mesh = new Mesh(new CubeGeometry(10,10,10), material1);
		// var submesh1:SubMesh = new SubMesh(cast(new CubeGeometry(1,1,1)), null,material1);
		// var submesh2:SubMesh = new SubMesh(cast(new CubeGeometry(1,1,1)), null,material2);
		// submesh1.x = 1;
		var g = new Geometry();
		g.addSubGeometry(mesh1.geometry.subGeometries[0]);
		var combinedMesh = new Mesh(g,null);
		MeshHelper.applyPosition(combinedMesh,1,0,0);
		g.addSubGeometry(mesh1b.geometry.subGeometries[0]);
		
		// combinedMesh.material.dispose();
		combinedMesh.subMeshes[0].material = material1;//red
		combinedMesh.subMeshes[1].material = grassMaterial;//green
		trace("submesh count:"+combinedMesh.subMeshes.length);

		//this is not retained after conversion to CSG:
		// for(m in mesh1.subMeshes){
			// m.subGeometry.scaleUV(2,2);
			
		// }
		//or:
		// mesh1.geometry.scaleUV(10,10);

		// _view.scene.addChild(combinedMesh); 
		var csg1:CSG = AwayCSG.fromMesh(combinedMesh);//mesh1
		var csg2:CSG = AwayCSG.fromMesh(mesh2);//green sphere
		// GC:Debug 
		// var m1:CSG = AwayCSG.fromMesh(mesh1);
		// var m1b:CSG = AwayCSG.fromMesh(mesh1b);
		
		
		var result:CSG = csg1.subtract(csg2);
		// var result:CSG = csg1.union(csg2);
		// var result:CSG = csg1.intersect(csg2);
		// var cube = CSG.cube(null,new Vector3D(.9,.9,.9));
		_mesh = AwayCSG.toMesh(result);//result uses toSubGeometry, this should be okay

		// GC:Debug 
		// trace("_MESH ====================");
		// dumpGeom( _mesh );

		if(_mesh != null){
			_mesh.scaleY = _mesh.scaleX = _mesh.scaleZ = 40;
			mesh1.scaleY = mesh1.scaleX = mesh1.scaleZ = 20;

			//this shows solid:
			/* for(m in _mesh.subMeshes){
				m.material = grassMaterial;//green

			} */

			_view.scene.addChild(_mesh); 
			_view.scene.addChild(mesh1); 
			mesh1.x = 80;
			
		}
		
		/* 
		// THIS SECTION WORKS AND DISPLAYS IN AWAY3D.
		var cube = CSG.cube(null,new Vector3D(.9,.9,.9));
		var sphere = CSG.sphere(new Vector3D(0.2,0.8,0.1),1.3);//center:Vector3D=null, radius:Float=1, slices:Int=16, stacks:Int=8
		var polygons = cube.subtract(sphere).toPolygons();
		// var polygons = cube.union(sphere).toPolygons();
		// var polygons = cube.intersect(sphere).toPolygons();
		trace("Here's a CSG cube");
		trace(cube.toPolygons());

		var subs = new Array<SubGeometry>();
		for(p in polygons){
			subs.push(AwayCSG.toSubGeometry(p));

		}

		var geometry = new Geometry();
		for (sub in subs) { //will cast sub from MaterialBase to SubGeometry
			geometry.addSubGeometry(sub);
		}

		_mesh = new Mesh(geometry, material1); */

	}
	
	// GC:Debug 
	// Dump function to look at the vertexData
	function dumpGeom(m:Mesh) {
		var step = 3;
		trace("SubMeshes="+m.subMeshes.length);
		for  (subMesh in m.subMeshes) {
			var g = subMesh.subGeometry;
			var vstride = g.vertexStride ; //13
			var uvstride:Int = g.UVStride;//2;
			var nstride:Int = g.vertexNormalStride;

			trace("VStride="+vstride+" UVStride="+uvstride+" NStride="+nstride+" step="+step);
			var i = 0;
			while(i < g.indexData.length) {
				var a:Int = g.indexData[i+0];
				var b:Int = g.indexData[i+1];
				var c:Int = g.indexData[i+2];

				var t = "";
				t += "V0("+ g.vertexData[(a*vstride)+0]+", "+g.vertexData[(a*vstride)+1]+", "+g.vertexData[(a*vstride)+2]+") ";
				t += "V1("+ g.vertexData[(b*vstride)+0]+", "+g.vertexData[(b*vstride)+1]+", "+g.vertexData[(b*vstride)+2]+") ";
				t += "V2("+ g.vertexData[(c*vstride)+0]+", "+g.vertexData[(c*vstride)+1]+", "+g.vertexData[(c*vstride)+2]+") ";
	
				t += "UV0("+ g.UVData[(a*uvstride)+0]+", "+g.UVData[(a*uvstride)+1]+") ";
				t += "UV1("+ g.UVData[(b*uvstride)+0]+", "+g.UVData[(b*uvstride)+1]+") ";
				t += "UV2("+ g.UVData[(c*uvstride)+0]+", "+g.UVData[(c*uvstride)+1]+") ";
				
				t += "N0("+ g.vertexNormalData[(a*nstride)+0]+", "+g.vertexNormalData[(a*nstride)+1]+", "+g.vertexNormalData[(a*nstride)+2]+") ";
				t += "N1("+ g.vertexNormalData[(b*nstride)+0]+", "+g.vertexNormalData[(b*nstride)+1]+", "+g.vertexNormalData[(b*nstride)+2]+") ";
				t += "N2("+ g.vertexNormalData[(c*nstride)+0]+", "+g.vertexNormalData[(c*nstride)+1]+", "+g.vertexNormalData[(c*nstride)+2]+") ";
				trace(t);
				
				i += step;
			}
		}
	}

	/**
	 * Initialise the lights
	 */
	private function initLights():Void
	{
		light1 = new DirectionalLight();
		light1.direction = new Vector3D(1, -1, 0);
		light1.color = 0xffffff;
		light1.ambient = 0.1;
		light1.diffuse = 0.7;
		
		_view.scene.addChild(light1);
		
		light2 = new DirectionalLight();
		light2.direction = new Vector3D(0, -1, 0);
		light2.color = 0xff0000;
		light2.ambient = 0.1;
		light2.diffuse = 0.7;
		
		_view.scene.addChild(light2);
		
		lightPicker = new StaticLightPicker([light1, light2]);
	}
	
	/**
	 * render loop
	 */
	private function _onEnterFrame(e:Event):Void
	{
		if (_mesh != null) {
			_mesh.rotationY += 1;
		}
		if (mesh1 != null) {
			mesh1.rotationY -= 1;
		}
		// light1.direction = new Vector3D(Math.sin(getTimer()/10000)*150000, 1000, Math.cos(getTimer()/10000)*150000);
		_view.render();
	}
	
	/**
	 * stage listener for resize events
	 */
	private function onResize(event:Event = null):Void
	{
		_view.width = stage.stageWidth;
		_view.height = stage.stageHeight;
	}
}
