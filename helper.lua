local M = {}

---Coordinate class
---@class Coord
---@field x number x position
---@field y number y position
---@field distance function
function M.create_coord(x, y)
    local coord = {x=x, y=y}
    ---@param point Coord coordinate to calculate distance to
    ---calculates distance to point
    function coord:distance(point)
        return math.sqrt(math.pow(self.x - point.x, 2) + math.pow(self.y - point.y, 2))
    end
    return coord
end


return M
