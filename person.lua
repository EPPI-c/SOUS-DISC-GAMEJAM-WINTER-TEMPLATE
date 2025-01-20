local helper = require 'helper'

local M = {}

---@class Person
---@field dead boolean
---@field outline boolean
---@field coord Coord
---@field hitbox Hitbox
---@field maxspeed number
---@field speed number
---@field xspeed number
---@field front boolean
---@field yspeed number
---@field accel number
---@field decel number
---@field width number
---@field height number
---@field color table {red, green, blue}
---@field draw function draws person
---@field change_coord function (x,y)
---@field change_x function (x)
---@field change_y function (y)
---@field rollback function (x,y)
---@field accelerate function (dt, x, y)
---@field next_moves function (dt)
---@field dashTime number
---@field dashTimer number
---@field dashPower number
---@field dashCooldown number
---@field dashX function (dir)
---@field dashY function (dir)

---@param x number
---@param y number
---@param color table
---@param maxspeed number
---@param accel number
---@param decel number
---@return Person
function M.create_Person(x, y, color, maxspeed, accel, decel, dashcolor, afterdash)
    if not dashcolor then dashcolor = color end
    if not afterdash then afterdash = color end
    local coord = helper.create_coord(x, y)
    local width = 20
    local height = 20
    local person = {
        dead = false,
        coord = coord,
        color = color,
        dashcolor = dashcolor,
        afterdash = afterdash,
        activecolor = color,
        width = width,
        height = height,
        outline = false,
        front = true,
        speed = 0,
        xspeed = 0,
        yspeed = 0,
        maxspeed = maxspeed,
        accel = accel,
        decel = decel,
        pastx = x,
        pasty = y,
        dashTime = 0.2,
        dashTimer = 0,
        dashCooldownTimer = 0,
        dashPower = 2,
        dashCooldown = 1,
        hitbox = helper.create_hitbox(helper.create_coord(coord.x - width / 2, coord.y - height / 2),
            helper.create_coord(coord.x + width / 2, coord.y + height / 2)),
    }
    function person:draw()
        love.graphics.setColor(self.activecolor)
        if self.dead then
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.rectangle('fill', self.coord.x - self.width / 2, self.coord.y - self.height / 2, self.width,
            self.height)
    end

    ---@diagnostic disable-next-line: redefined-local
    function person:change_coord(x, y)
        self:change_x(x)
        self:change_y(y)
    end

    ---@diagnostic disable-next-line: redefined-local
    function person:change_x(x)
        if self.dead then
            return
        end
        self.pastx = self.coord.x
        self.pasty = self.coord.y
        self.coord.x = x
        self.hitbox.topLeft.x = x - self.width / 2
        self.hitbox.bottomRight.x = x + self.width / 2
    end

    ---@diagnostic disable-next-line: redefined-local
    function person:change_y(y)
        if self.dead then
            return
        end
        self.pastx = self.coord.x
        self.pasty = self.coord.y
        self.coord.y = y
        self.hitbox.topLeft.y = y - self.height / 2
        self.hitbox.bottomRight.y = y + self.height / 2
    end

    ---@diagnostic disable-next-line: redefined-local
    function person.totalspeed(x, y)
        return math.sqrt(x ^ 2 + y ^ 2)
    end

    ---@param dt number
    ---@param x number -1, 0, 1
    ---@param y number -1, 0, 1
    ---@diagnostic disable-next-line: redefined-local
    function person:accelerate(dt, x, y)
        if self.dashTimer > 0 then
            self.dashTimer = self.dashTimer - dt
            return
        end
        if self.dashCooldownTimer > 0 then
            self.activecolor = self.afterdash
            self.dashCooldownTimer = self.dashCooldownTimer - dt
        else
            self.activecolor = self.color
        end
        if y > 0 then
            self.front = true
        elseif y < 0 then
            self.front = false
        end

        local ax = x * self.accel * dt
        local ay = y * self.accel * dt
        self.xspeed = self.xspeed + ax
        self.yspeed = self.yspeed + ay
        local s = self.totalspeed(self.xspeed, self.yspeed)
        if s > self.maxspeed then
            self.xspeed = self.xspeed * self.maxspeed / s
            self.yspeed = self.yspeed * self.maxspeed / s
        end
        if x == 0 then
            self.xspeed = helper.round(self.xspeed - self.xspeed * self.decel, 1)
            if math.abs(self.xspeed) < 1 then
                self.xspeed = 0
            end
        end
        if y == 0 then
            self.yspeed = helper.round(self.yspeed - self.yspeed * self.decel, 1)
            if math.abs(self.yspeed) < 1 then
                self.yspeed = 0
            end
        end
    end

    function person:rollback()
        self:change_coord(self.pastx, self.pasty)
    end

    ---@diagnostic disable-next-line: redefined-local
    function person:dashX(dir)
        if self.dashTimer > 0 or self.dashCooldownTimer > 0 then
            return
        end
        self.activecolor = self.dashcolor
        Soundfx.dash.sound:play()
        GameStats.game.dashed = GameStats.game.dashed + 1
        self.dashTimer = self.dashTime
        self.dashCooldownTimer = self.dashCooldown
        -- speed goes whooooa
        self.xspeed = self.maxspeed * self.dashPower * dir
        self.yspeed = 0
    end

    ---@diagnostic disable-next-line: redefined-local
    function person:dashY(dir)
        if self.dashTimer > 0 or self.dashCooldownTimer > 0 then
            return
        end
        self.activecolor = self.dashcolor
        Soundfx.dash.sound:play()
        GameStats.game.dashed = GameStats.game.dashed + 1
        self.dashTimer = self.dashTime
        self.dashCooldownTimer = self.dashCooldown
        -- speed goes whooooa
        self.yspeed = self.maxspeed * self.dashPower * dir
        self.xspeed = 0
    end

    function person:next_moves(dt)
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

    return person
end

function M.createImagePerson(imagefront, imageback, x, y, color, maxspeed, accel, decel, dashcolor, afterdash, outfront, outback)
    if not outfront then
        outfront = imagefront
    end
    if not outback then
        outback = imageback
    end
    local w, h = imagefront:getDimensions()
    local wo, ho = outfront:getDimensions()
    local person = M.create_Person(x, y, color, maxspeed, accel, decel, dashcolor, afterdash)
    function person:draw()
        love.graphics.setColor(self.activecolor)
        if self.dead then
            love.graphics.setColor(0, 0, 0)
        end
        local image, out
        if self.front then
            image = imagefront
            out = outfront
        else
            image = imageback
            out = outback
        end
        if self.outline and not self.dead then
            love.graphics.draw(out, self.coord.x, self.coord.y, nil, nil,nil, wo/2, (ho-self.height) + self.height/2 - (ho-h)/2)
        end
        love.graphics.draw(image, self.coord.x, self.coord.y, nil, nil, nil, w / 2, (h-self.height)+self.height/2)
    end

    return person
end

return M
