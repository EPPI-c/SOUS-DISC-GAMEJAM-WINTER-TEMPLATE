local helper = require 'helper'
local person = require 'person'

local streets = {}

local buildingblue = helper.hex_to_rgb(0x1c4863)
local streetblue = helper.hex_to_rgb(0x345163)
local streetwhite = helper.hex_to_rgb(0xa89ba5)
local sidewalkblue = helper.hex_to_rgb(0x658788)

local function rectangle(mode, x1, y1, x2, y2)
    love.graphics.rectangle(mode, x1, y1, x2 - x1, y2 - y1)
end

local function translate(x, y, points)
    local isx = true
    local real = {}
    for _, v in pairs(points) do
        if isx then
            v = v + x
        else
            v = v + y
        end
        table.insert(real, v)
        isx = not isx
    end
    return real
end

---@param x number
---@param y number
---@param hitbox Hitbox
local function translate_hitbox(x, y, hitbox)
    local x1, y1, x2, y2 = unpack(translate(x, y,
        { hitbox.topLeft.x, hitbox.topLeft.y, hitbox.bottomRight.x, hitbox.bottomRight.y }))
    return helper.create_hitbox(helper.create_coord(x1, y1), helper.create_coord(x2, y2))
end

local function rotate_and_translate(x, y, width, height, radians)
    if not radians then
        radians = 0
    end
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.translate(width / 2, height / 2)
    love.graphics.rotate(radians)
    love.graphics.translate(-width / 2, -height / 2)
end

local function check_collision(x, y, hitbox, walls)
    hitbox = translate_hitbox(-x, -y, hitbox)
    local hit = false
    for _, wall in pairs(walls) do
        local wallhitbox = wall
        if wallhitbox:check_collision(hitbox) then
            hit = true
        end
    end
    return hit
end

function streets.create_vertical(x, y, width, height)
    local walls = width * 0.1
    local street = {
        name = 'vertical',
        x = x,
        y = y,
        width = width,
        height = height,
        walls = walls,
        wall1 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(walls, height)),
        wall2 = helper.create_hitbox(helper.create_coord(width - walls, 0), helper.create_coord(width, height)),
        piecesup = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_corner_downleft,
            streets.create_corner_downright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesdown = {
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_upleft,
            streets.create_corner_upright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesleft = {
        },
        piecesright = {
        },
    }

    ---@param hitbox Hitbox
    function street:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2 })
    end

    function street:draw()
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        local stripegapratio = 0.2
        local stripeq = 8
        local stripeh = self.height / stripeq
        local stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)
        local stripew = self.height * 0.03

        local streetw = self.width * 0.5
        love.graphics.setColor(buildingblue)
        love.graphics.rectangle('fill', 0, 0, self.walls, self.height)
        love.graphics.rectangle('fill', self.width - self.walls, 0, self.walls, self.height)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)

        love.graphics.setColor(streetblue)
        love.graphics.rectangle('fill', self.width / 2 - streetw / 2, 0, streetw, self.height)
        love.graphics.setColor(streetwhite)
        for stripe_y = 0, stripeq - 1 do
            love.graphics.rectangle('fill', self.width / 2 - stripew / 2, stripe_y * (stripeh + stripegap),
                stripew, stripeh)
        end

        love.graphics.pop()
    end

    return street
end

function streets.create_horizontal(x, y, width, height)
    local walls = height * 0.1
    local street = {
        name = 'horizontal',
        x = x,
        y = y,
        width = width,
        height = height,
        walls = walls,
        wall1 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(width, walls)),
        wall2 = helper.create_hitbox(helper.create_coord(0, height - walls), helper.create_coord(width, height)),
        piecesup = {
        },
        piecesdown = {
        },
        piecesleft = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_downright,
            streets.create_corner_upright,
            streets.create_horizontal,
            streets.create_intersection,
        },
        piecesright = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_up,
            streets.create_corner_downleft,
            streets.create_corner_upleft,
            streets.create_horizontal,
            streets.create_intersection,
        },
    }

    ---@param hitbox Hitbox
    function street:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2 })
    end

    function street:draw()
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        local stripegapratio = 0.2
        local stripeq = 8
        local stripeh = self.width / stripeq
        local stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)
        local stripew = self.width * 0.03

        local streetw = self.height * 0.5
        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)

        love.graphics.setColor(streetblue)
        love.graphics.rectangle('fill', 0, self.height / 2 - streetw / 2, self.height, streetw)
        love.graphics.setColor(streetwhite)
        for stripe_y = 0, stripeq - 1 do
            love.graphics.rectangle('fill', stripe_y * (stripeh + stripegap), self.width / 2 - stripew / 2,
                stripeh, stripew)
        end

        love.graphics.pop()
    end

    return street
