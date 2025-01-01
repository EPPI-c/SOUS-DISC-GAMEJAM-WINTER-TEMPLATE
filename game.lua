local game = {}

---for drawing stuff
function game:draw()
	love.graphics.rectangle("fill", 0, 0, 400, 400)
end

---@param dt number seconds since the last time the function was called
---for game logic
function game:update(dt)
end

---@param context any feel free to use this however you want
---called when state changed to this state
function game:changedstate(context)
end

---@param f boolean the state if focused or not
---for when game is focused or unfocused
function game:focus(f)
end

---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
function game:mousepressed(x, y, button, istouch, presses)
end

---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
function game:mousereleased(x, y, button, istouch, presses)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---Callback function triggered when a keyboard key is released. 
function game:keyreleased(key, scancode)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
function game:keypressed(key, scancode)
end

return game
