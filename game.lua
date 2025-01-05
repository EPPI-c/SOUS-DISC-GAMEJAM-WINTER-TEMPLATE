local streets = require 'streets'
local person = require 'person'
local helper = require 'helper'

local game = {}

function game:init(sm, menu)
    Streets = streets.create_manager(400, 400, 0)
    Map = love.graphics.newImage('map.jpeg')
    MapW, MapH = Map:getDimensions()
    StateMachine = sm
    MenuState = menu
    Player = person.create_Person(200, 200, { 0, 0, 1 }, 350, 2000, 0.2)
    Enemy = person.create_Person(100, 100, { 1, .3, .3 }, 200, 2000, 0.2)
    Enemy_vision = 200
    Dash = { '', 0 }
    Dashdelta = 100
    Enemynormalcolor = { .1, .1, .5, .5 }
    Enemycolor = Enemynormalcolor
    EnergyMax = 5
    Energy = EnergyMax
    Energy_width = ScreenAreaWidth * 0.8
    Attack_range = 70
    Barcolor = { 0.3, 1, 0.3, 0.8 }
end

---for drawing stuff
function game:draw()
    love.graphics.push()
    love.graphics.translate(ScreenAreaWidth / 2 - Player.coord.x, ScreenAreaHeight / 2 - Player.coord.y)
    -- -- Background
    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.draw(Map, -MapW / 2, -MapH / 2)

    Streets:draw()

    -- Enemy vision
    love.graphics.setColor(Enemycolor)
    love.graphics.circle("fill", Enemy.coord.x, Enemy.coord.y, Enemy_vision)

    -- Attack range
    love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
    love.graphics.circle("fill", Player.coord.x, Player.coord.y, Attack_range)

    Enemy:draw()
    Player:draw()

    love.graphics.pop()
    -- Energy Bar
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", 20, 20, Energy_width, 20)
    love.graphics.setColor(Barcolor)
    love.graphics.rectangle("fill", 20, 20, Energy_width * Energy /
        EnergyMax, 20)
    love.graphics.setColor(1, 0.3, 0.3, 0.7)
    love.graphics.print(tostring(love.timer.getFPS()), 5, 5)
    love.graphics.print(tostring(helper.round(Player.coord.x, 0))..'\t'..tostring(helper.round(Player.coord.y, 0)), 5, ScreenAreaHeight - 200)
end

function game:player_movement(dt)
    ---@diagnostic disable-next-line: redefined-local
    local x = 0
    ---@diagnostic disable-next-line: redefined-local
    local y = 0
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
    Player:accelerate(dt, x, y)
    local movements = Player:next_moves(dt)
    for _, move in pairs(movements) do
        Player:change_x(move.x)
        Streets:update(Player.coord.x, Player.coord.y)
        if Streets:check_collisions(Player.hitbox) then
            Player:rollback()
        end
        Player:change_y(move.y)
        Streets:update(Player.coord.x, Player.coord.y)
        if Streets:check_collisions(Player.hitbox) then
            Player:rollback()
        end
    end
end

function game:enemy_movement(dt)
    if Enemy.coord:distance(Player.coord) < Enemy_vision then
        Enemycolor = { .5, .1, .1, .5 }
        local diffx = Enemy.coord.x - Player.coord.x
        local xdir = diffx / math.abs(diffx)
        local diffy = Enemy.coord.y - Player.coord.y
        local ydir = diffy / math.abs(diffy)
        Enemy:accelerate(dt, xdir, ydir)
        local moves = Enemy:next_moves(dt)
        for _, move in pairs(moves) do
            Enemy:change_x(move.x)
            if Streets:check_collisions(Enemy.hitbox) then
                Enemy:rollback()
            end
            Enemy:change_y(move.y)
            if Streets:check_collisions(Enemy.hitbox) then
                Enemy:rollback()
            end
        end
    else
        Enemycolor = Enemynormalcolor
    end
end

---@param dt number seconds since the last time the function was called
---for game logic
function game:update(dt)
    self:player_movement(dt)
    self:enemy_movement(dt)
    Streets:update(Player.coord.x, Player.coord.y)
    -- Energy = Energy - dt
    if Energy < 0 then
        StateMachine:changestate(MenuState, nil)
    end
end

---@param context any feel free to use this however you want
---called when state changed to this state
---@diagnostic disable-next-line: unused-local
function game:changedstate(context)
    self:init(StateMachine, MenuState)
end

---@param f boolean the state if focused or not
---for when game is focused or unfocused
---@diagnostic disable-next-line: unused-local
function game:focus(f)
end

---@param x number Mouse x .coordition, in pixels.
---@param y number Mouse y .coordition, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
---@diagnostic disable-next-line: unused-local
function game:mousepressed(x, y, button, istouch, presses)
end

---@param x number Mouse x .coordition, in pixels.
---@param y number Mouse y .coordition, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
---@diagnostic disable-next-line: unused-local
function game:mousereleased(x, y, button, istouch, presses)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---Callback function triggered when a keyboard key is released.
---@diagnostic disable-next-line: unused-local
function game:keyreleased(key, scancode)
end

function game:dash(key, isrepeat)
    if key == Dash[1] and love.timer.getTime() - Dash[2] < 0.25 and not isrepeat then
        if key == 'w' then
            Player:dashY(-1)
        elseif key == 's' then
            Player:dashY(1)
        elseif key == 'a' then
            Player:dashX(-1)
        elseif key == 'd' then
            Player:dashX(1)
        end
    end
    Dash = { key, love.timer.getTime() }
end

function game:attack()
    if Enemy.coord:distance(Player.coord) < Attack_range then
        Energy = EnergyMax
    end
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
---@diagnostic disable-next-line: unused-local
function game:keypressed(key, scancode, isrepeat)
    self:dash(key, isrepeat)
    if key == 'k' and not isrepeat then
        self:attack()
    end
end

---@param x number The mouse .coordition on the x-axis.
---@param y number The mouse .coordition on the y-axis.
---@param dx number  The amount moved along the x-axis since the last time love.mousemoved was called.
---@param dy number  The amount moved along the y-axis since the last time love.mousemoved was called.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@diagnostic disable-next-line: unused-local
function game:mousemoved(x, y, dx, dy, istouch)
end

return game
