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

function Cell.draw(cell, level, cellSize)
    local expAnimTime = easeOutExpo(cell.animTime)
    local x, y = lerp(cell.lastX, cell.x, expAnimTime), lerp(cell.lastY, cell.y, expAnimTime)
    local w = cosh(1.3169578969248*(expAnimTime - 0.5)) - 0.25 -- don't worry ! that horrendous constant is just arccosh(2)
    local h = 2 - w

    local color = level.palette[cell.cell]
    if color.r == nil then
        color = color[string.byte(cell.region) - 64]
    end

    love.graphics.setColor(color())

    if cell.cell == Cell.Goal then
        love.graphics.setLineWidth(5)
        love.graphics.rectangle("line", x * cellSize + (state.width - level.width * cellSize) / 2,
            y * cellSize + (state.height - level.height * cellSize) / 2, cellSize, cellSize)
        love.graphics.setLineWidth(1)

        if cell.cell == Cell.Player then
            love.graphics.rectangle("fill", x * cellSize + (state.width - level.width * cellSize - (w - 1) * cellSize) / 2,
            y * cellSize + (state.height - level.height * cellSize - (h - 1) * cellSize) / 2, w * cellSize, h * cellSize)
        else
            love.graphics.rectangle("fill", x * cellSize + (state.width - level.width * cellSize) / 2,
            y * cellSize + (state.height - level.height * cellSize) / 2, cellSize, cellSize)
        end
    else
        if cell.cell == Cell.Timer then
            love.graphics.setColor(level.palette[cell.cell]())

    elseif cell.cell == Cell.Wall or cell.cell == Cell.Box then
        love.graphics.rectangle("fill", x * cellSize + (state.width - level.width * cellSize) / 2,
            y * cellSize + (state.height - level.height * cellSize) / 2, cellSize, cellSize)

    elseif cell.cell == Cell.Timer then
        local fwidth = globals.font:getWidth(cell.val)
        local fheight = globals.font:getHeight()

        love.graphics.print(cell.val, globals.font,
            x * cellSize + (state.width - level.width * cellSize + (cellSize - fwidth)) / 2,
            y * cellSize + (state.height - level.height * cellSize - (cellSize - fheight * 1.35)) / 2)

    elseif cell.cell == Cell.Origin then
        love.graphics.rectangle("fill", (x + 0.25) * cellSize + (state.width - level.width * cellSize) / 2,
            (y + 0.25) * cellSize + (state.height - level.height * cellSize) / 2, cellSize / 2, cellSize / 2)

            love.graphics.print(cell.val, globals.font,
                x * cellSize + (state.width - level.width * cellSize + (cellSize - fwidth)) / 2,
                y * cellSize + (state.height - level.height * cellSize - (cellSize - fheight * 1.35)) / 2)
        elseif cell.cell == Cell.Origin then
            love.graphics.setColor(level.palette[cell.cell][string.byte(cell.region) - 64]())
            drawRotatedRectangle("fill", (x + 0.5) * cellSize + (state.width - level.width * cellSize) / 2,
                (y + 0.5) * cellSize + (state.height - level.height * cellSize) / 2, cellSize / 2, cellSize / 2, cell.animTime * 2 * math.pi)
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
