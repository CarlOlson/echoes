package echoes;

import echoes.Entity;
import echoes.Echoes;
import echoes.View;

class ComponentStorage<T> {
	public var name(default, null):String;
	
	/**
	 * All components of this type.
	 */
	private var storage:Map<Int, T> = new Map();
	
	/**
	 * All views that include this type of component.
	 */
	@:allow(echoes.ViewBase)
	private var relatedViews:Array<ViewBase> = [];
	
	private function new(name:String) {
		this.name = name;
		Echoes.componentStorage.push(this);
	}
	
	public inline function get(entity:Entity):T {
		return storage[entity];
	}
	
	public inline function exists(entity:Entity):Bool {
		return storage.exists(entity);
	}
	
	public function add(entity:Entity, component:T):Void {
		if(component == null) {
			remove(entity);
			return;
		}
		
		storage[entity] = component;
		
		if(entity.isActive()) {
			for(view in relatedViews) {
				@:privateAccess view.addIfMatched(entity);
				
				//Stop dispatching events if a listener removed it.
				if(!exists(entity)) {
					return;
				}
			}
		}
	}
	
	public function remove(entity:Entity):Void {
		var removedComponent:T = get(entity);
		storage.remove(entity);
		
		if(entity.isActive()) {
			for(view in relatedViews) {
				@:privateAccess view.removeIfExists(entity, this, removedComponent);
				
				//Stop dispatching events if a listener added it back.
				if(exists(entity)) {
					return;
				}
			}
		}
	}
	
	@:allow(echoes.Echoes)
	private inline function clear():Void {
		storage.clear();
	}
}

/**
 * A version of `ComponentStorage` that stores components of unknown type. As
 * this makes it unsafe to call `add()`, that function is disabled.
 */
@:forward(name, get, exists, remove, clear)
abstract DynamicComponentStorage(ComponentStorage<Dynamic>) {
	@:from private static inline function fromComponentStorage<T>(componentStorage:ComponentStorage<T>):DynamicComponentStorage {
		return cast componentStorage;
	}
}
