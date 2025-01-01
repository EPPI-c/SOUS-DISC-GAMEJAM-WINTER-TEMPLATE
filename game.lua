local helper = require 'helper'
local game = {}

---@class Person
---@field coord Coord
---@field color table {red, green, blue}
---@field draw function draws person

---@param x number
---@param y number
---@param color table
---@return Person
function game.create_Person(x, y, color)
    local coord = helper.create_coord(x, y)
    local person = {
        coord = coord,
        color = color,
        width = 20,
        height = 20,
    }
    function person:draw()
        love.graphics.setColor(color)
        love.graphics.rectangle('fill', self.coord.x - self.width / 2, self.coord.y - self.height / 2, self.width,
            self.height)
    end

    return person
end

function game:init(sm, menu)
    Map = love.graphics.newImage('map.jpeg')
    MapW, MapH = Map:getDimensions()
    StateMachine = sm
    MenuState = menu
    Player = game.create_Person(0, 0, { 0, 0, 1 })
    Enemy = game.create_Person(100, 100, { 1, .3, .3 })
    Enemy_vision = 200
    Speed = 250
    EnemySpeed = 200
    Dash = { '', 0 }
    Dashdelta = 100
    Enemynormalcolor = { .1, .1, .5, .5 }
    Enemycolor = Enemynormalcolor
    EnergyMax = 5
    Energy = EnergyMax
    Energy_width = ScreenAreaWidth * 0.8
    Attack_range = 70
end

---for drawing stuff
function game:draw()
    love.graphics.push()
    love.graphics.translate(ScreenAreaWidth / 2 - Player.coord.x, ScreenAreaHeight / 2 - Player.coord.y)
    -- Background
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(Map, -MapW / 2, -MapH / 2)
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
    love.graphics.setColor(0.3, 1, 0.3, 0.8)
    love.graphics.rectangle("fill", 20, 20, Energy_width * Energy /
    EnergyMax, 20)
end

function game:player_movement(dt)
    if love.keyboard.isDown('w') then
        Player.coord.y = Player.coord.y - dt * Speed
    end
    if love.keyboard.isDown('s') then
        Player.coord.y = Player.coord.y + dt * Speed
    end
    if love.keyboard.isDown('d') then
        Player.coord.x = Player.coord.x + dt * Speed
    end
    if love.keyboard.isDown('a') then
        Player.coord.x = Player.coord.x - dt * Speed
    end
end

function game:enemy_movement(dt)
    if Enemy.coord:distance(Player.coord) < Enemy_vision then
        local diffx = Enemy.coord.x - Player.coord.x
        local dir = diffx / math.abs(diffx)
        Enemy.coord.x = Enemy.coord.x + EnemySpeed * dt * dir
        local diffy = Enemy.coord.y - Player.coord.y
        dir = diffy / math.abs(diffy)
        Enemy.coord.y = Enemy.coord.y + EnemySpeed * dt * dir
        Enemycolor = { .5, .1, .1, .5 }
    else
        Enemycolor = Enemynormalcolor
    end
end

---@param dt number seconds since the last time the function was called
---for game logic
function game:update(dt)
    self:player_movement(dt)
    self:enemy_movement(dt)
    Energy = Energy - dt
    if Energy < 0 then
        StateMachine:changestate(MenuState, nil)
    end
end

---@param context any feel free to use this however you want
---called when state changed to this state
function game:changedstate(context)
    self:init(StateMachine, MenuState)
end

---@param f boolean the state if focused or not
---for when game is focused or unfocused
function game:focus(f)
end

---@param x number Mouse x .coordition, in pixels.
---@param y number Mouse y .coordition, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
function game:mousepressed(x, y, button, istouch, presses)
end

---@param x number Mouse x .coordition, in pixels.
---@param y number Mouse y .coordition, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
function game:mousereleased(x, y, button, istouch, presses)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---Callback function triggered when a keyboard key is released.
function game:keyreleased(key, scancode)
end

function game:dash(key, isrepeat)
    if key == Dash[1] and love.timer.getTime() - Dash[2] < 0.25 and not isrepeat then
        if key == 'w' then
            Player.coord.y = Player.coord.y - Dashdelta
        elseif key == 's' then
            Player.coord.y = Player.coord.y + Dashdelta
        elseif key == 'a' then
            Player.coord.x = Player.coord.x - Dashdelta
        elseif key == 'd' then
            Player.coord.x = Player.coord.x + Dashdelta
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
function game:mousemoved(x, y, dx, dy, istouch)
end

return game