end

local function ellipse_point(x, a, b)
    return math.sqrt(b ^ 2 * (1 - (x ^ 2 / a ^ 2)))
end
local function arc(s, e, resolution)
    local points = {}
    local streetpoint = s / resolution
    for i = 0, resolution do
        local xpoint = s - i * streetpoint
        local ypoint = ellipse_point(xpoint, e, s)
        table.insert(points, xpoint)
        table.insert(points, ypoint)
    end
    return points
end

function streets.create_corner_downleft(x, y, width, height, resolution)
    if not resolution then
        resolution = 99
    end
    local wallsv = width * 0.1
    local wallsh = height * 0.1
    local corner = {
        name = 'corner_downleft',
        x = x,
        y = y,
        width = width,
        height = height,
        wallsv = wallsv,
        wallsh = wallsh,
        wall1 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(width, wallsh)),
        wall2 = helper.create_hitbox(helper.create_coord(width - wallsv, 0), helper.create_coord(width, height)),
        wall3 = helper.create_hitbox(helper.create_coord(0, height - wallsh), helper.create_coord(wallsv, height)),
        resolution = resolution,
        piecesup = {
        },
        piecesdown = {
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_upleft,
            streets.create_corner_upright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesleft = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_downright,
            streets.create_corner_upright,
            streets.create_horizontal,
            streets.create_intersection,
        },
        piecesright = {
        },
    }

    ---@param hitbox Hitbox
    function corner:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2, self.wall3 })
    end

    function corner:draw()
        rotate_and_translate(self.x, self.y, self.width, self.height, self.radians)
        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)

        love.graphics.setColor(streetblue)
        local street = self.width * 0.5
        local streetup = self.width / 2 - street / 2
        local streetdown = self.width / 2 + street / 2
        local streetr = self.height / 2 - street / 2
        local streetl = self.height / 2 + street / 2

        local a = arc(streetdown, streetl, self.resolution)
        table.insert(a, 0)
        table.insert(a, 0)
        love.graphics.push()
        love.graphics.translate(self.width / 2, self.height / 2)
        love.graphics.rotate(math.rad(-90))
        love.graphics.translate(-self.width / 2, -self.height / 2)
        love.graphics.polygon('fill', a)
        love.graphics.setColor(sidewalkblue)
        a = arc(streetup, streetr, self.resolution)
        table.insert(a, 0)
        table.insert(a, 0)
        love.graphics.polygon('fill', a)
        love.graphics.pop()

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall3.topLeft.x, self.wall3.topLeft.y, self.wall3.bottomRight.x, self.wall3.bottomRight.y)

        love.graphics.pop()
    end

    return corner
end

function streets.create_corner_downright(x, y, width, height, resolution)
    if not resolution then
        resolution = 99
    end
    local wallsv = width * 0.1
    local wallsh = height * 0.1
    local corner = {
        name = 'corner_downright',
        x = x,
        y = y,
        width = width,
        height = height,
        wallsv = wallsv,
        wallsh = wallsh,
        wall1 = helper.create_hitbox(helper.create_coord(0, 0),
            helper.create_coord(width, wallsv)),
        wall2 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(wallsv, height)),
        wall3 = helper.create_hitbox(helper.create_coord(width - wallsv, height - wallsh),
            helper.create_coord(width, height)),
        resolution = resolution,
        piecesup = {
        },
        piecesdown = {
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_upleft,
            streets.create_corner_upright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesleft = {
        },
        piecesright = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_up,
            streets.create_corner_downleft,
            streets.create_corner_upleft,
            streets.create_horizontal,
            streets.create_intersection,
        },
    }

    ---@param hitbox Hitbox
    function corner:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2, self.wall3 })
    end

    function corner:draw()
        rotate_and_translate(self.x, self.y, self.width, self.height, self.radians)
        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        love.graphics.setColor(buildingblue)

        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)

        love.graphics.setColor(streetblue)
        local street = self.width * 0.5
        local streetup = self.width / 2 - street / 2
        local streetdown = self.width / 2 + street / 2
        local streetr = self.height / 2 - street / 2
        local streetl = self.height / 2 + street / 2

        love.graphics.push()
        love.graphics.translate(self.width / 2, self.height / 2)
        love.graphics.rotate(math.rad(180))
        love.graphics.translate(-self.width / 2, -self.height / 2)
        local a = arc(streetdown, streetl, self.resolution)
        table.insert(a, 0)
        table.insert(a, 0)
        love.graphics.polygon('fill', a)
        love.graphics.setColor(sidewalkblue)
        a = arc(streetup, streetr, self.resolution)
        table.insert(a, 0)
        table.insert(a, 0)
        love.graphics.polygon('fill', a)
        love.graphics.pop()

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall3.topLeft.x, self.wall3.topLeft.y, self.wall3.bottomRight.x, self.wall3.bottomRight.y)

        love.graphics.pop()
    end

    return corner
