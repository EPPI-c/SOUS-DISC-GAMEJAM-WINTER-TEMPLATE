local streets = require 'streets'
local person = require 'person'
local helper = require 'helper'

local game = {}

function game:init(sm, menu, pause, deathstate)
    self.sm = sm
    self.menuState = menu
    self.pauseState = pause
    self.deathState = deathstate
    self.randomguyfront = love.graphics.newImage('images/randomguyfront.png')
    self.randomguyback = love.graphics.newImage('images/randomguyback.png')
    self.randomgirlfrontoutline = love.graphics.newImage('images/outlinegirlfront.png')
    self.randomgirlbackoutline = love.graphics.newImage('images/outlinegirlback.png')
    self.randomguyoutline = love.graphics.newImage('images/outlineguy.png')
    self.randomguyback = love.graphics.newImage('images/randomguyback.png')
    self.randomgirlfront = love.graphics.newImage('images/randomgirlfront.png')
    self.randomgirlback = love.graphics.newImage('images/randomgirlback.png')
    self.sailormoonfront = love.graphics.newImage('images/sailormoonfront.png')
    self.sailormoonback = love.graphics.newImage('images/sailormoonback.png')
    self.monsterfront = love.graphics.newImage('images/monsterfront.png')
    self.monsterback = love.graphics.newImage('images/monsterback.png')
    self.music_speed = helper.generate_linear_function(3, 1, 0, 0.5)
    self:reset()
end

function game:reset()
    if Music.reverbmusic.sound:isPlaying() then
        local musicPos = Music.reverbmusic.sound:tell()
        Music.reverbmusic.sound:stop()
        Music.music.sound:seek(musicPos)
    end
    Music.music.sound:setLooping(true)
    Music.music.sound:play()

    Player = person.createImagePerson(self.monsterfront, self.monsterback, 200, 200, { 0, 1, 0 }, 350, 2000, 0.2,
        { 1, 1, 1 }, { 0.5, 0.5, 1 })
    Dash = { '', 0 }
    Dashdelta = 100
    EnergyMax = 10
    Energy = EnergyMax
    Energy_width = ScreenAreaWidth * 0.25
    Attack_range = 70
    Barcolor = { 0.3, 1, 0.3, 0.8 }

    GameStats = helper.create_stats()
    Seed = os.time()
    Streets = streets.create_manager(400, 400, Seed, self.randomgirlfront, self.randomgirlback,
        self.randomgirlfrontoutline, self.randomgirlbackoutline, self.randomguyfront, self.randomguyback,
        self.randomguyoutline)
    Victim_vision = 200
    Victimenergy = 3

    EnemyOffScreen = false
    MaxEnemySpeed = 400
    EnemyisChasing = false
    EnemyStuckCounter = 0
    Enemymincooldown = 0.7
    EnemyAttack_rangemin = 200
    EnemyAttack_rangemax = 250
    EnemyAttack_timer = 3
    EnemyAttackisLive = false
    EnemyAttacks = {}
    Enemy = person.createImagePerson(self.sailormoonfront, self.sailormoonback, 350, 200, { 1, 1, 1 }, MaxEnemySpeed,
        2000, 0.2)
end

function game:getcooldown()
    if GameStats.game.score > 10 then
        return Enemymincooldown
    end
    local cooldown = GameStats.game.score * -0.23 + 3
    return cooldown
end

