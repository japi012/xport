local love = require "love"
if Cell ~= nil then return Cell end

local function makeType(drawLayer)
    return {
        layer = drawLayer
    }
end

Cell = {
    Wall = makeType(1),
    Player = makeType(1),
    Box = makeType(1),
    Timer = makeType(2.5),
    Origin = makeType(2),
    Goal = makeType(3),
}

-- local drawFunctions = {
--     default = function(cell) end,
--     [Cell.Wall] = function(cell)
--     end
-- }

-- Types of cells that draw a solid square
Cell.solids = {
    [Cell.Wall] = true,
    [Cell.Player] = true,
    [Cell.Box] = true
}

function Cell.draw(cell, level, cellSize)
    local animTime = easeOutExpo(cell.animTime)
    local x, y = lerp(cell.lastX, cell.x, animTime), lerp(cell.lastY, cell.y, animTime)

    if cell.cell == Cell.Goal then
        love.graphics.setLineWidth(5)
        love.graphics.setColor(level.palette[cell.cell]())
        love.graphics.rectangle("line", x * cellSize + (state.width - level.width * cellSize) / 2,
            y * cellSize + (state.height - level.height * cellSize) / 2, cellSize, cellSize)
        love.graphics.setLineWidth(1)
    elseif Cell.solids[cell.cell] then
        if cell.cell == Cell.Box then
            love.graphics.setColor(level.palette[cell.cell][string.byte(cell.region) - 64]())
        else
            love.graphics.setColor(level.palette[cell.cell]())
        end

        love.graphics.rectangle("fill", x * cellSize + (state.width - level.width * cellSize) / 2,
            y * cellSize + (state.height - level.height * cellSize) / 2, cellSize, cellSize)
    else
        if cell.cell == Cell.Timer then
            love.graphics.setColor(level.palette[cell.cell]())

            local fwidth = globals.font:getWidth(cell.val)
            local fheight = globals.font:getHeight()

            love.graphics.print(cell.val, globals.font,
                x * cellSize + (state.width - level.width * cellSize + (cellSize - fwidth)) / 2,
                y * cellSize + (state.height - level.height * cellSize - (cellSize - fheight * 1.35)) / 2)
        elseif cell.cell == Cell.Origin then
            love.graphics.setColor(level.palette[cell.cell]())
            love.graphics.rectangle("fill", (x + 0.25) * cellSize + (state.width - level.width * cellSize) / 2,
                (y + 0.25) * cellSize + (state.height - level.height * cellSize) / 2, cellSize / 2, cellSize / 2)
        end
    end
end

function Cell.startMoveAnim(cell)
    cell.lastX = cell.x
    cell.lastY = cell.y
    cell.animTime = 0
end

function Cell.new(x, y, id, type, region, timer)
    local result = {
        x = x,
        y = y,
        id = id,

        lastX = x,
        lastY = y,

        cell = type,
        region = region,
        val = timer,

        draw = Cell.draw,
        animTime = 0
    }

    -- result.draw = drawFunctions[type] or drawFunctions.default

    return result
end

function Cell.fromChar(x, y, id, character)
    if character == "#" then
        return Cell.new(x, y, id, Cell.Wall)
    elseif string.match(character, "[ABCDEF]") then
        return Cell.new(x, y, id, Cell.Box, character)
    elseif character == "P" then
        return Cell.new(x, y, id, Cell.Player, character)
    end
end

return Cell