end

function streets.create_corner_upright(x, y, width, height, resolution)
    if not resolution then
        resolution = 99
    end
    local wallsv = width * 0.1
    local wallsh = height * 0.1
    local corner = {
        name = 'corner_upright',
        x = x,
        y = y,
        width = width,
        height = height,
        wallsv = wallsv,
        wallsh = wallsh,
        wall1 = helper.create_hitbox(helper.create_coord(0, height - wallsh), helper.create_coord(height, width)),
        wall2 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(wallsv, height)),
        wall3 = helper.create_hitbox(helper.create_coord(width - wallsv, 0), helper.create_coord(width, wallsh)),
        resolution = resolution,
        piecesup = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_corner_downleft,
            streets.create_corner_downright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesdown = {
        },
        piecesleft = {
        },
        piecesright = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_up,
            streets.create_corner_downleft,
            streets.create_corner_upleft,
            streets.create_horizontal,
            streets.create_intersection,
        },
    }

    ---@param hitbox Hitbox
    function corner:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2, self.wall3 })
    end

    function corner:draw()
        rotate_and_translate(self.x, self.y, self.width, self.height, self.radians)
        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)

        love.graphics.setColor(streetblue)
        local street = self.width * 0.5
        local streetup = self.width / 2 - street / 2
        local streetdown = self.width / 2 + street / 2
        local streetr = self.height / 2 - street / 2
        local streetl = self.height / 2 + street / 2

        love.graphics.push()
        love.graphics.translate(self.width / 2, self.height / 2)
        love.graphics.rotate(math.rad(90))
        love.graphics.translate(-self.width / 2, -self.height / 2)
        local a = arc(streetdown, streetl, self.resolution)
        table.insert(a, 0)
        table.insert(a, 0)
        love.graphics.polygon('fill', a)
        love.graphics.setColor(sidewalkblue)
        a = arc(streetup, streetr, self.resolution)
        table.insert(a, 0)
        table.insert(a, 0)
        love.graphics.polygon('fill', a)
        love.graphics.pop()

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall3.topLeft.x, self.wall3.topLeft.y, self.wall3.bottomRight.x, self.wall3.bottomRight.y)

        love.graphics.pop()
    end

    return corner
end

function streets.create_corner_upleft(x, y, width, height, resolution)
    if not resolution then
        resolution = 99
    end
    local wallsv = width * 0.1
    local wallsh = height * 0.1
    local corner = {
        name = 'corner_upleft',
        x = x,
        y = y,
        width = width,
        height = height,
        wallsv = wallsv,
        wallsh = wallsh,
        wall1 = helper.create_hitbox(helper.create_coord(0, height - wallsh), helper.create_coord(height, width)),
        wall2 = helper.create_hitbox(helper.create_coord(width - wallsv, 0), helper.create_coord(width, height)),
        wall3 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(wallsv, wallsh)),
        resolution = resolution,
        piecesup = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_corner_downleft,
            streets.create_corner_downright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesdown = {
        },
        piecesleft = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_downright,
            streets.create_corner_upright,
            streets.create_horizontal,
            streets.create_intersection,
        },
        piecesright = {
        },
    }

    ---@param hitbox Hitbox
    function corner:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2, self.wall3 })
    end

    function corner:draw()
        rotate_and_translate(self.x, self.y, self.width, self.height, self.radians)
        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)

        love.graphics.setColor(streetblue)
        local street = self.width * 0.5
        local streetup = self.width / 2 - street / 2
        local streetdown = self.width / 2 + street / 2
        local streetr = self.height / 2 - street / 2
        local streetl = self.height / 2 + street / 2

        local a = arc(streetdown, streetl, self.resolution)
        table.insert(a, 0)
        table.insert(a, 0)
        love.graphics.polygon('fill', a)
        love.graphics.setColor(sidewalkblue)
        a = arc(streetup, streetr, self.resolution)
        table.insert(a, 0)
        table.insert(a, 0)
        love.graphics.polygon('fill', a)

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall3.topLeft.x, self.wall3.topLeft.y, self.wall3.bottomRight.x, self.wall3.bottomRight.y)

        love.graphics.pop()
    end

    return corner
