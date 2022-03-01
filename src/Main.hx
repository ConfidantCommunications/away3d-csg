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
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

import openfl.events.Event;
import openfl.geom.Vector3D;

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
	private var resultMesh:Mesh;
	private var mesh1:Mesh;

	private var cubeMaterial:TextureMaterial;
	private var cube:Mesh;
	private var cubeCSGMesh:Mesh;
	
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
		_view.camera.y = 20;
		_view.camera.lookAt(new Vector3D());
		
		_view.antiAlias = 4;
		
		initLights();
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
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
		
		cubeMaterial = new TextureMaterial(Cast.bitmapTexture("assets/trinket_diffuse.jpg"));
		cubeMaterial.specularMap = Cast.bitmapTexture("assets/trinket_specular.jpg");
		cubeMaterial.normalMap = Cast.bitmapTexture("assets/trinket_normal.jpg");
		cubeMaterial.lightPicker = lightPicker;
		cubeMaterial.mipmap = false;

		cube = new Mesh(new CubeGeometry(40,40,40,1,1,1,false));
		cube.subMeshes[0].material = cubeMaterial;
		cube.x = 50;
		_view.scene.addChild(cube);

		// trace("Cube ====================");
		// dumpGeom( cube );
		// for (sg in cube.geometry.subGeometries)
		// 	trace("VertexData-geoms:"+sg.vertexData);

		material1.lightPicker = lightPicker;
		material2.lightPicker = lightPicker;
		material3.lightPicker = lightPicker;
				
		var redCube:Mesh = new Mesh(new CubeGeometry(40,40,40), material1);//red
		redCube.y = redCube.z = 20;
		redCube.x = 20;
		redCube.rotationX = 23;
		redCube.rotationY = 64;
		var sphere:Mesh = new Mesh(new SphereGeometry(40), material2);//green
		sphere.y = 30;
		sphere.z = 10;
		sphere.x = -10;

		var g = new Geometry();
		g.addSubGeometry(cube.geometry.subGeometries[0].clone());
		var combinedMesh = new Mesh(g,null);
		MeshHelper.applyPosition(combinedMesh,40,0,0);
		g.addSubGeometry(redCube.geometry.subGeometries[0]);
		
		combinedMesh.subMeshes[0].material = cubeMaterial;
		combinedMesh.subMeshes[1].material = material1;//red

		var redCubeCSG:CSG = AwayCSG.fromMesh(redCube);
		var sphereCSG:CSG = AwayCSG.fromMesh(sphere);
		var combinedCSG:CSG = AwayCSG.fromMesh(combinedMesh);
		var cubeCSG = AwayCSG.fromMesh(cube);//mesh1
		
		var resultCSG:CSG = combinedCSG.subtract(sphereCSG);
		// var result:CSG = csg1.union(csg2);
		// var result:CSG = csg1.intersect(csg2);
		// var cube = CSG.cube(null,new Vector3D(.9,.9,.9));
		// _mesh = AwayCSG.toMesh(result);//result uses toSubGeometry, this should be okay
		// _mesh.showBounds = true;

		resultMesh = AwayCSG.toMesh(resultCSG);//result uses toSubGeometry, this should be okay
		resultMesh.showBounds = true;

		resultMesh.x = -30;
		_view.scene.addChild(resultMesh); 

		// GC:Debug 
		// trace("resultMesh ====================");
		// dumpGeom( resultMesh );
		// for (sg in resultMesh.geometry.subGeometries)
		// 	trace("VertexData-geoms:"+sg.vertexData);
	}
	
	// GC:Debug 
	// Dump function to look at the vertexData
	function dumpGeom(m:Mesh) {
		var step = 3;
		trace("SubMeshes="+m.subMeshes.length);
		for  (subMesh in m.subMeshes) {
			var g = subMesh.subGeometry;
			var stride = g.vertexStride ; //13
			var uvoffset:Int = g.UVOffset;//2;
			var vnoffset:Int = g.vertexNormalOffset;
	
			trace("Stride="+stride+" UVOffset="+uvoffset+" VNOffset="+vnoffset+" step="+step+" indexLength="+g.indexData.length);
			var i = 0;
			while(i < g.indexData.length) {
				var a:Int = g.indexData[i+0];
				var b:Int = g.indexData[i+1];
				var c:Int = g.indexData[i+2];

				var t = "";
				t += "V0("+ g.vertexData[(a*stride)+0]+", "+g.vertexData[(a*stride)+1]+", "+g.vertexData[(a*stride)+2]+") ";
				t += "V1("+ g.vertexData[(b*stride)+0]+", "+g.vertexData[(b*stride)+1]+", "+g.vertexData[(b*stride)+2]+") ";
				t += "V2("+ g.vertexData[(c*stride)+0]+", "+g.vertexData[(c*stride)+1]+", "+g.vertexData[(c*stride)+2]+") ";
	
				t += "UV0("+ g.UVData[(a*stride)+uvoffset+0]+", "+g.UVData[(a*stride)+uvoffset+1]+") ";
				t += "UV1("+ g.UVData[(b*stride)+uvoffset+0]+", "+g.UVData[(b*stride)+uvoffset+1]+") ";
				t += "UV2("+ g.UVData[(c*stride)+uvoffset+0]+", "+g.UVData[(c*stride)+uvoffset+1]+") ";
				
				t += "N0("+ g.vertexNormalData[(a*stride)+vnoffset+0]+", "+g.vertexNormalData[(a*stride)+vnoffset+1]+", "+g.vertexNormalData[(a*stride)+vnoffset+2]+") ";
				t += "N1("+ g.vertexNormalData[(b*stride)+vnoffset+0]+", "+g.vertexNormalData[(b*stride)+vnoffset+1]+", "+g.vertexNormalData[(b*stride)+vnoffset+2]+") ";
				t += "N2("+ g.vertexNormalData[(c*stride)+vnoffset+0]+", "+g.vertexNormalData[(c*stride)+vnoffset+1]+", "+g.vertexNormalData[(c*stride)+vnoffset+2]+") ";
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
		// if (_mesh != null) {
		// 	_mesh.rotationY += 1;
		// }
		// if (mesh1 != null) {
		// 	mesh1.rotationY -= 1;
		// }
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

	/**
	 * stage listener for keyboard events
	 */
	private function onKeyDown(event:KeyboardEvent = null):Void
	{
		if (event.keyCode == Keyboard.UP) 
			_view.camera.z += event.shiftKey ? 10 : 1;
		if (event.keyCode == Keyboard.DOWN) 
			_view.camera.z -= event.shiftKey ? 10 : 1;
		if (event.keyCode == Keyboard.LEFT)
			resultMesh.rotationY = cube.rotationY += event.shiftKey ? 10 : 1;
		if (event.keyCode == Keyboard.RIGHT)
			resultMesh.rotationY = cube.rotationY -= event.shiftKey ? 10 : 1;
	}
}
