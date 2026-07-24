local love = require "love"
require "util"
require "level"
require "anim"

state = {}
globals = {}

Mode = {
    Gameplay = {},
    Menu = {}
}

function love.load()
    -- state.level = Level.fromGrid([[
    --     .......
    --     PP.....
    --     P.A....
    --     ..B....
    --     .BB....
    --     ]],[[
    --     .......
    --     .......
    --     ..2....
    --     .......
    --     .......
    --     ]])
    globals.levels = {
        {[[
            ......
            ......
            .P....
            ......
            .A....
            .A.BB.
            ...B..
            ......
        ]],[[
            ......
            ......
            .P....
            ......
            .4....
            ......
            ...7..
            ......
        ]],[[
            ......
            ......
            ......
            ......
            .G....
            ......
            ......
            ......
        ]]}
    }

    state.levelIndex = 1
    state.level = Level.fromGrid(globals.levels[state.levelIndex][1],
        globals.levels[state.levelIndex][2], globals.levels[state.levelIndex][3])

    state.mode = Mode.Gameplay

    globals.font = "futura-pt-bold.ttf" -- NOT a placeholder
end

KEYS_PRESSED = {}
REPEAT_START = 0.5
REPEAT_INTERVAL = 0.05
RECENT_KEY = ''

function love.update(dt)
    updateAnimations(dt)

    HAS_MOVED = false
    for key, data in pairs(KEYS_PRESSED) do
        data.time = data.time + dt

        if RECENT_KEY == key and data.time > REPEAT_START then
            data.repeatTime = data.repeatTime + dt
            if data.repeatTime > REPEAT_INTERVAL then
                data.repeatTime = 0
                pressedKey(key)
            end
        end
    end
end

function love.draw()
    -- does this not have deltatime?
    -- japi: yeah it's kinda crazy
    Level.draw(state.level)
    drawAnimations()
end

function love.keypressed(key)
    pressedKey(key)
    RECENT_KEY = key
    KEYS_PRESSED[key] = {
        time = 0,
        repeatTime = 0
    }

    -- animation test
    if key == "t" then
        local highScale = math.min(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
        local anim = Animation.chainLoop(
            Animation.new(3.0, function(self, progress)
                local progress = easeInOutCubic(progress)
                local width = love.graphics.getWidth()
                local height = love.graphics.getHeight()
                local scale = progress * highScale
                love.graphics.push()
                love.graphics.translate(width / 2, height / 2)
                love.graphics.rotate(progress * 8 * 3.14)
                love.graphics.rectangle("fill", -scale / 2, -scale / 2, scale, scale, rotation)
                love.graphics.pop()
            end),
            Animation.new(2.0, function(self, progress)
                local progress = easeInOutCubic(progress)
                local width = love.graphics.getWidth()
                local height = love.graphics.getHeight()
                local scale = (1 - easeInBack(progress)) * highScale
                love.graphics.setColor(1, 1, 1, 1 - easeInBack(progress))
                love.graphics.push()
                love.graphics.translate(width / 2, height / 2)
                love.graphics.rectangle("fill", -scale / 2, -scale / 2, scale, scale, rotation)
                love.graphics.pop()
                love.graphics.setColor(1, 1, 1)
            end)
        )
        Animation.start(anim)
    end
end

function pressedKey(key)
    Level.turn(state.level, key)
end

function love.keyreleased(key)
    KEYS_PRESSED[key] = nil
end
