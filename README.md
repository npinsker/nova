# Nova
![N|Solid](nova.png)

Nova is a library for quickly creating 2D games in Haxe. It's not actively maintained.

### Installation

Nova uses both **Haxe** and **HaxeFlixel** as dependencies. Installation instructions for both are [here](http://haxeflixel.com/documentation/getting-started/).

Then, just install via haxelib (which comes with Haxe): ```haxelib install nova```

# Overview

## Director

Director allows you to chain animations together. You can queue up animations (or functions, or both) to be executed after any set of animations is finished. Director supports programming custom ease functions as well.

Good for things like "if a bunch of enemies are moving, end their turn after they're all done".

## DialogBox

A powerful, highly customizable dialog box for use in just about any game. Supports dynamic resizing, text effects, portraits, arbitrary callbacks, and more.

## FlxLocalSprite

Similar to FlxSprite, but with the property that each sprite has a *local* position relative to its parent. For example:
```
var parent:FlxLocalSprite = new FlxLocalSprite(20, 20);
var child:FlxLocalSprite = new FlxLocalSprite(20, 20);
add(parent);
parent.add(child);
```

then ```child``` will appear at the position (40, 40). If ```parent``` moves, then ```child``` will move by the same amount.

## NovaEmitter

A simple, FlxSprite-based emitter where each pixel can be arbitrarily programmed.

## CollisionManager

A multi-pronged tool for checking collisions between sprites that's faster and simpler than Flixel's approach.

## RichText

Supports moving and animated text boxes, including programming your own behavior.

## TiledObjectLoader & TiledRenderer

Tools for quickly extracting structured information from Tiled (`.tmx` format) maps.