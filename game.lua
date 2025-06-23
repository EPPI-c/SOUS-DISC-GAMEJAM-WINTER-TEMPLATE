local person = require 'person'
local helper = require 'helper'

local game = {}

function game:init(sm, menu, pause, deathstate)
    self.sm = sm -- state manager
    self.background = love.graphics.newImage('images/kasaneteto-game.jpg') -- loading an image you should do this in init functions so it's run only once
    self.menuState = menu
    self.pauseState = pause
    self.deathState = deathstate
    self:reset()
end

function game:reset()
    -- change the menu music with the game music
    if Music.reverbmusic.sound:isPlaying() then
        local musicPos = Music.reverbmusic.sound:tell()
        Music.reverbmusic.sound:stop()
        Music.music.sound:seek(musicPos)
    end
    Music.music.sound:setLooping(true)
    Music.music.sound:play()

    Player = person.create_Person(200, 200, { 0, 1, 0 }, 350, 2000, 0.2)

    GameStats = helper.create_stats()
    Seed = os.time()
end

---for drawing stuff
function game:draw()
    love.graphics.push()

    -- keep player centered
    love.graphics.translate(ScreenAreaWidth / 2 - Player.coord.x, ScreenAreaHeight / 2 - Player.coord.y)

    -- draw background
    love.graphics.draw(self.background, 0, 0)

    Player:draw()

    -- you need to call this every time you call translate
    love.graphics.pop()
    -- you can put stuff that you don't want to be translated like ui here
    love.graphics.setColor({1,0,0})
    love.graphics.print("hi I'm ui",100,100)
end

function game:player_movement(dt)
    ---@diagnostic disable-next-line: redefined-local
    local x = 0
    ---@diagnostic disable-next-line: redefined-local
    local y = 0
    -- change direction of movement
    if love.keyboard.isDown('w') then
        y = -1
    end
    if love.keyboard.isDown('s') then
        y = 1
    end
    if love.keyboard.isDown('d') then
        x = 1
    end
    if love.keyboard.isDown('a') then
        x = -1
    end
    -- change speed
    Player:accelerate(dt, x, y)
    local movements = Player:next_moves(dt)
    for _, move in pairs(movements) do
        Player:change_x(move.x)
    -- check collisions example
    --     if Streets:check_collisions(Player.hitbox) then
    --         hitwall = true
    --         Player:rollback()
    --     end
        Player:change_y(move.y)
    --     if Streets:check_collisions(Player.hitbox) then
    --         hitwall = true
    --         Player:rollback()
    --     end
    --     if hitwall then
    --         Soundfx.wall.sound:play()
    --     end
    end
end

---@param dt number seconds since the last time the function was called
---for game logic
function game:update(dt)
    self:player_movement(dt)
end

---@param context any feel free to use this however you want
---called when state changed to this state
---@diagnostic disable-next-line: unused-local
function game:changedstate(context)
    if not context then
        self:reset()
    else
        local musicPos = Music.reverbmusic.sound:tell()
        Music.reverbmusic.sound:stop()
        Music.music.sound:seek(musicPos)
        Music.music.sound:setLooping(true)
        Music.music.sound:play()
    end
end

---@param f boolean the state if focused or not
---for when game is focused or unfocused
---@diagnostic disable-next-line: unused-local
function game:focus(f)
    if not f then
        self.sm:changestate(self.pauseState, nil)
    end
end


---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
---@diagnostic disable-next-line: unused-local
function game:keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        self.sm:changestate(self.pauseState, nil)
    end
end

return game