end

function streets.create_intersection(x, y, width, height)
    local wallsv = width * 0.1
    local wallsh = height * 0.1
    local intersection = {
        name = 'intersection',
        x = x,
        y = y,
        width = width,
        height = height,
        wallsv = wallsv,
        wallsh = wallsh,
        wall1 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(wallsv, wallsh)),
        wall2 = helper.create_hitbox(helper.create_coord(width - wallsv, 0), helper.create_coord(width, wallsh)),
        wall3 = helper.create_hitbox(helper.create_coord(0, height - wallsh), helper.create_coord(wallsv, height)),
        wall4 = helper.create_hitbox(helper.create_coord(width - wallsv, height - wallsh),
            helper.create_coord(width, height)),
        piecesup = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_corner_downleft,
            streets.create_corner_downright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesdown = {
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_upleft,
            streets.create_corner_upright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesleft = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_downright,
            streets.create_corner_upright,
            streets.create_horizontal,
            streets.create_intersection,
        },
        piecesright = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_up,
            streets.create_corner_downleft,
            streets.create_corner_upleft,
            streets.create_horizontal,
            streets.create_intersection,
        },
    }

    ---@param hitbox Hitbox
    function intersection:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2, self.wall3, self.wall4 })
    end

    function intersection:draw()
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)
        love.graphics.setColor(streetblue)
        local streetw = self.width * 0.5
        love.graphics.rectangle('fill', self.width / 2 - streetw / 2, 0, streetw, self.height)
        love.graphics.rectangle('fill', 0, self.height / 2 - streetw / 2, self.width, streetw)

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)
        rectangle('fill', self.wall3.topLeft.x, self.wall3.topLeft.y, self.wall3.bottomRight.x, self.wall3.bottomRight.y)
        rectangle('fill', self.wall4.topLeft.x, self.wall4.topLeft.y, self.wall4.bottomRight.x, self.wall4.bottomRight.y)

        love.graphics.setColor(streetwhite)

        local stripegapratio = 0.2
        local stripeq = 8
        local stripeh = self.height / stripeq
        local stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)
        local stripew = self.height * 0.03

        -- vertical stripes
        for stripe_y = 0, stripeq - 1 do
            love.graphics.rectangle('fill', self.width / 2 - stripew / 2, stripe_y * (stripeh + stripegap),
                stripew, stripeh)
        end
        love.graphics.rectangle('fill', self.width / 2 - stripew / 2, self.height / 2 - stripeh / 2, stripew, stripeh)

        stripeh = self.width / stripeq
        stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)

        -- horizontal stripes
        for stripe_y = 1, stripeq do
            stripe_y = stripeq - stripe_y
            love.graphics.rectangle('fill', stripe_y * (stripeh + stripegap), self.height / 2 - stripew / 2,
                stripeh, stripew)
        end
        love.graphics.rectangle('fill', self.width / 2 - stripeh / 2, self.height / 2 - stripew / 2,
            stripeh, stripew)

        love.graphics.pop()
    end

    return intersection
end

