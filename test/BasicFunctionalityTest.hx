package;

import Components;
import echoes.Echoes;
import echoes.Entity;
import echoes.SystemList;
import echoes.utils.Timestep;
import MethodCounter.assertTimesCalled;
import Systems;
import utest.Assert;
import utest.Test;

class BasicFunctionalityTest extends Test {
	private function teardown():Void {
		Echoes.reset();
		MethodCounter.reset();
	}
	
	//Tests may be run in any order, but not in parallel.
	
	private function testEntities():Void {
		//Make an inactive entity.
		var entity:Entity = new Entity(false);
		Assert.equals(Inactive, entity.status());
		Assert.isFalse(entity.isActive());
		Assert.isFalse(entity.isDestroyed());
		Assert.equals(0, Echoes.activeEntities.length);
		
		//Activate it.
		entity.activate();
		Assert.isTrue(entity.isActive());
		Assert.isFalse(entity.isDestroyed());
		Assert.equals(1, Echoes.activeEntities.length);
		
		//Add a component.
		entity.add(STAR);
		Assert.isTrue(entity.exists(Shape));
		
		//Deactivate the entity.
		entity.deactivate();
		Assert.isTrue(entity.exists(Shape));
		
		//Destroy it.
		entity.destroy();
		Assert.isFalse(entity.exists(Shape));
		Assert.equals(Destroyed, entity.status());
		Assert.equals(1, @:privateAccess Entity.idPool.length);
		
		//Make a new entity (should use the same ID as the old).
		var newEntity:Entity = new Entity();
		Assert.equals(entity, newEntity);
		Assert.equals(0, @:privateAccess Entity.idPool.length);
	}
	
	private function testComponents():Void {
		//Create the entity.
		var blackSquare:Entity = new Entity();
		Assert.isTrue(blackSquare.isActive());
		Assert.equals(0, Lambda.count(blackSquare.getComponents()));
		
		//Create some interchangeable components.
		var black:Color = 0x000000;
		var nearBlack:Color = 0x111111;
		var name:Name = "blackSquare";
		var shortName:Name = "blSq";
		
		//Add components.
		blackSquare.add(black);
		Assert.equals(black, blackSquare.get(Color));
		Assert.isFalse(blackSquare.exists(Int));
		
		blackSquare.add(0xFFFFFF);
		Assert.notEquals(blackSquare.get(Color), blackSquare.get(Int));
		
		blackSquare.add(SQUARE);
		Assert.equals(SQUARE, blackSquare.get(Shape));
		
		blackSquare.add(name);
		Assert.equals(name, blackSquare.get(Name));
		Assert.isFalse(blackSquare.exists(String));
		
		//Overwrite existing components.
		blackSquare.add(nearBlack, shortName);
		Assert.equals(nearBlack, blackSquare.get(Color));
		Assert.equals(shortName, blackSquare.get(Name));
		
		//Remove components.
		blackSquare.remove(Shape, Name);
		Assert.isTrue(blackSquare.exists(Color));
		Assert.isFalse(blackSquare.exists(Shape));
		Assert.isFalse(blackSquare.exists(Name));
		
		blackSquare.remove(Shape);
		Assert.isTrue(blackSquare.exists(Color));
		Assert.isFalse(blackSquare.exists(Shape));
		
		blackSquare.removeAll();
		Assert.isFalse(blackSquare.exists(Color));
	}
	
	private function testInactiveEntities():Void {
		var inactive:Entity = new Entity(false);
		Assert.isFalse(inactive.isActive());
		Assert.equals(0, Echoes.activeEntities.length);
		
		Echoes.addSystem(new AppearanceSystem());
		assertTimesCalled(0, "AppearanceSystem.colorAdded");
		
		//Add some components the system looks for.
		inactive.add((0x0000FF:Color));
		assertTimesCalled(0, "AppearanceSystem.colorAdded");
		
		//The system should notice when the entity's state changes.
		inactive.activate();
		assertTimesCalled(1, "AppearanceSystem.colorAdded");
		
		assertTimesCalled(0, "AppearanceSystem.colorRemoved");
		
		inactive.deactivate();
		assertTimesCalled(1, "AppearanceSystem.colorRemoved");
	}
	
