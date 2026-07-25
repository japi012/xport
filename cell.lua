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

    if cell.lastY == cell.y then h, w = w, h end

    local color = level.palette[cell.cell]
    if color.r == nil then
        color = color[string.byte(cell.region) - 64]
    end

    love.graphics.setColor(color())

    if cell.cell == Cell.Goal then
        love.graphics.setCanvas(level.layers[1])
        love.graphics.setLineWidth(5)
        love.graphics.rectangle("line", x * cellSize + (state.width - level.width * cellSize) / 2,
            y * cellSize + (state.height - level.height * cellSize) / 2, cellSize, cellSize)
        love.graphics.setLineWidth(1)

    elseif cell.cell == Cell.Player then
        love.graphics.setCanvas(level.layers[5])
        love.graphics.rectangle("fill", x * cellSize + (state.width - level.width * cellSize - (w - 1) * cellSize) / 2,
        y * cellSize + (state.height - level.height * cellSize - (h - 1) * cellSize) / 2, w * cellSize, h * cellSize)

    elseif cell.cell == Cell.Wall or cell.cell == Cell.Box then
        local timerIsZero = false
        if cell.cell == Cell.Box then
            local timers = allWithPredicate(level.cells, function(c)
                return c.cell == Cell.Timer and c.region == cell.region and c.val == 0
            end)
            if #timers > 0 then
                timerIsZero = true
            end
        end
        love.graphics.setCanvas(level.layers[3])
        if not timerIsZero then
            love.graphics.setColor(color())
        else
            local r, g, b = color()
            love.graphics.setColor(r - 0.2, g - 0.2, b - 0.2) -- REALLY stupid
        end
        love.graphics.rectangle("fill", x * cellSize + (state.width - level.width * cellSize) / 2,
            y * cellSize + (state.height - level.height * cellSize) / 2, cellSize, cellSize)

        love.graphics.setCanvas(level.layers[2])
        local r, g, b = color()
        love.graphics.setColor(r + 0.2, g + 0.2, b + 0.2) -- REALLY stupid
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", x * cellSize + (state.width - level.width * cellSize) / 2,
            y * cellSize + (state.height - level.height * cellSize) / 2, cellSize, cellSize)
        love.graphics.setLineWidth(1)
    elseif cell.cell == Cell.Timer then
        local fwidth = globals.font:getWidth(cell.val)
        local fheight = globals.font:getHeight()

        love.graphics.setCanvas(level.layers[5])
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(cell.val, globals.font,
            x * cellSize + (state.width - level.width * cellSize + (cellSize - fwidth)) / 2,
            y * cellSize + (state.height - level.height * cellSize - (cellSize - fheight * 1.4)) / 2)

        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(5)
        local origins = allWithPredicate(level.cells, function(c)
            return c.region == cell.region and c.cell == Cell.Origin
        end)
        love.graphics.setCanvas(level.layers[1])
        for _, origin in ipairs(origins) do
            love.graphics.line(
                (x + 0.5) * cellSize + (state.width - level.width * cellSize) / 2,
                (y + 0.5) * cellSize + (state.height - level.height * cellSize) / 2,
                (origin.x + 0.5) * cellSize + (state.width - level.width * cellSize) / 2,
                (origin.y + 0.5) * cellSize + (state.height - level.height * cellSize) / 2)
        end

    elseif cell.cell == Cell.Origin then
        love.graphics.setCanvas(level.layers[3])
        drawRotatedRectangle("fill", (x + 0.5) * cellSize + (state.width - level.width * cellSize) / 2,
            (y + 0.5) * cellSize + (state.height - level.height * cellSize) / 2, cellSize / 2, cellSize / 2, cell.animTime * 2 * math.pi)
    end
    love.graphics.setCanvas()
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
        default_val = timer,

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
