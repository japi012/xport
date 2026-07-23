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

function love.update(dt)

end

function love.draw()
    Level.draw(state.level)
end

function love.keypressed(key)
    Level.turn(state.level, key)
end
