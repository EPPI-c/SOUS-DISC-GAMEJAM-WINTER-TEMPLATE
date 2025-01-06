local streets = require 'streets'
local person = require 'person'
local helper = require 'helper'

local game = {}


function game:init(sm, menu)
    StateMachine = sm
    MenuState = menu

    GameStats = helper.create_stats()
    Seed = os.time()
    Streets = streets.create_manager(400, 400, Seed)
    Victim_vision = 200

    Player = person.create_Person(200, 200, { 0, 0, 1 }, 350, 2000, 0.2)
    Dash = { '', 0 }
    Dashdelta = 100
    EnergyMax = 10
    Energy = EnergyMax
    Energy_width = ScreenAreaWidth * 0.8
    Attack_range = 70
    Barcolor = { 0.3, 1, 0.3, 0.8 }

    MaxEnemySpeed = 350
    EnemyisChasing = false
    EnemyStuckCounter = 0
    EnemyAttack_rangemin = 200
    EnemyAttack_rangemax = 250
    EnemyAttack_cooldown = 1
    EnemyAttack_timer = 3
    EnemyAttackisLive = false
    EnemyAttacks = {}
    Enemy = person.create_Person(350, 200, { 0, 1, 1 }, MaxEnemySpeed, 2000, 0.2)
end

---for drawing stuff
function game:draw()
    love.graphics.push()
    love.graphics.translate(ScreenAreaWidth / 2 - Player.coord.x, ScreenAreaHeight / 2 - Player.coord.y)

    Streets:draw()

    -- Attack range
    love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
    love.graphics.circle("fill", Player.coord.x, Player.coord.y, Attack_range)

    Enemy:draw()
    Player:draw()
    for _, attack in pairs(EnemyAttacks) do
        attack:draw()
    end

    love.graphics.pop()
    -- Energy Bar
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", 20, 20, Energy_width, 20)
    love.graphics.setColor(Barcolor)
    love.graphics.rectangle("fill", 20, 20, Energy_width * Energy /
        EnergyMax, 20)
    love.graphics.setColor(1, 0.3, 0.3, 0.7)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 5, 5)
    love.graphics.print('Score: ' .. tostring(GameStats.game.score), ScreenAreaWidth - 110, 5)
    if GameStats.game.friendlyfire > 0 then
        love.graphics.print('FRIENDLY FIRE: ' .. tostring(GameStats.game.friendlyfire), ScreenAreaWidth - 200, 50)
    end
    -- love.graphics.print(tostring(helper.round(Player.coord.x, 0))..'\t'..tostring(helper.round(Player.coord.y, 0)), 5, ScreenAreaHeight - 200)
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
        if Streets:check_collisions(Player.hitbox) then
            Player:rollback()
        end
        Player:change_y(move.y)
        if Streets:check_collisions(Player.hitbox) then
            Player:rollback()
        end
    end
end

function game:getDirections(from, to)
    local diffx = from.x - to.x
    local xdir = 0
    if diffx > 0 then
        xdir = -1
    elseif diffx < 0 then
        xdir = 1
    end
    local diffy = from.y - to.y
    local ydir = 0
    if diffy > 0 then
        ydir = -1
    elseif diffy < 0 then
        ydir = 1
    end
    return xdir, ydir
end

function game:enemyshoot(dt)
    EnemyAttack_timer = EnemyAttack_timer - dt
    if Enemy.coord:distance(Player.coord) > Attack_range and EnemyAttack_timer <= 0 then
        local projectile = helper.create_projectile(helper.create_coord(Enemy.coord.x, Enemy.coord.y), Player)
        table.insert(EnemyAttacks, projectile)
        EnemyAttack_timer = EnemyAttack_cooldown
    end
end

