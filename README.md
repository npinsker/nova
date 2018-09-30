# Nova
![N|Solid](nova.png)

Nova is a library for quickly creating 2D games in Haxe.

### Why Haxe?

I've tried a lot of game engines for 2D games. I think Haxe (plus OpenFL) is among the best. Here's why:

- powerful, statically typed language
- no boilerplate to fight with
- huge amount of control over individual pixels
- cross-compilation to tons of different languages, including HTML5
- 100% free and open-source

Despite this, Haxe has very few high-level game libraries. Nova is an attempt to expand in that direction!

### Installation

Nova uses both **Haxe** and **HaxeFlixel** as dependencies. Installation instructions for both are [here](http://haxeflixel.com/documentation/getting-started/).

Then, just install via haxelib (which comes with Haxe): ```haxelib install nova```

# Overview

## Director

Director allows you to chain animations together. You can queue up animations (or functions, or both) to be executed after any set of animations is finished.

Good for things like "if a bunch of enemies are moving, end their turn after they're all done".

## DialogBox

A powerful, highly customizable dialog box for use in just about any game. Supports dynamic resizing, text effects, portraits, and more.

## FlxLocalSprite

Similar to FlxSprite, but with the property that each sprite has a *local* position relative to its parent. For example:
```
var parent:FlxLocalSprite = new FlxLocalSprite(20, 20);
var child:FlxLocalSprite = new FlxLocalSprite(20, 20);
add(parent);
parent.add(child);
```

then ```child``` will appear at the position (40, 40). If ```parent``` moves, then ```child``` will move by the same amount.

(More detailed documentation to come!)
