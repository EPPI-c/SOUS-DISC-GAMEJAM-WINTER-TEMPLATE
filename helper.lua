local M = {}

---Coordinate class
---@class Coord
---@field x number x position
---@field y number y position
---@field distance function
function M.create_coord(x, y)
    local coord = { x = x, y = y }
    ---@param point Coord coordinate to calculate distance to
    ---calculates distance to point
    function coord:distance(point)
        return math.sqrt(math.pow(self.x - point.x, 2) + math.pow(self.y - point.y, 2))
    end

    return coord
end

function M.generate_linear_function(x1, y1, x2, y2)
    local a = (y2 - y1) / (x2 - x1)
    local b = y1 - a * x1
    return function(x) return a * x + b end
end

function M.hex_to_rgb(rgb)
    -- clamp between 0x000000 and 0xffffff
    rgb = rgb % 0x1000000 -- 0xffffff + 1

    -- extract each color
    local b = rgb % 0x100         -- 0xff + 1 or 256
    local g = (rgb - b) % 0x10000 -- 0xffff + 1
    local r = (rgb - g - b)
    -- shift right
    g = g / 0x100   -- 0xff + 1 or 256
    r = r / 0x10000 -- 0xffff + 1

    return { r / 255, g / 255, b / 255 }
end

function M.round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

---@class Hitbox
---@field topLeft Coord
---@field bottomRight Coord
---@field check_collision function

---@param coord1 Coord
---@param coord2 Coord
---@return Hitbox
function M.create_hitbox(coord1, coord2)
    local hitbox = {
        topLeft = coord1,
        bottomRight = coord2,
    }
    ---@param other_hitbox Hitbox
    function hitbox:check_collision(other_hitbox)
        if other_hitbox.bottomRight.x < self.topLeft.x or other_hitbox.bottomRight.y < self.topLeft.y or other_hitbox.topLeft.x > self.bottomRight.x or other_hitbox.topLeft.y > self.bottomRight.y then
            return false
        else
            return true
        end
    end

    return hitbox
end

function M.split(s, delimiter)
    delimiter = delimiter or '%s'
    local t = {}
    local i = 1
    for str in string.gmatch(s, '([^' .. delimiter .. ']+)') do
        t[i] = str
        i = i + 1
    end
    return t
end

function M.create_stats()
    local types = { 'score', 'friendlyfire', 'dodged', 'dashed', 'shot', 'secondsalive', 'deaths', 'deathmessageindex' }
    local stats = {
        game = {},
        high = {},
        sum = {},
    }
    for _, v in pairs(types) do
        stats.game[v] = 0
        stats.high[v] = 0
        stats.sum[v] = 0
    end
    function stats:update(otherstats)
        for k, v in pairs(otherstats.game) do
            self.sum[k] = self.sum[k] + v
            if self.high[k] < v then
                self.high[k] = v
            end
        end
    end

    function stats:init_from_string(string)
        for _, line in pairs(M.split(string, '\n')) do
            local k, v = unpack(M.split(line, '='))
            local firstkey, secondkey = unpack(M.split(k, '>'))
            v = tonumber(v)
            if self[firstkey] then
                if secondkey then
                    self[firstkey][secondkey] = v
                end
            end
        end
    end

    function stats:tostring()
        string = ''
        for k, v in pairs(self.high) do
            string = string .. 'high>' .. k .. '=' .. tostring(v) .. '\n'
        end
        for k, v in pairs(self.sum) do
            string = string .. 'sum>' .. k .. '=' .. tostring(v) .. '\n'
        end
        return string
    end

    return stats
end

function M.loadHighScore(hsFile)
    local stats = M.create_stats()
    if love.filesystem.getInfo(hsFile, "file") then
        local data, _ = love.filesystem.read(hsFile)
        stats:init_from_string(data)
        return stats
    end
    return stats
end

function M.writeHighScore(hsFile, stats)
    love.filesystem.write(hsFile, stats:tostring())
end

local projectile_yellow = M.hex_to_rgb(0xFFEA00)
local superpurple = M.hex_to_rgb(0xff20ff)

function M.create_projectile(start, target)
    local radius = 4
    local p = {
        coord = start,
        radius = radius,
        target = target,
        maxspeed = 450,
        xspeed = 0,
        yspeed = 0,
        hit = false,
        missregistered = false,
        accel = 1000,
        explosiontimer = 0.3,
        damage = 4,
        timer = 3,
        hitbox = M.create_hitbox(M.create_coord(start.x - radius, start.y - radius),
            M.create_coord(start.x + radius, start.y + radius)),
    }
    function p:draw(energy)
        if self.timer <= 0 then
            if self.explosiontimer > 0 then
                love.graphics.setColor(1, 0, 0)
                love.graphics.circle('fill', self.coord.x, self.coord.y, self.radius * 2)
            end
            return
        end
        if energy > self.damage * 3 then
            love.graphics.setColor(superpurple)
        else
            love.graphics.setColor(projectile_yellow)
        end
        love.graphics.circle('fill', self.coord.x, self.coord.y, self.radius)
    end

    ---@diagnostic disable-next-line: redefined-local
    function p.totalspeed(x, y)
        return math.sqrt(x ^ 2 + y ^ 2)
    end

    function p:next_moves(dt, xdir, ydir)
        self.timer = self.timer - dt
        if self.timer < 0 then
            if not self.missregistered then
                Soundfx.explosion.sound:play()
                self.missregistered = true
                if not self.hit then
                    GameStats.game.dodged = GameStats.game.dodged + 1
                end
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
            table.insert(moves, M.create_coord(x, y))
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

-- see if the file exists
function M.file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function M.lines_from(file)
    if not M.file_exists(file) then return {} end
    local lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    return lines
end

function M.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

---creates a list of centered spaced coords in a rectangle
---@return table
---@param upperLeft Coord
---@param bottomRight Coord
---@param items number number of coords
---@param horizontal boolean
function M.center_coords(upperLeft, bottomRight, items, horizontal)
    local dir = 'y'
    if horizontal then
        horizontal = false
        dir = 'x'
    end
    local space = bottomRight[dir] - upperLeft[dir]
    local spacer = space / items / 2
    local occupation = spacer + spacer * items / 2
    local position = space / 2 - occupation
    local positions = {}
    local x = bottomRight.x/2
    local y = bottomRight.y/2
    for i=1,items do
        local c = M.create_coord(x, y)
        c[dir] = position + spacer * i
        table.insert(positions, c)
    end

    return positions
end

return M
