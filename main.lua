local sm = require("state")
local gameState = require("game")
local menuState = require("menu")

function love.load()
    menuState:init()
    sm:changestate(menuState, nil)
	ScreenAreaWidth = love.graphics.getWidth()
	ScreenAreaHeight = love.graphics.getHeight()
end

function love.update(dt)
	sm.state:update(dt)
end

function love.keypressed(key, scancode, isrepeat)
	sm.state:keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode, isrepeat)
	sm.state:keypressed(key, scancode, isrepeat)
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
