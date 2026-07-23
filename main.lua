local love = require "love"
require "level"

state = {}

function love.load()
    state.level = Level.fromGrid({
        { Cell.Wall, Cell.Wall },
        { Cell.Wall, Cell.Empty, Cell.Box, Cell.Box, Cell.Empty, Cell.Empty },
        { Cell.Wall, Cell.Empty, Cell.Empty, Cell.Empty, Cell.Wall },
        { Cell.Wall, Cell.Empty, Cell.Empty, Cell.Empty, Cell.Wall },
        { Cell.Wall, Cell.Player, Cell.Empty, Cell.Empty, Cell.Wall },
        { Cell.Wall, Cell.Wall, Cell.Wall },
    })
end

function love.update(dt)

end

function love.draw()
    Level.draw(state.level)
end

function love.keypressed(key)
    Level.turn(state.level, key)
end
