A lib to draw complex polygon with rgba colors.

using require"canvas" you can create a new canvas object to use the api and draw using the internal functions.
The canvas storage all pixels information using numbers table, to simulate byte array, and when needed draw all information to the screen.

A simple exemple:<br />
  to create a 160 x 50 canvas fill the background with a purple color, and draw a white circle with 7 pixels radius in the canvas center:
```lua
local canvas = require"canvas"
local vector = require"vector"
local my_canvas = canvas:new(vector(160, 50))

--beginning to draw in the canvas
my_canvas:begin()
--set background to this canvas to 0xff00ff -> purple
my_canvas:setBackground(0xff00ff)
--fill all pixels starting in 1,1 with widht of 160, and height 50 with empty space " ".
my_canvas:fill(1,1, 160, 50, " ")
--draws the circle with center on 160/2 and 50/2 middle of canvas, with radius of 7 pixels and a step of pi/36.
--the step means that the draw function will calculate 72 pixels to create the circle. A circle have 2*pi rads, so each step increase pi/36, then (2*pi) / (pi / 36) -> 72
obj:drawCircle(vector(160/2,50/2), 7, 3.1415926535/36)
--call to stop the drawing.
obj:done()

--displays the canvas at 1,1 position in relation to the screen.
obj:display(vector(1,1))

--free all ram and vram buffers, this call is fundamental to use the canvas.
--when you create a canvas, the canvas create 8 ram buffers (3 to background, 3 to foreground, 1 to char, 1 to change_buffer) and a vram buffer.
--the background use one buffer for each color component r|g|b, the same to foreground, the char and change_buffer is a internal way to avoid gpu calls.
--the vram is a block of 160 * 50 pixels, create in new() function, and is used when the done() function is called
--the done function draws in vram, so the display don't need to re draws the canvas, only copys to the screen.
obj:free();
```
