local love = require "love"
require "util"
require "level"

local Menu = require "menu"
local Animation = require "anim"

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
    levelFont = {},
    tutorialFont = {},

    fontFile = "fonts/intrebol.ttf", -- NOT a placeholder
    levelFontFile = "fonts/Comfortaa-Regular.ttf", -- *REALLY* NOT a placeholder,

    entered_level_six = 0,
    tree = love.graphics.newImage("tree.png"),
    man = {
        [[
        #########
        ##.....##
        #.......#
        #..AT...#
        #.......#
        ##.....##
        ###...###
        ###...###
        ###.P.###
        ###...###
        ]],
        [[
        #########
        ##.....##
        #.......#
        #..0....#
        #.......#
        ##.....##
        ###...###
        ###...###
        ###...###
        ###...###
        ]],
        [[
        #########
        ##.....##
        #.......#
        #....G..#
        #.......#
        ##.....##
        ###...###
        ###...###
        ###...###
        ###...###
        ]],
        "",
        "There is a man here."
    }
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
    state.cellSize = math.min(state.width / state.level.width, state.height / state.level.height) * 0.65
    globals.font = love.graphics.newFont(globals.fontFile, state.cellSize * 0.9)
    globals.menuFont = love.graphics.newFont(globals.fontFile, math.min(state.width, state.height) * 0.06)
    globals.levelFont = love.graphics.newFont(globals.levelFontFile, math.min(state.width, state.height) * 0.067)
    globals.tutorialFont = love.graphics.newFont(globals.levelFontFile, math.min(state.width, state.height) * 0.05)
    -- globals.titleFont = love.graphics.newFont(globals.fontFile, state.cellSize * 0.5)

    if state.mode == Mode.Gameplay then
        Level.onResize(state.level)
    elseif state.mode == Mode.Menu then
        Menu.onResize(state.menu)
    end
end

