local game = {}

function game:init(sm, menu)
	Map = love.graphics.newImage('map.jpeg')
	MapW, MapH = Map:getDimensions()
	StateMachine = sm
	MenuState = menu
	Playerx = 0
	Playery = 0
	Enemypos = {x=100, y=100}
	Speed = 250
	Dash = { '', 0 }
	Dashdelta = 200
end

---for drawing stuff
function game:draw()
	love.graphics.draw(Map, -MapW / 2 + ScreenAreaWidth / 2 - Playerx, -MapH / 2 + ScreenAreaHeight / 2 - Playery)
	love.graphics.setColor(1, .3, .3)
	love.graphics.rectangle("fill", Enemypos.x + ScreenAreaWidth / 2 - 10 - Playerx, Enemypos.y + ScreenAreaHeight / 2 - 10 - Playery, 20, 20)
	love.graphics.setColor(1, 1, 1)
	love.graphics.rectangle("fill", ScreenAreaWidth / 2 - 10, ScreenAreaHeight / 2 - 10, 20, 20)
end

---@param dt number seconds since the last time the function was called
---for game logic
function game:update(dt)
	if love.keyboard.isDown('w') then
		Playery = Playery - dt * Speed
	end
	if love.keyboard.isDown('s') then
		Playery = Playery + dt * Speed
	end
	if love.keyboard.isDown('d') then
		Playerx = Playerx + dt * Speed
	end
	if love.keyboard.isDown('a') then
		Playerx = Playerx - dt * Speed
	end
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
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
function game:keypressed(key, scancode, isrepeat)
	if key == Dash[1] and love.timer.getTime() - Dash[2] < 0.25 and not isrepeat then
		if key == 'w' then
			Playery = Playery - Dashdelta
		elseif key == 's' then
			Playery = Playery + Dashdelta
		elseif key == 'a' then
			Playerx = Playerx - Dashdelta
		elseif key == 'd' then
			Playerx = Playerx + Dashdelta
		end
	end
	Dash = { key, love.timer.getTime() }
end

---@param x number The mouse position on the x-axis.
---@param y number The mouse position on the y-axis.
---@param dx number  The amount moved along the x-axis since the last time love.mousemoved was called.
---@param dy number  The amount moved along the y-axis since the last time love.mousemoved was called.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
function game:mousemoved(x, y, dx, dy, istouch)
end

return game
