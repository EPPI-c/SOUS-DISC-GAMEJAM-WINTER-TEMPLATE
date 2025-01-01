local ui = require "helper"
local M = {}

function M:init(sm, Game_state)
	local start = ui.createButtonDraw('start', { 1, 1, 1 }, { 0, 0.7, 0 }, { 0.3, 0.3, 0.3 }, { 0, 0, 0.7 })
	local exit = ui.createButtonDraw('exit', { 1, 1, 1 }, { 0.7, 0, 0 }, { 0.3, 0.3, 0.3 }, { 0, 0, 0.7 })
	local start_func = function()
	    sm:changestate(Game_state, nil)
	end
	local buttons = {
		ui.createButton(20, 20, 50, 20, start, start_func, 1, 0.2),
		ui.createButton(20, 50, 50, 20, exit, love.event.quit, 2, 0.2),
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

---@param x number The mouse position on the x-axis.
---@param y number The mouse position on the y-axis.
---@param dx number  The amount moved along the x-axis since the last time love.mousemoved was called.
---@param dy number  The amount moved along the y-axis since the last time love.mousemoved was called.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
function M:mousemoved(x, y, dx, dy, istouch)
    Menu:mousemoved(x, y)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
---Callback function triggered when a keyboard key is released.
function M:keyreleased(key, scancode, isrepeat)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
---Callback function triggered when a keyboard key is pressed.
function M:keypressed(key, scancode, isrepeat)
	Menu:key(key, isrepeat)
end

return M
