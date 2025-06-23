local helper = require 'helper'

local M = {}

-- class definition this helps your editor to provide suggestions and check for errors

--- person class
---@class Person
---@field dead boolean is the person dead?
---@field coord Coord coordinate of the person
---@field pastx number x position before using change_x
---@field pasty number y position before using change_y
---@field hitbox Hitbox hitbox of the person
---@field maxspeed number maximum speed of the person
---@field xspeed number current speed in the x direction of the person
---@field yspeed number current speed in the y direction of the person
---@field front boolean is the person facing the screen or not
---@field accel number acceleration of the person above 0
---@field decel number deceleration of the person should be between 0 and 1
---@field width number width of the person this is used for the hitbox
---@field height number height of the person this is used for the hitbox
---@field color table {red, green, blue} default color of the person
---@field draw function function that draws the person
---@field change_x function (x) changes the person x coordinate
---@field change_y function (y) changes the person y coordinate
---@field rollback function rollback to last position before using change if the person collided
---@field accelerate function (dt, x, y) changes the speed of the person dt is the time delta since last frame and x and y should be -1, 0 or 1 and define in which direction the person is moving
---@field next_moves function (dt) gives the next moves based on acceleration

---@param x number x position of the person
---@param y number y position of the person
---@param color table color of the person
---@param maxspeed number maximum speed of the person
---@param accel number acceleration of the person above 0
---@param decel number deceleration of the person should be between 0 and 1
---@return Person
function M.create_Person(x, y, color, maxspeed, accel, decel)
    local coord = helper.create_coord(x, y)
    local width = 20
    local height = 20
    ---@class Person
    local person = {
        dead = false,
        coord = coord,
        color = color,
        width = width,
        height = height,
        front = true,
        xspeed = 0,
        yspeed = 0,
        maxspeed = maxspeed,
        accel = accel,
        decel = decel,
        pastx = x,
        pasty = y,
        hitbox = helper.create_hitbox(helper.create_coord(coord.x - width / 2, coord.y - height / 2),
            helper.create_coord(coord.x + width / 2, coord.y + height / 2)),
    }

    function person:draw()
        love.graphics.setColor(self.color)
        if self.dead then
            love.graphics.setColor(0, 0, 0)
        end
        love.graphics.rectangle('fill', self.coord.x - self.width / 2, self.coord.y - self.height / 2, self.width,
            self.height)
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

    -- the complete speed vector in both directinos
    ---@diagnostic disable-next-line: redefined-local
    function person.totalspeed(x, y)
        -- probably not the best way because it uses square root but who cares at this scale
        return math.sqrt(x ^ 2 + y ^ 2)
    end

    ---@param dt number delta time
    ---@param x number -1, 0, 1 direction x
    ---@param y number -1, 0, 1 direction y
    ---@diagnostic disable-next-line: redefined-local
    function person:accelerate(dt, x, y)
        if y > 0 then
            self.front = true
        elseif y < 0 then
            self.front = false
        end

        -- calculate the change of speed in the correct direction already
        local ax = x * self.accel * dt
        local ay = y * self.accel * dt

        -- change speed
        self.xspeed = self.xspeed + ax
        self.yspeed = self.yspeed + ay

        -- verify if your above max speed
        local s = self.totalspeed(self.xspeed, self.yspeed)
        if s > self.maxspeed then
            -- if you're above max speed cap speed to max
            self.xspeed = self.xspeed * self.maxspeed / s
            self.yspeed = self.yspeed * self.maxspeed / s
        end
        -- decelerate if you're not moving in x direction
        if x == 0 then
            self.xspeed = helper.round(self.xspeed - self.xspeed * self.decel, 1)
            -- stop at once, if you don't have the speed will keep getting smaller and smaller without becoming 0
            if math.abs(self.xspeed) < 1 then
                self.xspeed = 0
            end
        end
        -- decelerate if you're not moving in y direction
        if y == 0 then
            self.yspeed = helper.round(self.yspeed - self.yspeed * self.decel, 1)
            -- stop at once, if you don't have the speed will keep getting smaller and smaller without becoming 0
            if math.abs(self.yspeed) < 1 then
                self.yspeed = 0
            end
        end
    end

    function person:rollback()
        self:change_x(self.pastx)
        self:change_y(self.pasty)
    end

    -- calculate moves for the person
    function person:next_moves(dt)
        -- calculate x and y dislocation
        local deltax = self.xspeed * dt
        local deltay = self.yspeed * dt
        -- calculate number of steps
        local steps = math.ceil(math.max(math.abs(deltax), math.abs(deltay)))
        local moves = {}
        -- dividing the movement in small steps avoids your character to pass through walls if they are at high speeds
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

-- example of modifying/extending the person class

-- use images when drawing the person
function M.createImagePerson(imagefront, imageback, x, y, color, maxspeed, accel, decel)
    local w, h = imagefront:getDimensions()
    local person = M.create_Person(x, y, color, maxspeed, accel, decel)
    -- redefining the draw function, yes you can just redefine functions no problem :)
    function person:draw()
        -- set color
        love.graphics.setColor(self.color)
        if self.dead then
            love.graphics.setColor(0, 0, 0)
        end

        -- decide which image to show
        local image
        if self.front then
            image = imagefront
        else
            image = imageback
        end
        love.graphics.draw(image, self.coord.x, self.coord.y, nil, nil, nil, w / 2, (h - self.height) + self.height / 2)
    end

    return person
end

return M
