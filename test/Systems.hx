package;

import Components;
import echoes.Entity;
import echoes.System;
import MethodCounter;

class AppearanceSystem extends System implements IMethodCounter {
	@:a private function colorAdded(color:Color):Void {}
	@:u private function colorUpdated(color:Color):Void {}
	@:r private function colorRemoved(color:Color):Void {}
	
	@:add private function shapeAdded(shape:Shape, entity:Entity):Void {}
	@:upd private function shapeUpdated(shape:Shape, entity:Entity):Void {}
	@:rem private function shapeRemoved(shape:Shape, entity:Entity):Void {}
	
	@:added private function colorAndShapeAdded(shape:Shape, color:Color):Void {}
	@:updated private function colorAndShapeUpdated(shape:Shape, color:Color):Void {}
	@:removed private function colorAndShapeRemoved(shape:Shape, color:Color):Void {}
}

class NameSystem extends System implements IMethodCounter {
	@:add private function nameAdded(name:Name):Void {}
	@:update private function nameUpdated(name:Name):Void {}
	@:remove private function nameRemoved(name:Name):Void {}
}

class OptionalComponentSystem extends System implements IMethodCounter {
	@:add private function colorAndNameAdded(color:Color, ?shape:Shape, name:Name):Void {}
	@:update private function colorAndNameUpdated(color:Color, ?shape:Shape, name:Name):Void {}
	@:remove private function colorAndNameRemoved(color:Color, ?shape:Shape, name:Name):Void {}
}

class TimeCountSystem extends System implements IMethodCounter {
	public var colorTime:Float = 0;
	public var shapeTime:Float = 0;
	public var colorAndShapeTime:Float = 0;
	public var totalTime:Float = 0;
	
	@:update private function colorUpdated(color:Color, time:Float):Void {
		colorTime += time;
	}
	
	@:update private function shapeUpdated(shape:Shape, time:Float):Void {
		shapeTime += time;
	}
	
	@:update private function colorAndShapeUpdated(color:Color, shape:Shape, time:Float):Void {
		colorAndShapeTime += time;
	}
	
	@:update private function update(time:Float):Void {
		totalTime += time;
	}
}
