local love = require "love"
require "level"

state = {}

function love.load()
    state.level = Level.fromGrid([[
        .......
        PP.....
        P.A....
        ..B....
        .BB....
        ]],[[
        .......
        .......
        .......
        .......
        .......
        ]])
    -- state.level = Level.fromGrid([[
    --     ####..
    --     #..#..
    --     #P.#..
    --     #..###
    --     #A...#
    --     #..B.#
    --     #..###
    --     ####..
    -- ]],[[
    --     ####..
    --     #..#..
    --     #..#..
    --     #..###
    --     #4+..#
    --     #..3.#
    --     #..###
    --     ####..
    -- ]])
    godoMaum = love.graphics.newFont("godoMaum.ttf", 80) -- placeholder
end

function love.update(dt)

end

function love.draw()
    Level.draw(state.level)
end

function love.keypressed(key)
    Level.turn(state.level, key)
end