function streets.create_Tintersection_up(x, y, width, height)
    local wallsv = width * 0.1
    local wallsh = height * 0.1
    local T = {
        name = 'Tintersection_up',
        x = x,
        y = y,
        width = width,
        height = height,
        wallsv = wallsv,
        wallsh = wallsh,
        wall1 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(wallsv, wallsh)),
        wall2 = helper.create_hitbox(helper.create_coord(width - wallsv, 0), helper.create_coord(width, wallsh)),
        wall3 = helper.create_hitbox(helper.create_coord(0, height - wallsh), helper.create_coord(width, height)),
        piecesup = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_corner_downleft,
            streets.create_corner_downright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesdown = {
        },
        piecesleft = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_downright,
            streets.create_corner_upright,
            streets.create_horizontal,
            streets.create_intersection,
        },
        piecesright = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_up,
            streets.create_corner_downleft,
            streets.create_corner_upleft,
            streets.create_horizontal,
            streets.create_intersection,
        },
    }

    ---@param hitbox Hitbox
    function T:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2, self.wall3 })
    end

    function T:draw()
        love.graphics.push()
        love.graphics.translate(self.x, self.y)

        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)
        love.graphics.setColor(streetblue)

        local streetw = self.width * 0.5
        love.graphics.rectangle('fill', 0, self.height / 2 - streetw / 2, self.width, streetw)
        love.graphics.rectangle('fill', self.width / 2 - streetw / 2, 0, streetw, self.height / 2)

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)
        rectangle('fill', self.wall3.topLeft.x, self.wall3.topLeft.y, self.wall3.bottomRight.x, self.wall3.bottomRight.y)

        local stripegapratio = 0.2
        local stripeq = 4
        local stripeh = self.height / 2 / stripeq
        local stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)
        local stripew = self.height * 0.03

        love.graphics.setColor(streetwhite)

        -- vertical stripes
        for stripe_y = 0, stripeq - 1 do
            love.graphics.rectangle('fill', self.width / 2 - stripew / 2, stripe_y * (stripeh + stripegap),
                stripew, stripeh)
        end
        love.graphics.rectangle('fill', self.width / 2 - stripew / 2, self.height / 2 - stripeh / 2, stripew, stripeh / 2)

        stripeq = 8
        stripeh = self.width / stripeq
        stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)

        -- horizontal stripes
        for stripe_y = 0, stripeq - 1 do
            love.graphics.rectangle('fill', stripe_y * (stripeh + stripegap), self.height / 2 - stripew / 2,
                stripeh, stripew)
        end
        love.graphics.rectangle('fill', self.width / 2 - stripeh / 2, self.height / 2 - stripew / 2,
            stripeh, stripew)

        love.graphics.pop()
    end

    return T
end

function streets.create_Tintersection_left(x, y, width, height)
    local wallsv = width * 0.1
    local wallsh = height * 0.1
    local T = {
        name = 'Tintersection_left',
        x = x,
        y = y,
        width = width,
        height = height,
        wallsv = wallsv,
        wallsh = wallsh,
        wall1 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(wallsv, wallsh)),
        wall2 = helper.create_hitbox(helper.create_coord(0, height - wallsh), helper.create_coord(wallsv, height)),
        wall3 = helper.create_hitbox(helper.create_coord(width - wallsh, 0), helper.create_coord(width, height)),
        piecesup = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_corner_downleft,
            streets.create_corner_downright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesdown = {
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_upleft,
            streets.create_corner_upright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesleft = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_downright,
            streets.create_corner_upright,
            streets.create_horizontal,
            streets.create_intersection,
        },
        piecesright = {
        },
    }

    ---@param hitbox Hitbox
    function T:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2, self.wall3 })
    end

    function T:draw()
        love.graphics.push()
        love.graphics.translate(self.x, self.y)

        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)
        love.graphics.setColor(streetblue)

        local streetw = self.width * 0.5
        love.graphics.rectangle('fill', 0, self.height / 2 - streetw / 2, self.width / 2, streetw)
        love.graphics.rectangle('fill', self.width / 2 - streetw / 2, 0, streetw, self.height)

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)
        rectangle('fill', self.wall3.topLeft.x, self.wall3.topLeft.y, self.wall3.bottomRight.x, self.wall3.bottomRight.y)

        local stripegapratio = 0.2
        local stripeq = 8
        local stripeh = self.height / stripeq
        local stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)
        local stripew = self.height * 0.03

        love.graphics.setColor(streetwhite)

        -- vertical stripes
        for stripe_y = 0, stripeq - 1 do
            love.graphics.rectangle('fill', self.width / 2 - stripew / 2, stripe_y * (stripeh + stripegap),
                stripew, stripeh)
        end
        love.graphics.rectangle('fill', self.width / 2 - stripew / 2, self.height / 2 - stripeh / 2,
            stripew, stripeh)

        stripeq = 8
        stripeh = self.width / stripeq
        stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)

        -- horizontal stripes
        for stripe_y = 0, stripeq / 2 - 1 do
            love.graphics.rectangle('fill', stripe_y * (stripeh + stripegap), self.height / 2 - stripew / 2,
                stripeh, stripew)
        end
        love.graphics.rectangle('fill', self.width / 2 - stripeh, self.height / 2 - stripew / 2,
            stripeh, stripew)

        love.graphics.pop()
    end

    return T
end

