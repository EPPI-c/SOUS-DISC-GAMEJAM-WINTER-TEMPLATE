local helper = require 'helper'
local ui = {}
Previous_selected = 1

function ui.createButtonDraw(text, textcolor, normalcolor, selectedcolor, clickedcolor)
    return function(x, y, xs, ys, state)
        local color
        if state == 'clicked' then
            color = clickedcolor
        else
            color = normalcolor
        end
        if state == 'selected' then
            love.graphics.setColor(selectedcolor)
            love.graphics.rectangle('fill', x + 4, y + 4, xs, ys)
        end
        love.graphics.setColor(color)
        love.graphics.rectangle('fill', x, y, xs, ys)

        love.graphics.setColor(textcolor)
        love.graphics.printf(text, x, y, xs, 'center')
    end
end

function ui.createSliderDraw(text, textcolor, normalcolor, selectedcolor, clickedcolor, slidercolor)
    return function(x, y, xs, ys, state, value, active)
        local color
        if not active then
            color = { 0.1, 0.1, 0.1, 0.6 }
        else
            color = slidercolor
        end
        if state == 'selected' then
            love.graphics.setColor(selectedcolor)
            love.graphics.rectangle('fill', x + 4, y + 4, xs, ys)
        end
        love.graphics.setColor(normalcolor)
        love.graphics.rectangle('fill', x, y, xs, ys)
        love.graphics.setColor(textcolor)
        love.graphics.printf(text, x, y, xs, 'center')
        love.graphics.setColor(color)
        love.graphics.rectangle('fill', x + 2, y + 2, (xs - 4) * value, ys - 4)
    end
end

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
---@field key function executes the onclicked function

---@param xp number position x of hitbox
---@param yp number position y of hitbox
---@param xs number size on x axis of hitbox
---@param ys number size on y axis of hitbox
---@param drawfunction function called when draw is called parameters are x, y, xs, ys, state (normal, selected, clicked)
---@param onclicked function function that returns a boolean and is called when pressed
---@param position number number to determine the position in the list of the button in navigatable list
---@param click_time number time in seconds of clicked stated
---@return button
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
        Soundfx.click.sound:play()
        self.state = 'clicked'
        self.clicked_timer = self.click_time
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
        if not x or not y then
            return false
        end
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

function ui.createSlider(xp, yp, xs, ys, drawfunction, onclicked, crease_time, position, click_time, step, initial)
    if not step then
        step = 0.1
    end
    if not initial then
        initial = 0.5
    end

    ---@class Slider:button
    local slider = ui.createButton(xp, yp, xs, ys, drawfunction, onclicked, position, click_time)
    slider.value = initial
    slider.step = step
    slider.active = true
    function slider:increase()
        if self.value < 1 then
            self.value = helper.round(self.value + self.step, 3)
            crease_time(self.value)
        end
    end

    function slider:decrease()
        if self.value > 0 then
            self.value = helper.round(self.value - self.step, 3)
            crease_time(self.value)
        end
    end

    ---draws the button
    function slider:draw()
        drawfunction(self.x, self.y, self.xs, self.ys, self.state, self.value, self.active)
    end

    ---executes the onclicked function
    function slider:click()
        Soundfx.click.sound:play()
        self.state = 'clicked'
        self.clicked_timer = self.click_time
        self.active = not self.active
        onclicked(self.active, self.value)
    end

    function slider:key(key, _)
        if key == 'right' or key == 'l' then
            slider:increase()
        elseif key == 'left' or key == 'h' then
            slider:decrease()
        end
    end

    return slider
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

    function KeyboardNavigator:mousemoved(x, y)
        for k, button in pairs(self.items) do
            if button:checkHit(x, y) then
                self.selected = k
            end
        end
    end

    function KeyboardNavigator:update(dt)
        if self.selected ~= Previous_selected then
            Previous_selected = self.selected
            Soundfx.select.sound:play()
        end
        for k, button in pairs(self.items) do
            button:update(dt)
            if button.state ~= 'clicked' then
                if k == self.selected then
                    button.state = 'selected'
                else
                    button.state = 'normal'
                end
            end
        end
    end

    function KeyboardNavigator:key(key, isrepeat)
        if (key == 'down' or key == 'j') and not isrepeat then
            self:next()
        elseif (key == 'up' or key == 'k') and not isrepeat then
            self:previous()
        elseif key == 'space' and not isrepeat then
            if #self.items == 0 then
                return nil
            elseif not self.selected then
                self.selected = 1
            end
            local c = self:current()
            c:click()
        end
        if #self.items == 0 then
            return nil
        elseif not self.selected then
            self.selected = 1
        end
        local cur = self:current()
        if cur.key then
            cur:key(key, isrepeat)
        end
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


function ui.createKeyBoardNavigationHorizontal(items)
    ---@class KeyboardNavigatorHorizonontal:KeyboardNavigator
    local navigator = ui.createKeyBoardNavigation(items)
    function navigator:key(key, isrepeat)
        print('in horiziontal')
        if (key == 'left' or key == 'j') and not isrepeat then
            self:next()
        elseif (key == 'right' or key == 'k') and not isrepeat then
            self:previous()
        elseif key == 'space' and not isrepeat then
            if #self.items == 0 then
                return nil
            elseif not self.selected then
                self.selected = 1
            end
            local c = self:current()
            c:click()
        end
        if #self.items == 0 then
            return nil
        elseif not self.selected then
            self.selected = 1
        end
        local cur = self:current()
        if cur.key then
            cur:key(key, isrepeat)
        end
    end
    return navigator
end

return ui
