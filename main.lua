-- Explanation:
--
-- Love2d basics:
--
-- In love2d you have a bunch of functions that are called at specific moments
-- when your game launches.
-- You define in these functions what your game should do at those moments
-- The most important ones are
--
-- love.load() when the game loads it's run only once and should contain things
-- like loading assets and settings, initializing variables etc...
--
-- love.draw() is where you draw on the screen it's called repeatedly when the
-- game is running
--
-- love.update(dt) is where you should put most of your game logic, it gives
-- you dt which is the delta time basically time that has passed since it was
-- called the last time in seconds
--
-- love.keypressed/mousemoved/focus/resize etc...
-- these are called when, well what is stated in their name happened and you
-- can define how to react to these situations in them
--
-- How I do stuff:
--
-- In a game we have different states like the menu state, pause state,
-- game state, deat state, etc...
-- each of these states wants to do something different with the love functions
-- we learned about above.
-- The most simple approach you can think of is probably using a bunch of if
-- statements to change what you're doing in each state, but this quickly gets
-- messy. So what I like to do is to use a statemachine.
-- Basically I'll make an object for all the love calls for each state
-- for example I'll make the game state and it'll have a draw, update etc...
-- functions. Then the statemachine will hold the object of the current state
-- and in the real love functions I'll call statemachine.draw(). I just change
-- what state is in the statemachine and all the love. functions will call the
-- correct functions.
--
-- You can make as many states as you want for example in a top down game
-- if you want to have a visual novel type dialogue in your game you could
-- make a state for that.
--
-- Notes:
-- if you get warnings in this file about some of the love. functions it's
-- probably the fault of the build-stuff/node_modules folder
-- if you the game takes a lot of time to load it's probably the fault of
-- the build-stuff/node_modules folder
-- moving the build-stuff folder out of this project should fix that you
-- only need it to create an html version of the game anyways
--
-- damn you javascript!
--
-- the makelove.sh file is my build file it basically automates the process
-- of making a windows, linux and html version of the game.
-- you can use it as inspiration to make your own or just visit
-- https://love2d.org/wiki/Game_Distribution for more info

local sm = require("state")
local gameState = require("game")
local menuState = require("menu")
local helper = require('helper')
local push = require('push')
local pauseState = require("pause")
local deathState = require("death")
local configuration = require('configuration')

local function create_sound(path, mode, vol)
    if not vol then vol = 1 end
    return { sound = love.audio.newSource(path, mode), vol = vol }
end

function love.load()
    -- use nearest for pixel art and linear for other things
    love.graphics.setDefaultFilter("nearest")
    love.keyboard.setKeyRepeat(true)
    HsFile = "highscore.txt"
    Stats = helper.loadHighScore(HsFile)
    Font = love.graphics.newFont(20)
    love.graphics.setFont(Font)
    Volumes = {
        generalVolume = 1,
        soundfxVolume = 1,
        musicVolume = 1,
    }
    Soundfx = {
        hurt = create_sound('sound-fx/hitHurt.wav.mp3', 'static', 0.6),
        point = create_sound('sound-fx/pickupCoin.wav.mp3', 'static', 0.8),
        shootmissle = create_sound('sound-fx/explosion.wav.mp3', "static", 0.2),
        explosion = create_sound('sound-fx/properexplosion.wav.mp3', "static", 0.2),
        dash = create_sound('sound-fx/dash.wav.mp3', "static"),
        wall = create_sound('sound-fx/hitwall.wav.mp3', "static"),
        select = create_sound('sound-fx/blipSelect.wav.mp3', "static", 0.1),
        click = create_sound('sound-fx/click.wav.mp3', "static"),
    }
    Music = {
        music = create_sound('sound-fx/epic_music_for_game_jam.wav.mp3', "stream"),
        reverbmusic = create_sound('sound-fx/epic_music_for_game_jam_reverb.wav.mp3', "stream"),
    }
    ChangeVolume()

    ScreenAreaWidth = 640
    ScreenAreaHeight = 600
    RealWidth = love.graphics.getWidth()
    RealHeight = love.graphics.getHeight()
    -- push is a library for scaling your game to any resolution
    push:setupScreen(ScreenAreaWidth, ScreenAreaHeight, RealWidth, RealHeight, { resizable = true })
    -- initialize states
    gameState:init(sm, menuState, pauseState, deathState)
    menuState:init(sm, gameState, configuration)
    pauseState:init(sm, gameState, menuState, configuration)
    deathState:init(sm, gameState, menuState)
    configuration:init(sm)
    sm:changestate(menuState, nil)
end

function ChangeVolume()
    for _, sound in pairs(Soundfx) do
        sound.sound:setVolume(Volumes.generalVolume * Volumes.soundfxVolume * sound.vol)
    end

    for _, sound in pairs(Music) do
        sound.sound:setVolume(Volumes.generalVolume * Volumes.musicVolume * sound.vol)
    end
end

function love.update(dt)
    -- verify if current state implements the update method
    if sm.state.update then
        -- call update method
        sm.state:update(dt)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if sm.state.keypressed then
        sm.state:keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode, isrepeat)
    if sm.state.keyreleased then
        sm.state:keyreleased(key, scancode, isrepeat)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    x, y = push:toGame(x, y)
    if sm.state.mousepressed then
        sm.state:mousepressed(x, y, button, istouch, presses)
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    x, y = push:toGame(x, y)
    if sm.state.mousereleased then
        sm.state:mousereleased(x, y, button, istouch, presses)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    x, y = push:toGame(x, y)
    if sm.state.mousemoved then
        sm.state:mousemoved(x, y, dx, dy, istouch)
    end
end

function love.draw()
    push:start()
    if sm.state.draw then
        sm.state:draw()
    end
    push:finish()
end

function love.focus(f)
    if sm.state.focus then
        sm.state:focus(f)
    end
end

function love.resize(w, he)
    RealWidth = w
    RealHeight = he
    push:resize(w, he)
    if sm.state.resize then
        sm.state:resize()
    end
end