---for drawing stuff
function game:draw()
    love.graphics.push()
    love.graphics.translate(ScreenAreaWidth / 2 - Player.coord.x, ScreenAreaHeight / 2 - Player.coord.y)
    if Player.dashTimer > 0 then
        local dx = love.math.random(-1, 1)
        local dy = love.math.random(-1, 1)
        love.graphics.translate(dx, dy)
    end

    Streets:draw()

    Enemy:draw()
    Player:draw()
    for _, attack in pairs(EnemyAttacks) do
        attack:draw(Energy)
    end

    love.graphics.pop()
    -- Energy Bar
    local barx = ScreenAreaWidth / 2 - Energy_width / 2
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", barx - 4, 16, Energy_width + 8, 28)
    local e = math.min(Energy / EnergyMax, 1)
    love.graphics.setColor({ 1 - e, e, 0, 0.8 })
    love.graphics.rectangle("fill", barx, 20, Energy_width * Energy /
        EnergyMax, 20)
    love.graphics.setFont(Font)
    love.graphics.setColor(1, 0.3, 0.3, 0.7)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 5, 5)
    love.graphics.print('Score: ' .. tostring(GameStats.game.score), ScreenAreaWidth - 110, 5)
    if GameStats.game.friendlyfire > 0 then
        love.graphics.print('FRIENDLY FIRE: ' .. tostring(GameStats.game.friendlyfire), ScreenAreaWidth - 200, 50)
    end
    love.graphics.setShader()
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
    local hitwall = false
    for _, move in pairs(movements) do
        Player:change_x(move.x)
        if Streets:check_collisions(Player.hitbox) then
            hitwall = true
            Player:rollback()
        end
        Player:change_y(move.y)
        if Streets:check_collisions(Player.hitbox) then
            hitwall = true
            Player:rollback()
        end
        if hitwall then
            Soundfx.wall.sound:play()
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
    if Enemy.coord:distance(Player.coord) < EnemyAttack_rangemax and EnemyAttack_timer <= 0 then
        Soundfx.shootmissle.sound:play()
        local projectile = helper.create_projectile(helper.create_coord(Enemy.coord.x, Enemy.coord.y), Player)
        table.insert(EnemyAttacks, projectile)
        EnemyAttack_timer = game:getcooldown()
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
            if Player.hitbox:check_collision(attack.hitbox) and attack.timer > 0 then
                Soundfx.hurt.sound:play()
                GameStats.game.shot = GameStats.game.shot + 1
                attack.timer = 0
                attack.hit = true
                if Energy > attack.damage * 3 then
                    Energy = Energy / 2
                else
                    Energy = Energy - attack.damage
                end
            end
        end
    end
end

function game:enemy_movement(dt)
    local xdir, ydir = self:getDirections(Enemy.coord, Player.coord)
    local fxdir, fydir = 0, 0
    local Enemydist = Enemy.coord:distance(Player.coord)
    local screen_hitbox = helper.create_hitbox(
        helper.create_coord(Player.coord.x - ScreenAreaWidth / 2, Player.coord.y - ScreenAreaHeight / 2),
        helper.create_coord(Player.coord.x + ScreenAreaWidth / 2, Player.coord.y + ScreenAreaHeight / 2))
    EnemyOffScreen = not Enemy.hitbox:check_collision(screen_hitbox)
    if EnemyOffScreen then
        Enemy:accelerate(dt, xdir, ydir)
        EnemyStuckCounter = EnemyStuckCounter + 1
        local moves = Enemy:next_moves(dt)
        if EnemyStuckCounter > 40 then
            Enemy.maxspeed = 1000
            for _, move in pairs(moves) do
                Enemy:change_coord(move.x, move.y)
            end
        end
    elseif Enemydist > EnemyAttack_rangemin then
        if EnemyisChasing or Enemydist > EnemyAttack_rangemax then
            EnemyisChasing = true
            EnemyStuckCounter = 0
            Enemy.maxspeed = MaxEnemySpeed
            fxdir = xdir
            fydir = ydir
        end
        if Enemydist + 10 <= EnemyAttack_rangemin then
            EnemyisChasing = false
        end
    end
    Enemy:accelerate(dt, fxdir, fydir)
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

    for _, victim in pairs(Streets.victims.collision) do
        if victim.coord:distance(Player.coord) < Attack_range then
            victim.outline = true
        else
            victim.outline = false
        end
    end


    local musicspeed
    if Energy < 3 then
        musicspeed = self.music_speed(Energy)
    else
        musicspeed = 1
    end
    if musicspeed < 0 then musicspeed = 0.1 end
    Music.music.sound:setPitch(musicspeed)
    Energy = Energy - dt
    if Energy <= 0 then
        GameStats.game.deaths = GameStats.game.deaths + 1
        Stats:update(GameStats)
        helper.writeHighScore(HsFile, Stats)
        self.sm:changestate(self.deathState, Seed)
    else
        GameStats.game.secondsalive = GameStats.game.secondsalive + 1
    end
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
                Soundfx.point.sound:play()
                if Energy < EnergyMax - Victimenergy then
                    Energy = EnergyMax
                else
                    Energy = Energy + Victimenergy
                end
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
    if key == 'escape' then
        self.sm:changestate(self.pauseState, nil)
    end
    self:dash(key, isrepeat)
    if key == 'k' and not isrepeat then
        self:attack()
    end
end

return game
