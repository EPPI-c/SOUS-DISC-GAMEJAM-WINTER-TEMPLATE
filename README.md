# Explanation:

## Love2d basics:

In love2d you have a bunch of functions that are called at specific moments
when your game launches.
You define in these functions what your game should do at those moments
The most important ones are

love.load() when the game loads it's run only once and should contain things
like loading assets and settings, initializing variables etc...

love.draw() is where you draw on the screen it's called repeatedly when the
game is running

love.update(dt) is where you should put most of your game logic, it gives
you dt which is the delta time basically time that has passed since it was
called the last time in seconds

love.keypressed/mousemoved/focus/resize etc...
these are called when, well what is stated in their name happened and you
can define how to react to these situations in them

## How I do stuff:

In a game we have different states like the menu state, pause state,
game state, deat state, etc...
each of these states wants to do something different with the love functions
we learned about above.
The most simple approach you can think of is probably using a bunch of if
statements to change what you're doing in each state, but this quickly gets
messy. So what I like to do is to use a statemachine.
Basically I'll make an object for all the love calls for each state
for example I'll make the game state and it'll have a draw, update etc...
functions. Then the statemachine will hold the object of the current state
and in the real love functions I'll call statemachine.draw(). I just change
what state is in the statemachine and all the love. functions will call the
correct functions.

You can make as many states as you want for example in a top down game
if you want to have a visual novel type dialogue in your game you could
make a state for that.

# Notes:
if you get warnings in main.lua about some of the love. functions it's
probably the fault of the build-stuff/node_modules folder
if you the game takes a lot of time to load it's probably the fault of
the build-stuff/node_modules folder
moving the build-stuff folder out of this project should fix that you
only need it to create an html version of the game anyways

damn you javascript!

the makelove.sh file is my build file it basically automates the process
of making a windows, linux and html version of the game.
you can use it as inspiration to make your own or just visit
https://love2d.org/wiki/Game_Distribution for more info
