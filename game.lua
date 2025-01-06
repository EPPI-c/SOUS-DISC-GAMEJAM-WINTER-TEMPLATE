local streets = require 'streets'
local person = require 'person'
local helper = require 'helper'

local game = {}

local projectile_yellow = helper.hex_to_rgb(0xFFEA00)

function game.create_projectile(start, target)
    local radius = 4
    local p = {
        coord = start,
        radius = radius,
        target = target,
        maxspeed = 400,
        xspeed = 0,
        yspeed = 0,
        hit = false,
        missregistered = false,
        accel = 1000,
        explosiontimer = 0.3,
        damage = 4,
        timer = 3,
        hitbox = helper.create_hitbox(helper.create_coord(start.x - radius, start.y - radius),
            helper.create_coord(start.x + radius, start.y + radius)),
    }
    function p:draw()
        if self.timer <= 0 then
            if self.explosiontimer > 0 then
                love.graphics.setColor(1, 0, 0)
                love.graphics.circle('fill', self.coord.x, self.coord.y, self.radius * 2)
            end
            return
        end
        love.graphics.setColor(projectile_yellow)
        love.graphics.circle('fill', self.coord.x, self.coord.y, self.radius)
    end

    ---@diagnostic disable-next-line: redefined-local
    function p.totalspeed(x, y)
        return math.sqrt(x ^ 2 + y ^ 2)
    end

    function p:next_moves(dt, xdir, ydir)
        self.timer = self.timer - dt
        if self.timer < 0 then
            if not self.hit and not self.missregistered then
                GameStats.game.dodged = GameStats.game.dodged + 1
                self.missregistered = true
            end
            self.explosiontimer = self.explosiontimer - dt
            return {}
        end

        local ax = xdir * self.accel * dt
        local ay = ydir * self.accel * dt
        self.xspeed = self.xspeed + ax
        self.yspeed = self.yspeed + ay
        local s = self.totalspeed(self.xspeed, self.yspeed)
        if s > self.maxspeed then
            self.xspeed = self.xspeed * self.maxspeed / s
            self.yspeed = self.yspeed * self.maxspeed / s
        end

        local deltax = self.xspeed * dt
        local deltay = self.yspeed * dt
        local steps = math.ceil(math.max(math.abs(deltax), math.abs(deltay)))
        local moves = {}
        for step = 1, steps do
            ---@diagnostic disable-next-line: redefined-local
            local x = self.coord.x + deltax / steps * step
            ---@diagnostic disable-next-line: redefined-local
            local y = self.coord.y + deltay / steps * step
            table.insert(moves, helper.create_coord(x, y))
        end
        return moves
    end

    ---@diagnostic disable-next-line: redefined-local
    function p:change_coord(x, y)
        self:change_x(x)
        self:change_y(y)
    end

    ---@diagnostic disable-next-line: redefined-local
    function p:change_x(x)
        self.pastx = self.coord.x
        self.pasty = self.coord.y
        self.coord.x = x
        self.hitbox.topLeft.x = x - self.radius
        self.hitbox.bottomRight.x = x + self.radius
    end

    ---@diagnostic disable-next-line: redefined-local
    function p:change_y(y)
        self.pastx = self.coord.x
        self.pasty = self.coord.y
        self.coord.y = y
        self.hitbox.topLeft.y = y - self.radius
        self.hitbox.bottomRight.y = y + self.radius
    end

    return p
end

function game:init(sm, menu)
    StateMachine = sm
    MenuState = menu

    GameStats = helper.create_stats()
    Seed = os.time()
    Streets = streets.create_manager(400, 400, Seed)
    Map = love.graphics.newImage('map.jpeg')
    MapW, MapH = Map:getDimensions()
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
    EnemyStuckCounter = 0
    EnemyAttack_range = 300
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
    -- -- Background
    -- love.graphics.setColor(1, 1, 1)
    -- love.graphics.draw(Map, -MapW / 2, -MapH / 2)

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
    love.graphics.print(tostring(love.timer.getFPS()), 5, 5)
    love.graphics.print(tostring(GameStats.game.score), ScreenAreaWidth - 20, 5)
    love.graphics.print(tostring(GameStats.game.dodged), ScreenAreaWidth - 20, ScreenAreaHeight - 200)
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
        local projectile = game.create_projectile(helper.create_coord(Enemy.coord.x, Enemy.coord.y), Player)
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
            for _, victim in pairs(Streets.victims) do
                if victim.hitbox:check_collision(attack.hitbox) and not victim.dead then
                    attack.timer = 0
                    victim.dead = true
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
    elseif Enemy.coord:distance(Player.coord) > Victim_vision then
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
    for _, victim in pairs(Streets.victims) do
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
    for _, victim in pairs(Streets.victims) do
        if victim.coord:distance(Player.coord) < Attack_range then
            if not victim.dead then
                Energy = EnergyMax
                victim.dead = true
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