function love.load()
    local firstPalette = Palette.defaultList()
    local secondPalette = Palette.list({
        [Cell.Wall] = col255(54, 63, 105),
        [Cell.Box] = Palette.gradientHSV(col255(95, 50, 225), col255(43, 6, 100), 6),
        [Cell.Origin] = {
            default = Palette.gradientHSV(col255(110, 90, 255), col255(87, 45, 200), 6),
            player = col(1, 1, 1)
        },
        background = col255(13, 13, 26),
        levelFill = col255(25, 25, 45),
        levelStroke = col255(0, 0, 255),
    })
    local challengePalette = Palette.list({
        [Cell.Wall] = col255(147, 35, 30),
        [Cell.Box] = Palette.gradientHSV(col255(230, 17, 47), col255(153, 6, 20), 6),
        [Cell.Origin] = {
            default = Palette.gradientHSV(col255(130, 27, 51), col255(70, 7, 20), 6),
            player = col(1, 1, 1)
        },
        background = col255(29, 1, 6),
        levelFill = col255(51, 3, 8),
        levelStroke = col255(255, 0, 0),
    })
    local secretPalette = Palette.list({
        [Cell.Wall] = col(0, 0, 0),
        background = col(0, 0, 0),
        levelFill = col255(59, 22, 65),
        levelStroke = col255(0, 0, 0)
    })

    globals.paletteLists = {
        [-6] = secretPalette,
        [1] = firstPalette,
        [2] = firstPalette,
        [3] = firstPalette,
        [4] = firstPalette,
        [5] = firstPalette,
        [6] = firstPalette,
        [7] = secondPalette,
        [8] = secondPalette,
        [9] = secondPalette,
        [10] = secondPalette,
        [11] = challengePalette,
        [12] = challengePalette,
        [13] = challengePalette,
        [14] = challengePalette,
        [15] = challengePalette
    }
    globals.levels = {
        {
            [[
            #########
            #P...####
            #....####
            #...A...#
            #########
            ]],
            [[
            #########
            #....####
            #....####
            #.......#
            #########
            ]],
            [[
            #########
            #....####
            #....####
            #......G#
            #########
            ]],
            "1 - Déjà Vu",
            "Use WASD or the arrow keys to move."
        },{
            [[
            #########
            ######.##
            #.......#
            #.####.##
            #.####A##
            #.....P##
            #......##
            #########
            ]],
            [[
            #########
            ######.##
            #.......#
            #.####.##
            #.####.##
            #......##
            #......##
            #########
            ]],
            [[
            #########
            ######.##
            #......G#
            #.####.##
            #.####.##
            #......##
            #......##
            #########
            ]],
            "2 - Sokoban",
            "Use Z to undo and R to reset."
        },{
            [[
            #################
            #..P..###.......#
            #...#####.......#
            #...##..........#
            #...............#
            #.AA...#####....#
            #.A....###......#
            #################
            ]],
            [[
            #################
            #.....###.......#
            #...#####.......#
            #...##..........#
            #...............#
            #......#####....#
            #......###......#
            #################
            ]],
            [[
            #################
            #.....###.......#
            #...#####.....G.#
            #...##.......G..#
            #...............#
            #......#####....#
            #......###......#
            #################
            ]],
            "3 - Joined Together",
            "Multiblocks can move as one unit."
        },{
            [[
            ########
			####..##
			#.PA..##
			#####.##
			#......#
			#......#
			########
            ]],
            [[
            ########
			####..##
			#..9..##
			#####.##
			#......#
			#......#
			########
            ]],
            [[
            ########
			####..##
			#G....##
			#####.##
			#......#
			#......#
			########
            ]],
            "4 - Welcome to XPORT",
            "Exhaust the timer!",
            "o lili e ilo tenpo!"
        },{
            [[
            #########
            #.P....##
            #....A.##
            #....A.##
            #...#####
            #.B.....#
            #########
            ]],
            [[
            #########
            #......##
            #......##
            #......##
            #...#####
            #.5.....#
            #########
            ]],
            [[
            #########
            #......##
            #......##
            #......##
            #...#####
            #......G#
            #########
            ]],
            "5 - Point of No Return",
            "Press ESCAPE or BACKSPACE to exit level."
        },{
            [[
            ########
            ####...#
            ######.#
			####...#
			#####..#
            #PABC..#
            ###....#
			########
            ]],
            [[
            ########
            ####...#
            ######.#
			####...#
			#####..#
            #...2..#
            ###....#
			########
            ]],
            [[
            ########
            ####G..#
            ######.#
			####...#
			#####..#
            #......#
            ###....#
			########
            ]],
            "6 - Origin Shift",
            "There is a room in between."
        },{
            [[
            #######
			#.....#
            #.ABC.#
            #..P..#
            #.....#
			##.#.##
            #######
            ]],
            [[
            #######
			#.....#
            #.1.1.#
            #.....#
            #.....#
			##.#.##
            #######
            ]],
            [[
            #######
			#.....#
            #.....#
            #.....#
            #.....#
			##G#G##
            #######
            ]],
            "7 - Nailing It",
        },{
            [[
            ###############
            ##...........##
			#.............#
            #.....APB.....#
            #.............#
			##...........##
            ###############
            ]],
            [[
            ###############
            ##...........##
			#.............#
            #.....4P4.....#
            #.............#
			##...........##
            ###############
            ]],
            [[
            ###############
            ##...........##
			#.............#
            #.G....P....G.#
            #.............#
			##...........##
            ###############
            ]],
            "8 - A Bit of a Stretch",
        },{
            [[
            #########
            #.....###
            #.A....##
            ##B.P..##
			##......#
			###.....#
            #########
            ]],
            [[
            #########
            #.....###
            #.2....##
            ##2....##
			##......#
			###.....#
            #########
            ]],
            [[
            #########
            #.....###
            #......##
            ##....G##
			##....G.#
			###.....#
            #########
            ]],
            "9 - Twins",
        },{
            [[
            ###########
            #.........#
            #...APB...#
            #.........#
			##C#D#E#F##
			##.#.#.#.##
            ###########
            ]],
            [[
            ###########
            #.........#
            #.....4...#
            #.........#
			##1#1#1#1##
			##.#.#.#.##
            ###########
            ]],
            [[
            ###########
            #.........#
            #.........#
            #.........#
			##.#.#.#.##
			##G#G#G#G##
            ###########
            ]],
            "10 - Screwing It",
        },{
            [[
            #######
			#.....#
            #..P..#
            #.....#
            #.B.A.#
			###.###
            #######
            ]],
            [[
            #######
			#.....#
            #.....#
            #.....#
            #.3.3.#
			###.###
            #######
            ]],
            [[
            #######
			#.....#
            #.G.G.#
            #.....#
            #.....#
			###.###
            #######
            ]],
            "C1 - RE: House Flipper",
        },{
            [[
            #######
            #.....#
            #..CA.#
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
            "C2 - Loaded",
        },{
            [[
            ###########
            #......####
            #..C...####
            #..P.#.A..#
			#..E...####
			#......####
            ###########
            ]],
            [[
            ###########
            #......####
            #..3...####
            #....#.2..#
			#......####
			#......####
            ###########
            ]],
            [[
            ###########
            #......####
            #......####
            #....#...G#
			#......####
			#......####
            ###########
            ]],
            "C3 - Pinpoint",
        },{
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
            "C4 - Bone",
        },{
            [[
            ########
            #.....##
            #.....##
            #.FPA.##
            #.....##
            #####..#
            ########
            ]],
            [[
            ########
            #.....##
            #.....##
            #.2.1.##
            #.....##
            #####..#
            ########
            ]],
            [[
            ########
            #.....##
            #.....##
            #.....##
            #.....##
            #####.G#
            ########
            ]],
            "C5 - Embed",
        },{
            [[
            #############
            #######.....#
            #######.#####
            #..........##
            #.......#####
            #..P.C..#####
            #.......#####
            #..AAB..#####
            #.......#####
            #############
            ]],
            [[
            #############
            #######.....#
            #######.#####
            #..........##
            #.......#####
            #.......#####
            #.......#####
            #..2.3..#####
            #.......#####
            #############
            ]],
            [[
            #############
            #######.G.G.#
            #######.#####
            #..........##
            #.......#####
            #....G..#####
            #.......#####
            #.......#####
            #.......#####
            #############
            ]],
            "X - Priority Switch",
        },
        -- {
        --     [[
        --     ##################
        --     #................#
        --     #................#
        --     #................#
        --     #.P.A.B.C.D.E.F..#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     ##################
        --     ]],
        --     [[
        --     ##################
        --     #................#
        --     #................#
        --     #................#
        --     #.P.1.2.3.4.5.9..#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     ##################
        --     ]],
        --     [[
        --     ##################
        --     #................#
        --     #................#
        --     #................#
        --     #.P.1.2.3.4.5.9..#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     #................#
        --     #...............G#
        --     ##################
        --     ]],
        --     "C5 - Priority Switch",
        -- },
    }

    state.levelIndex = 1
    state.level = Level.fromGrid(globals.levels[state.levelIndex], state.levelIndex)
    state.levelClears = {}

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
            label = "sfx"
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
            label = "music"
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
    globals.levelMusic = {
        [1] = "level1",
        [2] = "level1",
        [3] = "level1",
        [4] = "level2",
        [5] = "level2",
        [6] = "level2",
        [7] = "level3",
        [8] = "level4",
        [9] = "level5",
        [10] = "level5",
        [11] = "challenge1",
        [12] = "challenge1",
        [13] = "challenge2",
        [14] = "challenge2",
        [15] = "challenge3",
    }

    Music.play(Music.menu)
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

    Music.update(dt)
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

    if (key == "return" and (love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")))
       or key == "f11" then
       state.fullscreen = not state.fullscreen
       love.window.setFullscreen(state.fullscreen)
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
