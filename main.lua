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

    sfxVolume = 0.5;
    musicVolume = 0.5;

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
        forceUpdateGraphics()
    end
end

function forceUpdateGraphics()
    state.cellSize = math.min(state.width / state.level.width, state.height / state.level.height) * 0.5
    globals.font = love.graphics.newFont(globals.fontFile, state.cellSize * 0.9)
    -- globals.titleFont = love.graphics.newFont(globals.fontFile, state.cellSize * 0.5)

    if state.mode == Mode.Gameplay then
        Level.onResize(state.level)
    elseif state.mode == Mode.Menu then
        Menu.onResize(state.menu)
    end
end

function love.load()
    globals.levels = {
        {
          [[
          #######
          #.....#
          #..AC.#
          ##..E.#
          #.P...#
          #..#..#
          #######
          ]],
          [[
          #######
          #.....#
          #...1.#
          ##....#
          #.....#
          #..#..#
          #######
          ]],
          [[
          #######
          #.....#
          #.....#
          ##....#
          #.....#
          #G.#..#
          #######
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
        },
        {
          [[
          #############
          #...####....#
          #.P..ACF....#
          #....####...#
          #############
          ]],
          [[
          #############
          #...####....#
          #....125....#
          #....####...#
          #############
          ]],
          [[
          #############
          #...####...G#
          #.P.........#
          #....####..G#
          #############
          ]],
        }
    }

    state.levelIndex = 1
    state.level = Level.fromGrid(globals.levels[state.levelIndex])
    state.levelClears = {}

    state.menu = Menu.new(750, 500, 100, 100, {
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
            x = 100,
            y = 100,
            w = 50,
            h = 50,
            levelIndex = 3,
        },{
            x = 200,
            y = 100,
            w = 50,
            h = 50,
            levelIndex = 4,
        }
    }, {
        {
            x = 400,
            y = 300,
            h = 150,
            value = state.sfxVolume,
            connect = function(value)
                state.sfxVolume = value
            end
        },
        {
            x = 450,
            y = 300,
            h = 150,
            value = state.musicVolume,
            connect = function(value)
                state.musicVolume = value
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

local pressTime = 0
local repeatTime = 0

function love.update(dt)
    updateAnimations(dt)
    updateGraphics()

    local currentKey = KEYS_PRESSED[#KEYS_PRESSED]
    if currentKey ~= nil then
        pressTime = pressTime + dt

        if pressTime > REPEAT_START then
            repeatTime = repeatTime + dt
            if repeatTime > REPEAT_INTERVAL then
                repeatTime = 0
                pressedKey(currentKey)
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
    keyClear(key, 0)
    KEYS_PRESSED[#KEYS_PRESSED+1] = key
end

function pressedKey(key)
    if state.mode == Mode.Gameplay then
        Level.turn(state.level, key)
    elseif state.mode == Mode.Menu then
        Menu.keypressed(state.menu, key)
    end
end

function love.keyreleased(key)
    keyClear(key, (#KEYS_PRESSED > 0) and (REPEAT_START * 0.5) or 0)
end

function keyClear(key, time)
    pressTime = time
    repeatTime = 0
    local index = indexOf(KEYS_PRESSED, key)
    table.remove(KEYS_PRESSED, index)
end
