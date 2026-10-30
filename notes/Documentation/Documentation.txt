This package adds a "hitspark" function to create hitspark effects.

the function variables are:
xpos : Real - X position of the spark. (Defaults to the X position of the instance that called the function)

ypos : Real - Y position of the spark. (Defaults to the Y position of the instance that called the function)

xscle : Real - X scale of the spark. (Defaults to the X scale position of the instance that called the function)

yscle : Real - Y scale of the spark. (Defaults to the Y scale position of the instance that called the function)

type : Sprite Asset - Sprite that the spark uses. (Defaults to the built-in light hitspark)*

audio : List - Audios that will play when the function is called. (Defaults to no sounds)**
The audio list is built as such: [[Audio Asset, Gain (Real)], [Audio Asset, Gain (Real)], ...]


This package also includes a "Hitspark area" object which creates hitsparks in its bounding box.

It works as such:
You have to set variables within the objects creation code, and those variables are:
cspeed : Real - Delay (in steps) between every batch of sparks created.

amount : Real - Amount of sparks created every batch.

types : List with Sprite Assets - List of the Hitspark types that Hitspark area will create.

size : List with Reals - List with the range of hitspark sizes the Hitspark area will create.
It is built as such: [Minimum size (Real), Maximum  size (Real)]

*The Built-in spark types are:
"hitspark_light"
"hitspark_medium"
"hitspark_hard"
You can also create your own hitspark types, just be sure to make the origin of the sprite Middle Centre.

**For the sounds, you can check the sounds folder of the package, or you can use your own sounds.