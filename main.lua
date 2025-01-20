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
    return {sound = love.audio.newSource(path, mode), vol = vol}
end

function love.load()
    love.graphics.setDefaultFilter("nearest")
    love.keyboard.setKeyRepeat( true )
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

    ScreenAreaWidth = 800
    ScreenAreaHeight = 600
    RealWidth = love.graphics.getWidth()
    RealHeight = love.graphics.getHeight()
    push:setupScreen(ScreenAreaWidth, ScreenAreaHeight, RealWidth, RealHeight, { resizable = true })
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
    if sm.state.update then
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
