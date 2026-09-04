local love = require "love"
require "source.data.levels"
require "source.data.locale"

require "source.utils"
require "source.graphics.anim"
require "source.play.level"

require "source.menu"
require "source.editor.interface"
require "source.graphics.palette"

--[[

TODO:
- Fix bug with fullscreen enter also working as entering a level
- Fix particles still appearing on the menu after closing a level
- Make the menu look nicer

]]

DEBUG = {
    AnimationTime = 0.16 -- default: 0.16
}

Mode = {
    Gameplay = {},
    Menu = {},
    Editor = {}
}

state = {
    width = 0,
    height = 0,

    sfxVolume = 0.5,
    musicVolume = 0.5,

    levelIndex = 1,
    levelClears = {},

    mode = Mode.Menu
}

globals = {
    font = {},
    levelFont = {},
    tutorialFont = {},

    fontFile = "fonts/intrebol.ttf", -- NOT a placeholder
    levelFontFile = "fonts/Comfortaa-Regular.ttf", -- *REALLY* NOT a placeholder,
    ponaFontFile1 = "fonts/sitelenselikiwenjuniko.ttf", -- toki pona :D
    ponaFontFile2 = "fonts/sitelenselikiwenmonojuniko.ttf", -- toki pona :D

    levels = {},
    entered_level_six = 0,
    tree = love.graphics.newImage("tree.png")
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
    local ponaAltFile = Locale.current == 'toki-pona' and globals.ponaFontFile1 or (Locale.current == 'sitelen-pona' and globals.ponaFontFile2 or nil)
    globals.menuFont = love.graphics.newFont(ponaAltFile or globals.fontFile, math.min(state.width, state.height) * 0.06)
    globals.levelFont = love.graphics.newFont(ponaAltFile or globals.levelFontFile, math.min(state.width, state.height) * 0.067)
    globals.tutorialFont = love.graphics.newFont(ponaAltFile or globals.levelFontFile, math.min(state.width, state.height) * 0.05)
    -- globals.titleFont = love.graphics.newFont(globals.fontFile, state.cellSize * 0.5)

    if state.mode == Mode.Gameplay then
        Level.onResize(state.level)
    elseif state.mode == Mode.Menu then
        Menu.onResize(state.menu)
    end
end

function love.load()
    Locale.loadMappings()
    Levels.loadData()
    -- state.level = Level.fromData(globals.levels[state.levelIndex])

    local menuLevelSize = 0.1
    state.menu = Menu.new(1, 1, {
        {
            x = 0.5 - menuLevelSize * 1.5,
            y = menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 1,
        },
        {
            x = 0.5,
            y = menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 2,
        },
        {
            x = 0.5 + menuLevelSize * 1.5,
            y = menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 3,
        },
        {
            x = 0.5 - menuLevelSize * 1.5,
            y = menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 4,
        },
        {
            x = 0.5,
            y = menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 5,
        },
        {
            x = 0.5 + menuLevelSize * 1.5,
            y = menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 6,
        },
        {
            x = 0.5 - menuLevelSize * 1.5,
            y = 0.5 - menuLevelSize * 0.7,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 7,
        },
        {
            x = 0.5,
            y = 0.5 - menuLevelSize * 0.7,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 8,
        },
        {
            x = 0.5 + menuLevelSize * 1.5,
            y = 0.5 - menuLevelSize * 0.7,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 9,
        },
        {
            x = 0.5,
            y = 0.5 + menuLevelSize * 0.7,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 10,
        },
        {
            x = 0.5 - menuLevelSize * 0.75,
            y = 1 - menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 11,
        },
        {
            x = 0.5 + menuLevelSize * 0.75,
            y = 1 - menuLevelSize * 2.4,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 12,
        },
        {
            x = 0.5 - menuLevelSize * 1.5,
            y = 1 - menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 13,
        },
        {
            x = 0.5,
            y = 1 - menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 14,
        },
        {
            x = 0.5 + menuLevelSize * 1.5,
            y = 1 - menuLevelSize,
            w = menuLevelSize,
            h = menuLevelSize,
            levelIndex = 15,
        },
    },{
        {
            x = 1/7 - Menu.scrollBarWidth / 2,
            y = 3/5,
            h = 0.3,
            value = state.sfxVolume,
            connect = function(value)
                if (state.sfxVolume ~= value) then
                    state.sfxVolume = value
                    Sounds.move:play()
                end
            end,
            label = Locale.localizeText("menu.volume.sfx")
        },
        {
            x = 6/7 - Menu.scrollBarWidth / 2,
            y = 3/5,
            h = 0.3,
            value = state.musicVolume,
            connect = function(value)
                if (state.musicVolume ~= value) then
                    state.musicVolume = value
                    Sounds.move:play(true)
                end
            end,
            label = Locale.localizeText("menu.volume.music")
        }
    })

    globals.challengeLevels = { 11, 12, 13, 14, 15 }

    state.mode = Mode.Menu
    state.musicVolume = 0.5
    state.fullscreen = false

    updateGraphics()

    local iconImageData = {}
    local iconAnimCount = 12
    -- local iconAnims = {}
    for i=1,iconAnimCount do
        local imageData = love.image.newImageData("icons/square" .. tostring(i) .. ".png")
        table.insert(iconImageData, imageData)

        -- local anim = Animation.new(1 / iconAnimCount, nil, function()
        --     love.window.setIcon(iconImageData[i])
        -- end)
        -- table.insert(iconAnims, anim)
    end
    -- local iconAnimation = Animation.chainArrayLoop(iconAnims)
    -- Animation.start(iconAnimation)
    love.window.setIcon(iconImageData[7])

    globals.mouseCursors = {
        ["hand"] = love.mouse.getSystemCursor("hand"),
        ["arrow"] = love.mouse.getSystemCursor("arrow"),
    }

    Music.play(Music.menu)
    state.interface = Interface.new()
end

KEYS_PRESSED = {}
REPEAT_START = 0.5
REPEAT_INTERVAL = 0.05

local pressTime = 0
local repeatTime = 0

function love.update(dt)
    Animation.update(dt)
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
    elseif state.mode == Mode.Editor then
        Interface.update(state.interface, dt)
    end

    Music.update(dt)

end

function love.draw()
    -- does this not have deltatime?
    -- japi: yeah it's kinda crazy
    if state.mode == Mode.Gameplay then
        Level.draw(state.level)
    elseif state.mode == Mode.Menu then
        Menu.draw(state.menu)
    elseif state.mode == Mode.Editor then
        Interface.draw(state.interface)
    end
    Animation.draw()
end

function love.keypressed(key)
    pressedKey(key)
    keyClear(key, 0)
    KEYS_PRESSED[#KEYS_PRESSED+1] = key

    if (key == "return" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")))
       or key == "f11" then
       state.fullscreen = not state.fullscreen
       love.window.setFullscreen(state.fullscreen)
    elseif key == "e" then
        state.mode = Mode.Editor
        state.musicVolume = 0.0
    end
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

function love.wheelmoved(x, y)
    if state.mode == Mode.Editor then
        Interface.wheelmoved(state.interface, x, y)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if state.mode == Mode.Editor then
        Interface.mousemoved(state.interface, x, y, dx, dy, istouch)
    end
end
