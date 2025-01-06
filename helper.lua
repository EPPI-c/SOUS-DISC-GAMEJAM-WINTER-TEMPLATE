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
    local types = {'score', 'friendlyfire', 'dodged', 'dashed', 'shot', 'secondsalive', 'deaths'}
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
            print(firstkey)
            print(secondkey)
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

return M
