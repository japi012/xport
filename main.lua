local love = require "love"
require "util"
require "level"

local Menu = require "menu"
local Animation = require "anim"

DEBUG = {
    AnimationTime = 0.16 -- default: 0.16
}

Mode = {
    Gameplay = {},
    Menu = {}
}

state = {
    width = 0,
    height = 0,

    mode = Mode.Menu,
    cellSize = 0
}

globals = {
    font = {},
    fontFile = "futura-pt-bold.ttf" -- NOT a placeholder,
}

local lastWidth = 0
local lastHeight = 0

function updateGraphics()
    lastWidth = state.width
    lastHeight = state.height
    state.width = love.graphics.getWidth()
    state.height = love.graphics.getHeight()

    if lastWidth ~= state.width or lastHeight ~= state.height then
        state.cellSize = math.min(state.width / state.level.width, state.height / state.level.height) * 0.5
        globals.font = love.graphics.newFont(globals.fontFile, state.cellSize * 0.9)
        -- globals.titleFont = love.graphics.newFont(globals.fontFile, state.cellSize * 0.5)

        if state.mode == Mode.Gameplay then
            Level.onResize(state.level)
        elseif state.mode == Mode.Menu then
            Menu.onResize(state.menu)
        end
    end
end

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
        {
          [[
          ........
          .PA.....
          ........
          ]],
          [[
          ........
          ........
          ........
          ]],
          [[
          ........
          ......G.
          ........
          ]],
        },
        {
          [[
          .........
          .PA......
          ..B..#...
          .........
          ]],
          [[
          .........
          .........
          .........
          .........
          ]],
          [[
          .........
          ......G..
          ......G..
          .........
          ]],
        },
        {
          [[
          .P.....
          .......
          .......
          .A.BB..
          .A..B..
          .......
          ]],
          [[
          .P.....
          .......
          .......
          .7..5..
          .......
          .......
          ]],
          [[
          .P.....
          .......
          .......
          ......G
          .......
          ......G
          ]],
        }
    }

    state.levelIndex = 1
    state.level = Level.fromGrid(globals.levels[state.levelIndex])
    state.levelClears = {}

    state.menu = Menu.new(500, {
        {
            x = 30,
            y = 30,
            w = 50,
            h = 50,
            levelIndex = 1,
        },{
            x = 120,
            y = 30,
            w = 50,
            h = 50,
            levelIndex = 2,
        },{
            x = 210,
            y = 30,
            w = 50,
            h = 50,
            levelIndex = 3,
        }
    }, {
        {
            x = 450,
            y = 300,
            h = 100,
            value = 0,
            connect = function(value)
                print(value)
            end
        }
    }, true)

    state.mode = Mode.Menu
    state.musicVolume = 0.5

    updateGraphics()

    local iconImageData = {}
    local iconAnimCount = 12
    local iconAnims = {}
    for i=1,iconAnimCount do
        local imageData = love.image.newImageData("icons/square" .. tostring(i) .. ".png")
        table.insert(iconImageData, imageData)

        local anim = Animation.new(1 / iconAnimCount, nil, function()
            love.window.setIcon(iconImageData[i])
        end)
        table.insert(iconAnims, anim)
    end
    local iconAnimation = Animation.chainArrayLoop(iconAnims)
    Animation.start(iconAnimation)

    globals.mouseCursors = {
        ["hand"] = love.mouse.getSystemCursor("hand"),
        ["arrow"] = love.mouse.getSystemCursor("arrow"),
    }
end

KEYS_PRESSED = {}
REPEAT_START = 0.5
REPEAT_INTERVAL = 0.05
RECENT_KEY = ''

function love.update(dt)
    updateAnimations(dt)
    updateGraphics()

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

    if state.mode == Mode.Gameplay then
        Level.update(state.level, dt)
    elseif state.mode == Mode.Menu then
        Menu.update(state.menu, dt)
    end
end

function love.draw()
    -- does this not have deltatime?
    -- japi: yeah it's kinda crazy
    if state.mode == Mode.Gameplay then
        Level.draw(state.level)
    elseif state.mode == Mode.Menu then
        Menu.draw(state.menu, dt)
    end
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
        local anim = Animation.chained(
            Animation.new(3.0, function(self, progress)
                local highScale = math.min(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
                local progress = easeInOutCubic(progress)
                local width = love.graphics.getWidth()
                local height = love.graphics.getHeight()
                local scale = progress * highScale
                love.graphics.push()
                love.graphics.translate(width / 2, height / 2)
                love.graphics.rotate(progress * 8 * math.pi)
                love.graphics.rectangle("fill", -scale / 2, -scale / 2, scale, scale)
                love.graphics.pop()
            end),
            Animation.new(2.0, function(self, progress)
                local highScale = math.min(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
                local progress = easeInOutCubic(progress)
                local width = love.graphics.getWidth()
                local height = love.graphics.getHeight()
                local scale = (1 - easeInBack(progress)) * highScale
                love.graphics.setColor(1, 1, 1, 1 - easeInBack(progress))
                love.graphics.push()
                love.graphics.translate(width / 2, height / 2)
                love.graphics.rectangle("fill", -scale / 2, -scale / 2, scale, scale)
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