function streets.create_Tintersection_right(x, y, width, height)
    local wallsv = width * 0.1
    local wallsh = height * 0.1
    local T = {
        name = 'Tintersection_right',
        x = x,
        y = y,
        width = width,
        height = height,
        wallsv = wallsv,
        wallsh = wallsh,
        wall1 = helper.create_hitbox(helper.create_coord(width - wallsv, 0), helper.create_coord(width, wallsh)),
        wall2 = helper.create_hitbox(helper.create_coord(width - wallsv, height - wallsh),
            helper.create_coord(width, height)),
        wall3 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(wallsv, height)),
        piecesup = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_corner_downleft,
            streets.create_corner_downright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesdown = {
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_upleft,
            streets.create_corner_upright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesleft = {
        },
        piecesright = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_up,
            streets.create_corner_downleft,
            streets.create_corner_upleft,
            streets.create_horizontal,
            streets.create_intersection,
        },
    }

    ---@param hitbox Hitbox
    function T:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2, self.wall3 })
    end

    function T:draw()
        love.graphics.push()
        love.graphics.translate(self.x, self.y)

        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)
        love.graphics.setColor(streetblue)

        local streetw = self.width * 0.5
        love.graphics.rectangle('fill', self.width / 2, self.height / 2 - streetw / 2, self.width / 2, streetw)
        love.graphics.rectangle('fill', self.width / 2 - streetw / 2, 0, streetw, self.height)

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)
        rectangle('fill', self.wall3.topLeft.x, self.wall3.topLeft.y, self.wall3.bottomRight.x, self.wall3.bottomRight.y)

        local stripegapratio = 0.2
        local stripeq = 8
        local stripeh = self.height / stripeq
        local stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)
        local stripew = self.height * 0.03

        love.graphics.setColor(streetwhite)

        -- vertical stripes
        for stripe_y = 0, stripeq - 1 do
            love.graphics.rectangle('fill', self.width / 2 - stripew / 2, stripe_y * (stripeh + stripegap),
                stripew, stripeh)
        end
        love.graphics.rectangle('fill', self.width / 2 - stripew / 2, self.height / 2 - stripeh / 2,
            stripew, stripeh)

        stripeq = 8
        stripeh = self.width / stripeq
        stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)

        -- horizontal stripes
        for stripe_y = stripeq / 2, stripeq - 1 do
            love.graphics.rectangle('fill', stripe_y * (stripeh + stripegap), self.height / 2 - stripew / 2,
                stripeh, stripew)
        end

        love.graphics.pop()
    end

    return T
end

function streets.create_Tintersection_down(x, y, width, height)
    local wallsv = width * 0.1
    local wallsh = height * 0.1
    local T = {
        name = 'Tintersection_down',
        x = x,
        y = y,
        width = width,
        height = height,
        wallsv = wallsv,
        wallsh = wallsh,
        wall1 = helper.create_hitbox(helper.create_coord(0, 0), helper.create_coord(width, wallsh)),
        wall2 = helper.create_hitbox(helper.create_coord(width - wallsv, height - wallsh),
            helper.create_coord(width, height)),
        wall3 = helper.create_hitbox(helper.create_coord(0, height - wallsh), helper.create_coord(wallsv, height)),
        piecesup = {
        },
        piecesdown = {
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_upleft,
            streets.create_corner_upright,
            streets.create_vertical,
            streets.create_intersection,
        },
        piecesleft = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_downright,
            streets.create_corner_upright,
            streets.create_horizontal,
            streets.create_intersection,
        },
        piecesright = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_up,
            streets.create_corner_downleft,
            streets.create_corner_upleft,
            streets.create_horizontal,
            streets.create_intersection,
        },
    }

    ---@param hitbox Hitbox
    function T:check_collision(hitbox)
        return check_collision(self.x, self.y, hitbox, { self.wall1, self.wall2, self.wall3 })
    end

    function T:draw()
        love.graphics.push()
        love.graphics.translate(self.x, self.y)

        love.graphics.setColor(sidewalkblue)
        love.graphics.rectangle('fill', 0, 0, self.width, self.height)
        love.graphics.setColor(streetblue)

        local streetw = self.width * 0.5
        love.graphics.rectangle('fill', 0, self.height / 2 - streetw / 2, self.width, streetw)
        love.graphics.rectangle('fill', self.width / 2 - streetw / 2, self.height / 2, streetw, self.height / 2)

        love.graphics.setColor(buildingblue)
        rectangle('fill', self.wall1.topLeft.x, self.wall1.topLeft.y, self.wall1.bottomRight.x, self.wall1.bottomRight.y)
        rectangle('fill', self.wall2.topLeft.x, self.wall2.topLeft.y, self.wall2.bottomRight.x, self.wall2.bottomRight.y)
        rectangle('fill', self.wall3.topLeft.x, self.wall3.topLeft.y, self.wall3.bottomRight.x, self.wall3.bottomRight.y)

        local stripegapratio = 0.2
        local stripeq = 8
        local stripeh = self.height / stripeq
        local stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)
        local stripew = self.height * 0.03

        love.graphics.setColor(streetwhite)

        -- vertical stripes
        for stripe_y = stripeq / 2, stripeq - 1 do
            love.graphics.rectangle('fill', self.width / 2 - stripew / 2, stripe_y * (stripeh + stripegap),
                stripew, stripeh)
        end

        stripeq = 8
        stripeh = self.width / stripeq
        stripegap = stripeh * stripegapratio
        stripeh = stripeh * (1 - stripegapratio)

        -- horizontal stripes
        for stripe_y = 0, stripeq - 1 do
            love.graphics.rectangle('fill', stripe_y * (stripeh + stripegap), self.height / 2 - stripew / 2,
                stripeh, stripew)
        end
        love.graphics.rectangle('fill', self.width / 2 - stripeh / 2, self.height / 2 - stripew / 2,
            stripeh, stripew)

        love.graphics.pop()
    end

    return T
