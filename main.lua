local love = require "love"
require "util"
require "level"

state = {}
globals = {}

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
            ####..
            #..#..
            #P.#..
            #..###
            #A...#
            #A.B.#
            #..###
            ####..
        ]],[[
            ####..
            #..#..
            #..#..
            #..###
            #4P..#
            #..3.#
            #..###
            ####..
        ]],[[
            ####..
            #..#..
            #..#..
            #..###
            #....#
            #.G..#
            #..###
            ####..
        ]]}
    }

    state.levelIndex = 1
    state.level = Level.fromGrid(globals.levels[state.levelIndex][1],
        globals.levels[state.levelIndex][2], globals.levels[state.levelIndex][3])

    globals.font = "godoMaum.ttf" -- placeholder
end

KEYS_PRESSED = {}
REPEAT_START = 0.5
REPEAT_INTERVAL = 0.05
RECENT_KEY = '';

function love.update(dt)
    HAS_MOVED = false
    for key, data in pairs(KEYS_PRESSED) do
        data.time = data.time + dt

        if RECENT_KEY == key and data.time > REPEAT_START then
            data.repeatTime = data.repeatTime + dt
            if data.repeatTime > REPEAT_INTERVAL then
                data.repeatTime = 0;
                pressedKey(key);
            end
        end
    end
end

function love.draw() -- does this not have deltatime?
    Level.draw(state.level)
end

function love.keypressed(key)
    pressedKey(key)
    RECENT_KEY = key
    KEYS_PRESSED[key] = {
        time = 0,
        repeatTime = 0
    };
end

function pressedKey(key)
    Level.turn(state.level, key)
end

function love.keyreleased(key)
    KEYS_PRESSED[key] = nil;
end