	private function testAddAndRemoveEvents():Void {
		//Add a system.
		var appearanceSystem:AppearanceSystem = new AppearanceSystem();
		Assert.equals(0, Echoes.activeSystems.length);
		
		Echoes.addSystem(appearanceSystem);
		Assert.equals(1, Echoes.activeSystems.length);
		assertTimesCalled(0, "AppearanceSystem.colorAdded");
		
		//Add a red line.
		Assert.equals(0, Echoes.activeEntities.length);
		
		var redLine:Entity = new Entity();
		Assert.equals(1, Echoes.activeEntities.length);
		
		redLine.add((0xFF0000:Color), Shape.LINE);
		assertTimesCalled(1, "AppearanceSystem.colorAdded");
		assertTimesCalled(1, "AppearanceSystem.colorAndShapeAdded");
		assertTimesCalled(0, "AppearanceSystem.colorAndShapeRemoved");
		
		//Add a circle.
		var circle:Entity = new Entity();
		Assert.equals(2, Echoes.activeEntities.length);
		
		circle.add(CIRCLE);
		assertTimesCalled(1, "AppearanceSystem.colorAdded");
		assertTimesCalled(2, "AppearanceSystem.shapeAdded");
		assertTimesCalled(1, "AppearanceSystem.colorAndShapeAdded");
		assertTimesCalled(0, "AppearanceSystem.colorAndShapeRemoved");
		
		//Create and activate a system AFTER adding the component.
		circle.add(("circle":Name));
		assertTimesCalled(0, "NameSystem.nameAdded", "NameSystem doesn't exist but its method was still called.");
		
		var nameSystem:NameSystem = new NameSystem();
		
		redLine.add(("redLine":Name));
		assertTimesCalled(0, "NameSystem.nameAdded", "NameSystem isn't active but its method was still called.");
		
		Echoes.addSystem(nameSystem);
		assertTimesCalled(2, "NameSystem.nameAdded");
		assertTimesCalled(0, "NameSystem.nameRemoved");
		
		//Deconstruct an entity.
		redLine.remove(Shape);
		assertTimesCalled(0, "AppearanceSystem.colorRemoved");
		assertTimesCalled(1, "AppearanceSystem.shapeRemoved");
		assertTimesCalled(1, "AppearanceSystem.colorAndShapeRemoved");
		
		redLine.remove(Color);
		assertTimesCalled(1, "AppearanceSystem.colorRemoved");
		assertTimesCalled(1, "AppearanceSystem.colorAndShapeRemoved");
		
		redLine.removeAll();
		assertTimesCalled(1, "NameSystem.nameRemoved");
		
		//Deactivate a system.
		Echoes.removeSystem(nameSystem);
		assertTimesCalled(2, "NameSystem.nameRemoved");
		
		//Destroy the remaining entity.
		assertTimesCalled(1, "AppearanceSystem.shapeRemoved");
		
		circle.destroy();
		assertTimesCalled(2, "NameSystem.nameRemoved");
		assertTimesCalled(2, "AppearanceSystem.shapeRemoved");
	}
	
	private function testUpdateEvents():Void {
		//Create a `TimeCountSystem` and use a custom `Timestep`.
		var systems:SystemList = new SystemList(new OneSecondTimestep());
		Echoes.addSystem(systems);
		
		var timeCountSystem:TimeCountSystem = new TimeCountSystem();
		Assert.equals(0, timeCountSystem.totalTime);
		
		systems.add(timeCountSystem);
		
		//Create some entities, but none with both color and shape.
		var green:Entity = new Entity().add((0x00FF00:Color));
		Assert.equals(0, timeCountSystem.colorTime);
		
		var star:Entity = new Entity().add(STAR, ("Proxima Centauri":Name));
		Assert.equals(0, timeCountSystem.shapeTime);
		
		//Run an update.
		Echoes.update();
		Assert.equals(1, timeCountSystem.totalTime);
		Assert.equals(1, timeCountSystem.colorTime);
		Assert.equals(1, timeCountSystem.shapeTime);
		Assert.equals(0, timeCountSystem.colorAndShapeTime);
		
		//Give one entity both a color and shape.
		star.add((0xFFFFFF:Color));
		
		//Run another few updates. (`colorTime` should now increment twice per
		//update, since now two entities have color.)
		Echoes.update();
		Assert.equals(2, timeCountSystem.totalTime);
		Assert.equals(3, timeCountSystem.colorTime);
		Assert.equals(2, timeCountSystem.shapeTime);
		Assert.equals(1, timeCountSystem.colorAndShapeTime);
		
		Echoes.update();
		Assert.equals(3, timeCountSystem.totalTime);
		Assert.equals(5, timeCountSystem.colorTime);
		Assert.equals(3, timeCountSystem.shapeTime);
		Assert.equals(2, timeCountSystem.colorAndShapeTime);
	}
}

/**
 * A custom `Timestep` that advances 1 second whenever `Echoes.update()` is
 * called, regardless of the real-world time elapsed.
 */
class OneSecondTimestep extends Timestep {
	public override function advance(time:Float):Void {
		super.advance(1);
	}
}
