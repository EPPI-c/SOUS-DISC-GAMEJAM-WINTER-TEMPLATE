local ui = require 'ui'
local helper = require 'helper'
local M = {}

function M:init(stateMachine, gameState, menuState, configuration)
    self.sm = stateMachine
    self.gameState = gameState
    self.menuState = menuState
    self.configuration = configuration
    local start = ui.createButtonDraw('continue', { 1, 1, 1 }, { 0, 0.7, 0 }, { 0.3, 0.3, 0.3 }, { 0, 0.7, 0 })
    local menu = ui.createButtonDraw('menu', { 1, 1, 1 }, { 0, 0.7, 0 }, { 0.3, 0.3, 0.3 }, { 0, 0.7, 0 })
    local config = ui.createButtonDraw('configuration', { 1, 1, 1 }, { 0, 0.7, 0 }, { 0.3, 0.3, 0.3 }, { 0, 0.7, 0 })
    local start_func = function()
        self.sm:changestate(self.gameState, true)
    end
    local menu_func = function()
        self.sm:changestate(self.menuState, nil)
    end
    local config_func = function()
        self.sm:changestate(self.configuration, self)
    end
    local positions = helper.center_coords(helper.create_coord(0, 0),
        helper.create_coord(ScreenAreaWidth, ScreenAreaHeight), 3, false)
    local buttonwidth = 100
    local buttonheight = 50
    local halfheight = buttonheight / 2
    local halfbutton = buttonwidth / 2
    local buttons = {
        ui.createButton(positions[1].x - halfbutton, positions[1].y - halfheight, buttonwidth, buttonheight, start, start_func, 1, 0.2),
        ui.createButton(positions[2].x - halfbutton, positions[2].y - halfheight, buttonwidth, buttonheight, config, config_func, 2, 0.2),
        ui.createButton(positions[3].x - halfbutton, positions[3].y - halfheight, buttonwidth, buttonheight, menu, menu_func, 3, 0.2),
    }
    self.menu = ui.createKeyBoardNavigation(buttons)
    self.menu.selected = 1
end

function M:update(dt)
    M.menu:update(dt)
end

function M:changedstate(_)
    MusicPos = Music.music.sound:tell()
    Music.music.sound:stop()
    Music.reverbmusic.sound:seek(MusicPos)
    Music.reverbmusic.sound:setLooping(true)
    Music.reverbmusic.sound:play()
end

function M:draw()
    self.gameState:draw()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, ScreenAreaWidth, ScreenAreaHeight)
    self.menu:draw()
end

---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
---@diagnostic disable-next-line: unused-local
function M:mousepressed(x, y, button, istouch, presses)
    local hit, nohit = self.menu:checkHit(x, y)
    for _, b in ipairs(hit) do
        b.state = 'clicked'
        b:click()
    end
    for _, b in ipairs(nohit) do
        b.state = 'normal'
    end
end

---@param x number The mouse position on the x-axis.
---@param y number The mouse position on the y-axis.
---@param dx number  The amount moved along the x-axis since the last time love.mousemoved was called.
---@param dy number  The amount moved along the y-axis since the last time love.mousemoved was called.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@diagnostic disable-next-line: unused-local
function M:mousemoved(x, y, dx, dy, istouch)
    self.menu:mousemoved(x, y)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
---Callback function triggered when a keyboard key is pressed.
---@diagnostic disable-next-line: unused-local
function M:keypressed(key, scancode, isrepeat)
    self.menu:key(key, isrepeat)
end

return M