function game:attack_movements(dt)
    for _, attack in pairs(EnemyAttacks) do
        local xdir, ydir = self:getDirections(attack.coord, attack.target.coord)
        for _, move in pairs(attack:next_moves(dt, xdir, ydir)) do
            attack:change_coord(move.x, move.y)
            if Streets:check_collisions(attack.hitbox) then
                attack.timer = 0
            end
            for k, victim in pairs(Streets.victims.collision) do
                if victim.hitbox:check_collision(attack.hitbox) then
                    attack.timer = 0
                    victim.dead = true
                    table.remove(Streets.victims.collision, k)
                    GameStats.game.friendlyfire = GameStats.game.friendlyfire + 1
                end
            end
            if Player.hitbox:check_collision(attack.hitbox) then
                GameStats.game.shot = GameStats.game.shot + 1
                attack.timer = 0
                attack.hit = true
                Energy = Energy - attack.damage
            end
        end
    end
end

function game:enemy_movement(dt)
    local xdir, ydir = self:getDirections(Enemy.coord, Player.coord)
    local Enemydist = Enemy.coord:distance(Player.coord)
    Enemy:accelerate(dt, xdir, ydir)
    local screen_hitbox = helper.create_hitbox(
        helper.create_coord(Player.coord.x - ScreenAreaWidth / 2, Player.coord.y - ScreenAreaHeight / 2),
        helper.create_coord(Player.coord.x + ScreenAreaWidth / 2, Player.coord.y + ScreenAreaHeight / 2))
    if not Enemy.hitbox:check_collision(screen_hitbox) then
        EnemyStuckCounter = EnemyStuckCounter + 1
        local moves = Enemy:next_moves(dt)
        if EnemyStuckCounter > 100 then
            Enemy.maxspeed = 800
            for _, move in pairs(moves) do
                Enemy:change_coord(move.x, move.y)
            end
        end
    elseif Enemydist > EnemyAttack_rangemin then
        if EnemyisChasing or Enemydist > EnemyAttack_rangemax then
            EnemyisChasing = true
            EnemyStuckCounter = 0
            Enemy.maxspeed = MaxEnemySpeed
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
        end
        if Enemydist - 10 <= EnemyAttack_rangemin then
            EnemyisChasing = false
        end
    end
end

function game:victim_movement(dt, victim)
    if victim.coord:distance(Player.coord) < Victim_vision then
        local diffx = victim.coord.x - Player.coord.x
        local xdir = 0
        if diffx > 0 then
            xdir = 1
        elseif diffx < 0 then
            xdir = -1
        end
        local diffy = victim.coord.y - Player.coord.y
        local ydir = 0
        if diffy > 0 then
            ydir = 1
        elseif diffy < 0 then
            ydir = -1
        end
        victim:accelerate(dt, xdir, ydir)
        local moves = victim:next_moves(dt)
        for _, move in pairs(moves) do
            victim:change_x(move.x)
            if Streets:check_collisions(victim.hitbox) then
                victim:rollback()
            end
            victim:change_y(move.y)
            if Streets:check_collisions(victim.hitbox) then
                victim:rollback()
            end
        end
    end
end

---@param dt number seconds since the last time the function was called
---for game logic
function game:update(dt)
    Streets:update(Player.coord.x, Player.coord.y)
    self:player_movement(dt)
    for _, victim in pairs(Streets.victims.collision) do
        self:victim_movement(dt, victim)
    end
    self:enemy_movement(dt)
    self:enemyshoot(dt)
    self:attack_movements(dt)
    Energy = Energy - dt
    if Energy < 0 then
        GameStats.game.deaths = GameStats.game.deaths + 1
        Stats:update(GameStats)
        helper.writeHighScore(HsFile, Stats)

        StateMachine:changestate(MenuState, Seed)
    else
        GameStats.game.secondsalive = GameStats.game.secondsalive + 1
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
    for k, victim in pairs(Streets.victims.collision) do
        if victim.coord:distance(Player.coord) < Attack_range then
            if not victim.dead then
                Energy = EnergyMax
                victim.dead = true
                table.remove(Streets.victims.collision, k)
                GameStats.game.score = GameStats.game.score + 1
            end
        end
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
