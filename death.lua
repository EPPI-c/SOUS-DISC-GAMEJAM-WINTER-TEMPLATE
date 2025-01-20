local ui = require 'ui'
local M = {}

local text = {
    "HAHAHA YOU DIED",
    "DO I HAVE TO INSULT YOU AGAIN?",
    "Are you reading My messages?",
    "Please say you're reading my messages!",
    "Oh I can't hear you, Well I'll have to assume you're reading them to continue this conversation",
    "What? you thought these messages were randomized like Minecraft?",
    "No, no, every time you die I have to come up with a new sequential piece of text. So please read them otherwise I'll be sad. I'll even give advice instead of insulting you.",
    "This game has no path finding, because the devs are lazy. Maybe you can use that to your advantage?",
    "See that was useful advice right, yet you still died.",
    "Is this getting repetitive? you have died ",
    "Well maybe the real game is our conversation! You win if you reach the end of these messages, I win if you give up on this game.",
    "OOPS have to give some advice otherwise the devs get mad. The purple bullets take half of your health so you better avoid them. Actually avoid all bullets.",
    "VIM key bindings btw you can change navigate the menus with j and k",
    "You know you can pause with the escape key?",
    "In case you never went to the menu there are stats there check them out!",
    "You know you should never push both buttons on an elevator that has one button to go up and another to go down, those elevators are smart so don't  be dumb!",
    "Did you know Bullets are worse at turning than humans? Maybe that can be useful.",
    "You shouldn't feel bad for killing all those innocent people. You're doing it for your own survival!",
    "And those people are clearly JAY WALKING that's a crime (well at least in the USA), you're basically a hero!",
    "The real Hero (the one shooting bullets at you) gets angrier the more people you kill, try killing 10 people and see how mad she gets.",
    "Isn't it weird how the JAY WALKERS can sense you even though they are turned with their backs against you? LAZY DEVS!",
    "Did you know you have plot armor? And even with it you keep dying!",
    "About the plot armor basically if your health is low the chance of there being a JAY WALKER increases, but only in uncharted territories!",
    "Why is there a SEED in the bottom left? Maybe the devs thought about letting you rerun a map but in the end they were LAZY again and didn't implement the rest of it",
    "Dead ends really are deadly aren't they?",
    "Is the music starting to bother you? You can NOW mute it in the configurations",
    "Did I get my last message right or did you die to something else like a bullet that time? The devs are LAZY so I can't tell if you died because of a dead end.",
    "Does the miss aligned text bother you? I bet it does but the devs were LAZY! So you'll have to live with it.",
    "Seems like the devs are getting tired of writing.",
    "Just a couple more deaths and you win the game.",
    "Ok you reached the end congratulations you win!. What? I said \"a couple more\" so you expected like at least 3? Must I really remind you? THE DEVS ARE LAZY!",
    "Hey why are you still playing this? You thought there wouldn't be any other messages? Well you're right this one is really the last one! From here on I'll stay quite from now on",
}

function M:init(stateMachine, gameState, menuState)
    self.sm = stateMachine
    self.gameState = gameState
    self.menuState = menuState
    self.deathmessages = text

    local start = ui.createButtonDraw('restart', { 1, 1, 1 }, { 0, 0.7, 0 }, { 0.3, 0.3, 0.3 }, { 0, 0.7, 0 })
    local menu = ui.createButtonDraw('menu', { 1, 1, 1 }, { 0, 0.7, 0 }, { 0.3, 0.3, 0.3 }, { 0, 0.7, 0 })
    local start_func = function()
        self.sm:changestate(self.gameState, nil)
    end
    local menu_func = function()
        self.sm:changestate(self.menuState, nil)
    end
    local buttonwidth = 100
    local offset = ScreenAreaWidth / 4
    local button1x = offset - buttonwidth
    local button2x = 3 * offset - buttonwidth
    local buttons = {
        ui.createButton(button1x, ScreenAreaHeight - 100, buttonwidth, 50, start,
            start_func, 1, 0.2),
        ui.createButton(button2x, ScreenAreaHeight - 100, buttonwidth, 50, menu,
            menu_func, 1, 0.2),
    }
    self.menu = ui.createKeyBoardNavigation(buttons)
    self.menu.selected = 1
end

function M:update(dt)
    self.menu:update(dt)
end

function M:changedstate(seed)
    Seed = seed
    local musicPos = Music.music.sound:tell()
    Music.music.sound:stop()
    Music.reverbmusic.sound:seek(musicPos)
    Music.reverbmusic.sound:setLooping(true)
    Music.reverbmusic.sound:play()
    Index = Stats.sum.deathmessageindex + 1
    Suicide = false
    Over = false
    if Index > 11 and GameStats.game.secondsalive < 10 then
        Suicide = true
    else
        if Index > #self.deathmessages then
            Over = true
        else
            Stats.sum.deathmessageindex = Stats.sum.deathmessageindex + 1
        end
    end
end

function M:draw()
    self.gameState:draw()
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, ScreenAreaWidth, ScreenAreaHeight)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Seed: " .. tostring(Seed), 5, ScreenAreaHeight - 20)
    self.menu:draw()
    if not Over then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(50))
        if Suicide then
            love.graphics.printf(
                'No, you can\'t kill yourself to game the system. You need to properly play the game for your death to count!',
                0,
                50, ScreenAreaWidth - 100, 'center')
        else
            if Index == 10 then
                love.graphics.printf(self.deathmessages[Index] .. ' ' .. tostring(Stats.sum.deaths) .. ' times!', 0, 50,
                    ScreenAreaWidth - 100, 'center')
            else
                love.graphics.printf(self.deathmessages[Index], 0, 50, ScreenAreaWidth - 100, 'center')
            end
        end
        love.graphics.setFont(Font)
    end
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
