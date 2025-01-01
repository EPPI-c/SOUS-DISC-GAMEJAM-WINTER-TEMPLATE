local ui = require "helper"
local M = {}

function M:init()
    local draw = function(x, y, xs, ys, state)
        if state == 'selected' then
            love.graphics.setColor(0.3, 0.3, 0.3)
        elseif state == 'clicked' then
            love.graphics.setColor(0, 0, 1)
        else
            love.graphics.setColor(0, 1, 0)
        end
        love.graphics.rectangle('fill', x, y, xs, ys)
    end
    local click = function()
        print('clicked')
    end
    local buttons = {
        ui.createButton(20, 20, 20, 20, draw, click, 0, 0.2),
        ui.createButton(50, 20, 20, 20, draw, click, 0, 0.2),
        ui.createButton(80, 20, 20, 20, draw, click, 0, 0.2),
    }
    Menu = ui.createKeyBoardNavigation(buttons)
end

---for drawing stuff
function M:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 0, 0, 400, 800)
    Menu:draw()
end

---@param dt number seconds since the last time the function was called
---for game logic
function M:update(dt)
    Menu:update(dt)
end

---@param context any feel free to use this however you want
---called when state changed to this state
function M:changedstate(context)
end

---@param f boolean the state if focused or not
---for when game is focused or unfocused
function M:focus(f)
end

---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
function M:mousepressed(x, y, button, istouch, presses)
    local hit, nohit = Menu:checkHit(x, y)
    for _, b in ipairs(hit) do
        b.state = 'clicked'
        b:click()
    end
    for _, b in ipairs(nohit) do
        b.state = 'normal'
    end
end

---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
function M:mousereleased(x, y, button, istouch, presses)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
---Callback function triggered when a keyboard key is released.
function M:keyreleased(key, scancode, isrepeat)
    print(key)
    Menu:keyreleased(key, isrepeat)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
---Callback function triggered when a keyboard key is pressed.
function M:keypressed(key, scancode, isrepeat)
end

return M
