local ui = {}

---base class for navigatable items
---@class Navigatable
---@field state string state (normal, selected, clicked)
---@field position number number to determine the position in the list of navigatables
---@field x number coordinate for coordinate navigation
---@field y number coordinate for coordinate navigation
---@field draw function draws the navigatable
---@field checkHit function checks if coordinates are in hitbox
---@field update function called to manage state receives (x, y, dt)
---@field click function executes the onclicked function

---@param xp number position x of hitbox
---@param yp number position y of hitbox
---@param xs number size on x axis of hitbox
---@param ys number size on y axis of hitbox
---@param drawfunction function called when draw is called parameters are x, y, xs, ys, state (normal, selected, clicked)
---@param onclicked function function that returns a boolean and is called when pressed
---@param position number number to determine the position in the list of the button in navigatable list
---@param click_time number time in seconds of clicked stated
---returns a button
function ui.createButton(xp, yp, xs, ys, drawfunction, onclicked, position, click_time)
    ---@class button: Navigatable
    local button = {
        x = xp,
        y = yp,
        xs = xs,
        ys = ys,
        clicked_timer = 0,
        click_time = click_time,
        position = position,
        state = 'normal',
    }
    ---draws the button
    function button:draw()
        drawfunction(self.x, self.y, self.xs, self.ys, self.state)
    end

    ---executes the onclicked function
    function button:click()
        self.state = 'clicked'
        self.clicked_timer = click_time
        onclicked()
    end

    ---manages state and a bunch of stuff
    function button:update(dt)
        if self.state == 'clicked' then
            if self.clicked_timer > 0 then
                self.clicked_timer = self.clicked_timer - dt
            else
                self.state = 'normal'
                self.clicked_timer = 0
            end
        end
    end

    ---manages state and a bunch of stuff when not using KeyboardNavigator
    function button:update_alone(x, y, dt)
        if self.state == 'clicked' then
            if self.clicked_timer > 0 then
                self.clicked_timer = self.clicked_timer - dt
            else
                self.state = 'normal'
                self.clicked_timer = 0
            end
        else
            if self:checkHit(x, y) then
                self.state = 'selected'
            else
                self.state = 'normal'
            end
        end
    end

    ---@param x number
    ---@param y number
    ---@return boolean
    ---use this function to to check if the some coordinate is inside the button
    function button:checkHit(x, y)
        if x > self.x and x < self.x + self.xs and y > self.y and y < self.y + self.ys then
            return true
        end
        return false
    end

    return button
end

function table.shallow_copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

function table.search(t, value, equal_func)
    if not equal_func then
        equal_func = function(a, b) return a == b end
    end
    local found = false
    local index
    for i, v in ipairs(t) do
        index = i
        if equal_func(v, value) then
            found = true
            break
        end
    end
    if found then
        return index
    else
        return false
    end
end

