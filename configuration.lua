local helper = require 'helper'
local ui = require 'ui'

local M = {}

function M:init(sm)
    self.sm = sm
    self.backstate = self

    local draw1 = ui.createButtonDraw('BACK', { 1, 1, 1 }, { 0, 1, 0 }, { 0.3, 0.3, 0.3 }, { 0, 1, 0 })
    local positions = helper.center_coords(helper.create_coord(0, 0),
        helper.create_coord(ScreenAreaWidth, ScreenAreaHeight), 4, false)
    local w = 100
    local h = 40

    local drawslider1 = ui.createSliderDraw('GENERAL VOLUME', { 1, 1, 1 }, { 0.3, 0.3, 0.3 }, { 0.3, 0.3, 0.3 },
        { 0.2, 0.2, 0.2 }, { 0, 1, 0, 0.5 })
    local sliderw = 300
    local sliderh = 30

    local drawslider2 = ui.createSliderDraw('MUSIC VOLUME', { 1, 1, 1 }, { 0.3, 0.3, 0.3 }, { 0.3, 0.3, 0.3 },
        { 0.2, 0.2, 0.2 }, { 0, 1, 0, 0.5 })

    local drawslider3 = ui.createSliderDraw('EFFECTS VOLUME', { 1, 1, 1 }, { 0.3, 0.3, 0.3 }, { 0.3, 0.3, 0.3 },
        { 0.2, 0.2, 0.2 }, { 0, 1, 0, 0.5 })

    local drawCrease1 = function(value)
        Volumes.generalVolume = value
        ChangeVolume()
    end
    local drawCrease2 = function(value)
        Volumes.musicVolume = value
        ChangeVolume()
    end
    local drawCrease3 = function(value)
        Volumes.soundfxVolume = value
        ChangeVolume()
    end

    local buttons = {
        ui.createSlider(positions[1].x - sliderw / 2, positions[1].y - sliderh / 2, sliderw, sliderh, drawslider1,
            function(active, value)
                if not active then
                    Volumes.generalVolume = 0
                else
                    Volumes.generalVolume = value
                end
                ChangeVolume()
            end, drawCrease1, 1, 0.2,0.1,1),
        ui.createSlider(positions[2].x - sliderw / 2, positions[2].y - sliderh / 2, sliderw, sliderh, drawslider2,
            function(active, value)
                if not active then
                    Volumes.musicVolume = 0
                else
                    Volumes.musicVolume = value
                end
                ChangeVolume()
            end, drawCrease2, 2, 0.2,0.1,1),
        ui.createSlider(positions[3].x - sliderw / 2, positions[3].y - sliderh / 2, sliderw, sliderh, drawslider3,
            function(active, value)
                if not active then
                    Volumes.soundfxVolume = 0
                else
                    Volumes.soundfxVolume = value
                end
                ChangeVolume()
            end, drawCrease3, 3, 0.2,0.1,1),
        ui.createButton(positions[4].x - w / 2, positions[4].y - h / 2, w, h, draw1, function()
            self.sm:changestate(self.backstate, nil)
        end, 4, 0.2),
    }
    self.menu = ui.createKeyBoardNavigation(buttons)
    self.menu.selected = 4
end

function M:changedstate(ctx)
    self.backstate = ctx
end

function M:draw()
    self.menu:draw()
end

function M:update(dt)
    self.menu:update(dt)
end

function M:keypressed(key, _, isrepeat)
    self.menu:key(key, isrepeat)
end

function M:mousepressed(x, y, _, _, _)
    local hit, nohit = self.menu:checkHit(x, y)
    for _, b in ipairs(hit) do
        b.state = 'clicked'
        b:click()
    end
    for _, b in ipairs(nohit) do
        b.state = 'normal'
    end
end

function M:mousemoved(x, y, _, _, _)
    self.menu:mousemoved(x, y)
end

return M