end

---@diagnostic disable-next-line: unused-local
function streets.create_manager(width, height, seed)
    -- store steets with locations
    local streets_table = {}
    streets_table[0] = {}
    local street = streets.create_intersection(0, 0, width, height)
    streets_table[0][0] = street
    local M = {
        width = width,
        height = height,
        streets = streets_table,
        victims = {
            draw = {},
            collision = {},
        },
        pieces = {
            streets.create_Tintersection_down,
            streets.create_Tintersection_left,
            streets.create_Tintersection_right,
            streets.create_Tintersection_up,
            streets.create_corner_downleft,
            streets.create_corner_downright,
            streets.create_corner_upleft,
            streets.create_corner_upright,
            streets.create_horizontal,
            streets.create_vertical,
            streets.create_intersection,
        }
    }

    ---@diagnostic disable-next-line: redefined-local
    function M:add_street(x, y, street)
        if not self.streets[x] then
            self.streets[x] = {}
        elseif self.streets[x][y] then
            return
        end
        self.streets[x][y] = street
        if math.random(4) == 1 then
            local victim = person.create_Person(x + self.width / 2, y + self.height / 2, { 1, .3, .3 }, 200, 2000, 0.2)
            table.insert(self.victims.draw, victim)
            table.insert(self.victims.collision, victim)
        end
    end

    function M:access(x, y)
        if not self.streets[x] then
            return nil
        end
        return self.streets[x][y]
    end

    function M:generate(i, j)
        -- this if is wrong
        -- want to check if the last generated street is out of the screen and stop must be
        -- completely out of screen i and j are the upper right corner coordinate
        local hitbox_street = helper.create_hitbox(helper.create_coord(i, j),
            helper.create_coord(i + self.width, j + self.height))
        local hitbox_screen = helper.create_hitbox(helper.create_coord(self.extremeLeft, self.extremeUp),
            helper.create_coord(self.extremeRight, self.extremeDown))
        if not hitbox_screen:check_collision(hitbox_street) then
            return
        end
        ---@diagnostic disable-next-line: redefined-local
        local street = self.streets[i][j]
        local optionsDown = #street.piecesdown
        local optionsUp = #street.piecesup
        local optionsLeft = #street.piecesleft
        local optionsRight = #street.piecesright
        if optionsDown > 0 then
            ---@diagnostic disable-next-line: redefined-local
            local j = j + self.height
            if not self:access(i, j) then
                ---@diagnostic disable-next-line: redefined-local
                local street = street.piecesdown[math.random(optionsDown)](i, j, self.width, self.height)
                self:add_street(i, j, street)
                self:generate(i, j)
            end
        end
        if optionsUp > 0 then
            ---@diagnostic disable-next-line: redefined-local
            local j = j - self.height
            if not self:access(i, j) then
                ---@diagnostic disable-next-line: redefined-local
                local street = street.piecesup[math.random(optionsUp)](i, j, self.width,
                    self.height)
                self:add_street(i, j, street)
                self:generate(i, j)
            end
        end
        if optionsLeft > 0 then
            ---@diagnostic disable-next-line: redefined-local
            local i = i - self.width
            if not self:access(i, j) then
                ---@diagnostic disable-next-line: redefined-local
                local street = street.piecesleft[math.random(optionsLeft)](i, j, self.width,
                    self.height)
                self:add_street(i, j, street)
                self:generate(i, j)
            end
        end
        if optionsRight > 0 then
            ---@diagnostic disable-next-line: redefined-local
            local i = i + self.width
            if not self:access(i, j) then
                ---@diagnostic disable-next-line: redefined-local
                local street = street.piecesright[math.random(optionsRight)](i, j, self.width,
                    self.height)
                self:add_street(i, j, street)
                self:generate(i, j)
            end
        end
        -- love.event.quit()
    end

    function M:getExtremes(x, y)
        local halfx = ScreenAreaWidth / 2
        local halfy = ScreenAreaHeight / 2
        self.extremeLeft = x - ScreenAreaWidth
        self.extremeRight = x + ScreenAreaWidth
        self.extremeUp = y - ScreenAreaHeight
        self.extremeDown = y + ScreenAreaHeight
        self.moderateLeft = x - halfx
        self.moderateRight = x + halfx
        self.moderateUp = y - halfy
        self.moderateDown = y + halfy
    end

    function M:getExtremeStreets()
        self.extremeLStreet = math.floor(self.extremeLeft / self.width) * self.width
        self.extremeRStreet = math.ceil(self.extremeRight / self.width) * self.width
        self.extremeUStreet = math.floor(self.extremeUp / self.height) * self.height
        self.extremeDStreet = math.ceil(self.extremeDown / self.height) * self.height
        self.moderateLStreet = math.floor(self.moderateLeft / self.width) * self.width
        self.moderateRStreet = math.ceil(self.moderateRight / self.width) * self.width
        self.moderateUStreet = math.floor(self.moderateUp / self.height) * self.height
        self.moderateDStreet = math.ceil(self.moderateDown / self.height) * self.height
    end

    function M:getModerateStreets()
        self.extremeLStreet = math.floor(self.extremeLeft / self.width) * self.width
        self.extremeRStreet = math.ceil(self.extremeRight / self.width) * self.width
        self.extremeUStreet = math.floor(self.extremeUp / self.height) * self.height
        self.extremeDStreet = math.ceil(self.extremeDown / self.height) * self.height
    end

    --- get coordinates of the street tile x and y are in
    ---@param x number
    ---@param y number
    ---@return number, number
    function M:getStreet(x, y)
        x = math.floor(x / self.width)
        y = math.floor(y / self.height)
        return x * self.width, y * self.height
    end

    function M:getCenter(x, y)
        x, y = self:getStreet(x, y)
        return x + self.width / 2, y + self.height / 2
    end

    function M:update(x, y)
        self:getExtremes(x, y)
        self:getExtremeStreets()
        ---@diagnostic disable-next-line: redefined-local
        local x, y = self:getStreet(x, y)
        self:generate(x, y) -- start in center
        for i = self.extremeLStreet, self.extremeRStreet, self.width do
            for j = self.extremeUStreet, self.extremeDStreet, self.height do
                if i ~= x or y ~= j then -- skip center
                    if self:access(i, j) then
                        self:generate(i, j)
                    end
                end
            end
        end
    end

    ---@param hitbox Hitbox
    function M:check_collisions(hitbox)
        local x, y = self:getStreet(hitbox.topLeft.x, hitbox.topLeft.y)
        local x1, y1 = self:getStreet(hitbox.bottomRight.x, hitbox.bottomRight.y)
        if x ~= x1 or y ~= y1 then
            if self:access(x1, y1) then
                if self.streets[x1][y1]:check_collision(hitbox) then
                    return true
                end
            end
        end
        if self:access(x, y) then
            if self.streets[x][y]:check_collision(hitbox) then
                return true
            end
        else
            return true -- if not generated block movement
        end
        return false
    end

    function M:draw()
        for i = self.moderateLStreet, self.moderateRStreet, self.width do
            for j = self.moderateUStreet, self.moderateDStreet, self.height do
                if self:access(i, j) then
                    self.streets[i][j]:draw()
                end
            end
        end
        for _, victim in pairs(self.victims.draw) do
            victim:draw()
        end
    end

    return M
end

return streets
