local ui = require "ui"
local M = {}

function M:init(sm, Game_state, configurationState)
    local start = ui.createButtonDraw('START', { 1, 1, 1 }, { 0, 0.7, 0 }, { 0.3, 0.3, 0.3 }, { 0, 0.7, 0 })
    local configuration = ui.createButtonDraw('CONFIG', { 1, 1, 1 }, { 0, 0.7, 0 }, { 0.3, 0.3, 0.3 }, { 0, 0.7, 0 })
    local start_func = function()
        sm:changestate(Game_state, nil)
    end
    local configuration_func = function()
        sm:changestate(configurationState, self)
    end
    local buttons = {
        ui.createButton(ScreenAreaWidth / 4 - 50, ScreenAreaHeight - 100, 100, 40, start, start_func, 1, 0.2),
        ui.createButton(ScreenAreaWidth / 4 - 50, ScreenAreaHeight - 200, 100, 40, configuration, configuration_func, 2, 0.2),
    }
    Menu = ui.createKeyBoardNavigation(buttons)
    Menu.selected = 1
end

function M:draw_stats()
    local stats = {
        {'HIGHSCORE', Stats.high.score},
        {'TOTALSCORE', Stats.high.score},
        {'DODGED', Stats.sum.dodged},
        {'DEATHS', Stats.sum.deaths},
        {'SECONDSALIVE', Stats.sum.secondsalive},
        {'DASHED', Stats.sum.dashed},
        {'SHOT', Stats.sum.shot},
    }
    love.graphics.setColor(1, 1, 1)
    local x = ScreenAreaWidth / 2 + 20
    local offset_y = 50
    if Stats.high.friendlyfire > 0 then
        love.graphics.print("FRIENDLYFIRE: " .. tostring(Stats.sum.friendlyfire), x, offset_y)
    end
    for k, v in pairs(stats) do
        love.graphics.print(v[1] .. ': ' .. tostring(v[2]), x, offset_y * (k + 1))
    end
end

---for drawing stuff
function M:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 0, 0, 400, 800)
    M:draw_stats()
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
    Seed = context
    if Music.music.sound:isPlaying() then
        local musicPos = Music.music.sound:tell()
        Music.music.sound:stop()
        Music.reverbmusic.sound:seek(musicPos)
        Music.reverbmusic.sound:setLooping(true)
        Music.reverbmusic.sound:play()
    end
end

---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
---@diagnostic disable-next-line: unused-local
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

---@param x number The mouse position on the x-axis.
---@param y number The mouse position on the y-axis.
---@param dx number  The amount moved along the x-axis since the last time love.mousemoved was called.
---@param dy number  The amount moved along the y-axis since the last time love.mousemoved was called.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@diagnostic disable-next-line: unused-local
function M:mousemoved(x, y, dx, dy, istouch)
    Menu:mousemoved(x, y)
end

---@param key string Character of the released key.
---@param scancode string The scancode representing the released key.
---@param isrepeat boolean Whether this keypress event is a repeat. The delay between key repeats depends on the user's system settings.
---Callback function triggered when a keyboard key is pressed.
---@diagnostic disable-next-line: unused-local
function M:keypressed(key, scancode, isrepeat)
    Menu:key(key, isrepeat)
end

return M