---Creates KeyboardNavigator which allows to easily implement keyboard navigation
---@param items Navigatable[]|nil
function ui.createKeyBoardNavigation(items)
    if items == nil then
        items = {}
    end

    local itemsp = table.shallow_copy(items)
    local itemsx = table.shallow_copy(items)
    local itemsy = table.shallow_copy(items)

    ---@class KeyboardNavigator
    ---@field items Navigatable[] in position order
    ---@field itemsx Navigatable[] in x order
    ---@field itemsy Navigatable[] in y order
    ---@field selected number|nil index of selected item in position list
    local KeyboardNavigator = {
        items = itemsp,
        itemsx = itemsx,
        itemsy = itemsy,
        selected = nil,
    }
    function KeyboardNavigator:draw()
        for _, button in ipairs(self.items) do
            button:draw()
        end
    end

    function KeyboardNavigator:update(dt)
        local x, y = love.mouse.getPosition()
        for k, button in pairs(self.items) do
            if button:checkHit(x, y) then
                self.selected = k
            end
        end
        love.keyboard.isDown('j')
        if key == 'j' and not isrepeat then
            print('j')
            local x = self:next()
            assert(x)
            print(x.state)
            x.state = 'selected'
            print(x.state)
        elseif key == 'k' and not isrepeat then
            print('k')
            self:previous().state = 'selected'
        elseif key == 'space' and not isrepeat then
            print('space')
            if #self.items == 0 then
                return nil
            elseif not self.selected then
                self.selected = 1
            end
            self:current().click()
        end
        for k, button in pairs(self.items) do
            button:update(x, y, dt, true)
            if button.state ~= 'clicked' then
                if k == self.selected then
                    button.state = 'selected'
                else
                    button.state = 'normal'
                end
            end
        end
    end

    function KeyboardNavigator:keyreleased(key, isrepeat)
    end

    function KeyboardNavigator:checkHit(x, y)
        local hit = {}
        local nohit = {}
        for _, button in ipairs(self.items) do
            if button:checkHit(x, y) then
                table.insert(hit, button)
            else
                table.insert(nohit, button)
            end
        end
        return hit, nohit
    end

    function KeyboardNavigator:sort()
        table.sort(self.items, function(a, b)
            return a.position < b.position
        end)
        table.sort(self.itemsx, function(a, b)
            return a.x < b.x
        end)
        table.sort(self.itemsy, function(a, b)
            return a.y < b.y
        end)
    end

    ---add item to navigator
    ---@param item Navigatable
    function KeyboardNavigator:add(item)
        table.insert(self.items, item)
        if self.selected and item.position < self.items[self.selected].position then
            self.selected = self.selected + 1
        end
        table.insert(self.itemsx, item)
        table.insert(self.itemsy, item)
        self:sort()
    end

    ---remove item from navigator
    ---@param item Navigatable
    function KeyboardNavigator:remove(item)
        if self.selected and item.position < self.items[self.selected].position then
            self.selected = self.selected - 1
        end
        local index = table.search(self.items, item)
        assert(index)
        table.remove(self.items, index)
        index = table.search(self.itemsx, item)
        assert(index)
        table.remove(self.itemsx, index)
        index = table.search(self.itemsy, item)
        assert(index)
        table.remove(self.itemsy, index)
    end

    ---gets next item of the position list
    function KeyboardNavigator:next()
        if #self.items == 0 then
            print('no items')
            return nil
        elseif not self.selected then
            self.selected = 1
        elseif self.selected < #self.items then
            self.selected = self.selected + 1
        else
            self.selected = 1
        end
        return self:current()
    end

    ---gets previous item of the position list
    function KeyboardNavigator:previous()
        if #self.items == 0 then
            return nil
        elseif not self.selected then
            self.selected = #self.items
        elseif self.selected > 1 then
            self.selected = self.selected - 1
        else
            self.selected = #self.items
        end
        return self:current()
    end

    ---gets item to the left
    function KeyboardNavigator:left()
        if #self.items == 0 then
            return nil
        elseif not self.selected then
            local selected = table.search(self.items, self.itemsx[1])
            assert(selected)
            self.selected = selected
            return self:current()
        end

        local index = table.search(self.itemsx, self.items[self.selected])
        if self.items[self.selected].x > self.itemsx[1].x then
            index = index - 1
        else
            index = #self.itemsx
        end
        index = table.search(self.items, self.itemsx[index])
        assert(index)
        self.selected = index
        return self:current()
    end

    ---gets item to the right
    function KeyboardNavigator:right()
        if #self.items == 0 then
            return nil
        elseif not self.selected then
            local selected = table.search(self.items, self.itemsx[#self.itemsx])
            assert(selected)
            self.selected = selected
            return self:current()
        end

        local index = table.search(self.itemsx, self.items[self.selected])
        if self.items[self.selected].x < self.itemsx[#self.itemsx].x then
            index = index + 1
        else
            index = 1
        end
        index = table.search(self.items, self.itemsx[index])
        assert(index)
        self.selected = index
        return self:current()
    end

    ---gets item above
    function KeyboardNavigator:up()
        if #self.items == 0 then
            return nil
        elseif not self.selected then
            local selected = table.search(self.items, self.itemsy[1])
            assert(selected)
            self.selected = selected
            return self:current()
        end

        local index = table.search(self.itemsy, self.items[self.selected])
        if self.items[self.selected].y > self.itemsy[1].y then
            index = index - 1
        else
            index = #self.itemsy
        end
        index = table.search(self.items, self.itemsy[index])
        assert(index)
        self.selected = index
        return self:current()
    end

    ---gets item below
    function KeyboardNavigator:down()
        if #self.items == 0 then
            return nil
        elseif not self.selected then
            local selected = table.search(self.items, self.itemsy[#self.itemsy])
            assert(selected)
            self.selected = selected
            return self:current()
        end

        local index = table.search(self.itemsy, self.items[self.selected])
        if self.items[self.selected].y < self.itemsy[#self.itemsy].y then
            index = index + 1
        else
            index = 1
        end
        index = table.search(self.items, self.itemsy[index])
        assert(index)
        self.selected = index
        return self:current()
    end

    function KeyboardNavigator:current()
        return self.items[self.selected]
    end

    KeyboardNavigator:sort()
    return KeyboardNavigator
end

-- local button = ui.createButton(5,1,1,1,function () end,function()end,10,false)
-- local button1 = ui.createButton(4,2,1,1,function () end,function()end,20,false)
-- local button2 = ui.createButton(3,3,1,1,function () end,function()end,50,false)
-- local button3 = ui.createButton(2,4,1,1,function () end,function()end,40,false)
-- local button4 = ui.createButton(1,5,1,1,function () end,function()end,30,false)

-- local navigator = ui.createKeyBoardNavigation({button, button2, button3, button4})
-- for _, v in pairs(navigator.items) do
-- 	print(v.position)
-- end
-- print()
-- navigator:add(button1)
-- for _, v in pairs(navigator.items) do
-- 	print(v.position)
-- end
-- print()
-- navigator:remove(button1)
-- for _, v in pairs(navigator.items) do
-- 	print(v.position)
-- end
--
return ui
