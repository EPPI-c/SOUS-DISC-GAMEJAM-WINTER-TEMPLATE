local helper = require 'helper'

local M = {}

-- class definition this helps your editor to provide suggestions and check for errors

--- car class
---@class Car
---@field coord Coord coordinate of the car
---@field pastcoord Coord past coordinate
---@field hitbox Hitbox hitbox of the car
---@field maxspeed number maximum speed of the car
---@field speed number current speed
---@field direction number direction of the car
---@field accel number acceleration of the car above 0
---@field decel number deceleration of the car should be between 0 and 1
---@field turnspeed number speed it turns
---@field width number width of the car this is used for the hitbox
---@field height number height of the car this is used for the hitbox
---@field color table {red, green, blue} default color of the car
---@field draw function function that draws the car
---@field change_x function (x) changes the car x coordinate
---@field change_y function (y) changes the car y coordinate
---@field rollback function rollback to last position before using change if the car collided
---@field accelerate function (dt, x, y) changes the speed of the car dt is the time delta since last frame and x and y should be -1, 0 or 1 and define in which direction the car is moving
---@field next_moves function (dt) gives the next moves based on acceleration
---@field turnleft function (dt) turns left
---@field turnright function (dt) turns right

---@param x number x position of the car
---@param y number y position of the car
---@param color table color of the car
---@param maxspeed number maximum speed of the car
---@param accel number acceleration of the car above 0
---@param decel number deceleration of the car should be between 0 and 1
---@return Car
function M.create_Car(x, y, color, maxspeed, accel, decel, turnspeed)
    local coord = helper.create_coord(x, y)
    local width = 20
    local height = 20
    ---@class Car
    local car = {
        dead = false,
        coord = coord,
        color = color,
        width = width,
        height = height,
        speed = 0,
        direction = 0,
        maxspeed = maxspeed,
        accel = accel,
        decel = decel,
        turnspeed = turnspeed,
        pastcoord = coord,
        hitbox = helper.create_hitbox(
            helper.create_coord(coord.x - width / 2, coord.y - height / 2),
            helper.create_coord(coord.x + width / 2, coord.y + height / 2)
        ),
    }

    function car:draw()
        print('x:',self.coord.x)
        print('y:',self.coord.y)
        print('direction:',self.direction)
        print('speed:',self.speed)
        love.graphics.push()
        love.graphics.translate(self.coord.x, self.coord.y)
        love.graphics.rotate(self.direction)
        love.graphics.setColor(self.color)
        love.graphics.rectangle(
            'fill',
            -self.width / 2,
            -self.height / 2,
            self.width,
            self.height
        )
        love.graphics.pop()
    end

    ---@diagnostic disable-next-line: redefined-local
    function car:change_x(x)
        self.pastcoord.x = self.coord.x
        self.pastcoord.y = self.coord.y
        self.coord.x = x
        self.hitbox.topLeft.x = x - self.width / 2
        self.hitbox.bottomRight.x = x + self.width / 2
    end

    ---@diagnostic disable-next-line: redefined-local
    function car:change_y(y)
        if self.dead then
            return
        end
        self.pastcoord.x = self.coord.x
        self.pastcoord.y = self.coord.y
        self.coord.y = y
        self.hitbox.topLeft.y = y - self.height / 2
        self.hitbox.bottomRight.y = y + self.height / 2
    end

    function car:turnleft(dt)
        self.direction = self.direction - self.turnspeed * dt
    end

    function car:turnright(dt)
        self.direction = self.direction + self.turnspeed * dt
    end

    ---@param dt number delta time
    ---@param dir number -1: accelerating backwards, 0: not accelerating, 1:accelerating forwards
    ---@diagnostic disable-next-line: redefined-local
    function car:accelerate(dt, dir)
        -- calculate the change of speed in the correct direction already
        local ax = dir * self.accel * dt

        -- change speed
        self.speed = self.speed + ax

        -- verify if your above max speed
        if self.speed > self.maxspeed then
            self.speed = self.maxspeed
        elseif self.speed < -self.maxspeed then
            self.speed = -self.maxspeed
        end
        -- decelerate if you're not moving
        if dir == 0 then
            self.speed = helper.round(self.speed - self.speed * self.decel, 1)
            -- stop at once, if you don't have the speed will keep getting smaller and smaller without becoming 0
            if math.abs(self.speed) < 1 then
                self.speed = 0
            end
        end
    end

    function car:rollback()
        self:change_x(self.pastcoord.x)
        self:change_y(self.pastcoord.y)
    end

    -- calculate moves for the car
    function car:next_moves(dt)
        -- calculate x and y dislocation
        local deltax = math.cos(self.direction) * self.speed * dt
        local deltay = math.sin(self.direction) * self.speed * dt
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

    return car
end

-- -- use images when drawing the person
-- function M.createImageCar(imagefront, imageback, x, y, color, maxspeed, accel, decel)
--     local w, h = imagefront:getDimensions()
--     local car = M.create_Car(x, y, color, maxspeed, accel, decel)
--     -- redefining the draw function, yes you can just redefine functions no problem :)
--     function car:draw()
--         -- set color
--         love.graphics.setColor(self.color)
--         if self.dead then
--             love.graphics.setColor(0, 0, 0)
--         end
--
--         -- decide which image to show
--         local image
--         if self.front then
--             image = imagefront
--         else
--             image = imageback
--         end
--         love.graphics.draw(image, self.coord.x, self.coord.y, nil, nil, nil, w / 2, (h - self.height) + self.height / 2)
--     end
--
--     return car
-- end

return M
