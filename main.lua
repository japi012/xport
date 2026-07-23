local love = require "love"
require "level"

state = {}

function love.load()
    state.level = Level.fromGrid([[
        ####..
        #..#..
        #..#..
        #..###
        #A...#
        #..B.#
        #..###
        ####..
    ]],[[
        ####..
        #..#..
        #..#..
        #..###
        #4+..#
        #..3.#
        #..###
        ####..
    ]])
end

function love.update(dt)

end

function love.draw()
    Level.draw(state.level)
end

function love.keypressed(key)
    Level.turn(state.level, key)
end
