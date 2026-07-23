local love = require "love"

Level = {}

Cell = {
    Wall = {},
    Player = {},
    Box = {},
    Empty = {}
}

Direction = {
    Up = {},
    Down = {},
    Left = {},
    Right = {}
}

Event = {
    Move = {}
}

function Level.new(height, width, cells)
    return {
        height = height,
        width = width,
        cells = cells,
        eventLog = {}
    }
end

function Level.fromGridAscii(asciiGrid, height, width)
    local cells = {}

    for y, row in ipairs(grid) do
        for x, cell in ipairs(row) do
            if cell ~= Cell.Empty then
                table.insert(cells, {
                    cell = cell,
                    x = x - 1,
                    y = y - 1
                })
            end
        end
    end

    return Level.new(height or #grid, width or (function()
        local max = 0
        for _, row in ipairs(grid) do
            local len = #row
            if len > max then
                max = len
            end
        end
        return max
    end)(), cells)
end

function Level.fromGrid(grid, height, width)
    local cells = {}

    for y, row in ipairs(grid) do
        for x, cell in ipairs(row) do
            if cell ~= Cell.Empty then
                table.insert(cells, {
                    cell = cell,
                    x = x - 1,
                    y = y - 1
                })
            end
        end
    end

    return Level.new(height or #grid, width or (function()
        local max = 0
        for _, row in ipairs(grid) do
            local len = #row
            if len > max then
                max = len
            end
        end
        return max
    end)(), cells)
end

function Level.draw(level)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    local cellSize = math.min(width / level.width, height / level.height) * 0.5

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", (width - level.width * cellSize) / 2, (height - level.height * cellSize) / 2,
        cellSize * level.width, cellSize * level.height)

    for _, cell in ipairs(level.cells) do
        if cell.cell == Cell.Wall then
            love.graphics.setColor(0.3, 0.3, 0.3)
        elseif cell.cell == Cell.Player then
            love.graphics.setColor(1, 1, 1)
        elseif cell.cell == Cell.Box then
            love.graphics.setColor(211 / 255, 188 / 255, 141 / 255)
        end

        love.graphics.rectangle("fill", cell.x * cellSize + (width - level.width * cellSize) / 2,
            cell.y * cellSize + (height - level.height * cellSize) / 2, cellSize, cellSize)
    end

    love.graphics.setColor(1, 1, 1)
end

local function allWithPredicate(list, predicate)
    -- imperative under the hood, but we hide it under a functional wrapper
    -- kinda neat
    local found = {}

    for _, value in ipairs(list) do
        if predicate(value) then
            table.insert(found, value)
        end
    end

    return found
end

local function findCells(level, x, y)
    -- stinky imperative programming   ewwww
    -- local cells = {}

    -- for _, cell in ipairs(level.cells) do
    --     if cell.x == x and cell.y == y then
    --         table.insert(cells, cell)
    --     end
    -- end

    -- return cells

    -- functional programming lets goooooo
    return allWithPredicate(level.cells, function(cell)
        return cell.x == x and cell.y == y
    end)
end

local function applyDirection(level, cell, direction)
    if direction == Direction.Up then
        return cell.x, math.max(0, cell.y - 1)
    elseif direction == Direction.Down then
        return cell.x, math.min(level.height - 1, cell.y + 1)
    elseif direction == Direction.Left then
        return math.max(0, cell.x - 1), cell.y
    elseif direction == Direction.Right then
        return math.min(level.width - 1, cell.x + 1), cell.y
    end
end

local function moveCell(level, cell, direction)
    local nx, ny = applyDirection(level, cell, direction)
    local events = {}

    if nx == cell.x and ny == cell.y then
        return
    end

    local ncells = findCells(level, nx, ny)
    for _, ncell in ipairs(ncells) do
        if ncell.cell == Cell.Wall then
            return
        elseif ncell.cell == Cell.Box then
            local box_events = moveCell(level, ncell, direction)
            if box_events == nil then
                return
            end
            events = box_events
        end
    end

    table.insert(events, {
        type = Event.Move,
        from_x = cell.x,
        from_y = cell.y,
        to_x = nx,
        to_y = ny,
        cell = cell
    })

    return events
end

local function runUndo(level)
    local events = table.remove(level.eventLog)
    if events == nil then
        return
    end

    for _, event in ipairs(events) do
        if event.type == Event.Move then
            event.cell.x = event.from_x
            event.cell.y = event.from_y
        end
    end
end

local function runEvent(level, event)
    if event.type == Event.Move then
        for _, cell in ipairs(level.cells) do
            if cell == event.cell then
                event.cell.x = event.to_x
                event.cell.y = event.to_y
            end
        end
    end
end

function Level.turn(level, key)
    local direction
    if key == "up" then
        direction = Direction.Up
    elseif key == "down" then
        direction = Direction.Down
    elseif key == "left" then
        direction = Direction.Left
    elseif key == "right" then
        direction = Direction.Right
    else
        if key == "z" then
            runUndo(level)
        end

        return
    end

    for _, cell in ipairs(level.cells) do
        local events = {}
        if cell.cell == Cell.Player then
            local move_events = moveCell(level, cell, direction)
            if move_events then
                for _, event in ipairs(move_events) do
                    table.insert(events, event)
                end
            end
        end

        if #events ~= 0 then
            table.insert(level.eventLog, events)
            for _, event in ipairs(events) do
                runEvent(level, event)
            end
        end
    end
end
