package echoes.core.macro;

#if macro

import echoes.core.macro.MacroTools.*;
import haxe.macro.Expr;

using echoes.core.macro.MacroTools;
using haxe.macro.Context;
using haxe.macro.ComplexTypeTools;
using haxe.macro.Type;
using Lambda;

class ComponentBuilder {
	private static var componentContainerTypeCache = new Map<String, Type>();
	
	public static function createComponentContainerType(componentComplexType:ComplexType) {
		var componentTypeName:String = componentComplexType.followName();
		var componentContainerTypeName:String = "ContainerOf" + componentComplexType.typeName();
		var componentContainerType:Type = componentContainerTypeCache.get(componentContainerTypeName);
		
		if(componentContainerType != null) {
			return componentContainerType;
		}
		
		var componentContainerTypePath:TypePath = {
			pack: [],
			name: componentContainerTypeName
		};
		var componentContainerComplexType:ComplexType = TPath(componentContainerTypePath);
		
		var viewsOfComponent:String = ViewsOfComponentBuilder.getViewsOfComponent(componentComplexType).followName();
		
		var def = macro class $componentContainerTypeName implements echoes.core.ICleanableComponentContainer {
			private static var instance = new $componentContainerTypePath();
			
			@:keep public static inline function inst():$componentContainerComplexType {
				return instance;
			}
			
			private var storage = new echoes.core.Storage<$componentComplexType>();
			
			private function new() {
				@:privateAccess echoes.Workflow.definedContainers.push(this);
			}
			
			public inline function get(id:Int):$componentComplexType {
				return storage.get(id);
			}
			
			public inline function exists(entity:echoes.Entity):Bool {
				return storage.exists(entity);
			}
			
			public inline function add(entity:echoes.Entity, c:$componentComplexType):Void {
				storage.set(entity, c);
				
				if(entity.isActive()) @:privateAccess $i{ viewsOfComponent }.inst().addIfMatched(entity);
			}
			
			public inline function remove(entity:echoes.Entity):Void {
				if(entity.isActive()) @:privateAccess $i{ viewsOfComponent }.inst().removeIfExists(entity);
				
				storage.remove(entity);
			}
			
			public inline function reset():Void {
				storage.clear();
			}
			
			public inline function print(id:Int):String {
				return $v{componentTypeName} + "=" + Std.string(storage.get(id));
			}
		}
		
		Context.defineType(def);
		
		componentContainerType = componentContainerComplexType.toType();
		
		componentContainerTypeCache.set(componentContainerTypeName, componentContainerType);
		
		Report.componentNames.push(componentTypeName);
		Report.gen();
		
		return componentContainerType;
	}
	
	public static function getComponentContainer(componentComplexType:ComplexType):ComplexType {
		return createComponentContainerType(componentComplexType).toComplexType();
	}
}

#end
