local sm = require("state")
local gameState = require("game")

function love.load()
	sm:changestate(gameState, nil)
end

function love.update(dt)
	sm.state:update(dt)
end

function love.keypressed(key, scancode)
	sm.state:keypressed(key, scancode)
end

function love.keyreleased(key, scancode)
	sm.state:keypressed(key, scancode)
end

function love.mousepressed(x, y, button, istouch, presses)
	sm.state:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	sm.state:mousereleased(x, y, button, istouch, presses)
end

function love.draw()
	sm.state:draw()
end

function love.focus(f)
	sm.state:focus(f)
end

function love.resize(w, he)
	ScreenAreaWidth = w
	ScreenAreaHeight = he
end
