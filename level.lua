local love = require "love"

Level = {}

Cell = {
    Wall = {},
    Player = {},
    Box = {},
    Timer = {},
    Origin = {}
}

Direction = {
    Up = {},
    Down = {},
    Left = {},
    Right = {}
}

Event = {
    Move = {},
    -- Undo = {},
    -- Reset = {},
    -- Teleport = {} (i think this could just be part of Move but also maybe it might be useful to separate it)
    -- future miney here: yeah it's definitely better to separate it
}

-- maybe move these three to a "util.lua"?
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

local function findCells(cells, x, y)
    -- stinky imperative programming   ewwww
    -- [code removed because of how horrifying it looked]

    -- functional programming lets goooooo
    return allWithPredicate(cells, function(cell)
        return cell.x == x and cell.y == y
    end)
end

local function movableWithRegion(cells, region)
    return allWithPredicate(cells, function(cell)
        return cell.region == region and cell.cell ~= Cell.Origin
    end)
end

local function elem(t, item)
    for _, i in ipairs(t) do
        if i == item then return true end
    end
    return false
end

local function append(t1, t2)
    for _, i in ipairs(t2) do
        table.insert(t1, i)
    end
end

function Level.new(height, width, cells)
    return {
        height = height,
        width = width,
        cells = cells,
        eventLog = {}
    }
end

function Level.fromGrid(layer1, layer2)
    local cells = {}
    
    local y = 0
    local x = 0
    for line in string.gmatch(layer1, "[^\n]+") do
        local trimmedLine = string.gsub(line, "%s+", "")
        if trimmedLine == "" then
            break
        end
        x = 0
        for character in string.gmatch(trimmedLine, ".") do
            if character == "#" then
                table.insert(cells, {
                    cell = Cell.Wall,
                    x = x,
                    y = y,
                })
            elseif character == "." then
            elseif string.match(character, "[ABCDEF]") then
                table.insert(cells, {
                    cell = Cell.Box,
                    x = x,
                    y = y,
                    region = character
                })
            elseif character == "P" then
                table.insert(cells, {
                    cell = Cell.Player,
                    x = x,
                    y = y,
                    region = 'P'
                })
            end
            x = x + 1
        end
        y = y + 1
    end

    y = 0
    for line in string.gmatch(layer2, "[^\n]+") do
        local trimmedLine = string.gsub(line, "%s+", "")
        if trimmedLine == "" then
            break
        end
        x = 0
        for character in string.gmatch(trimmedLine, ".") do
            if string.match(character, "[#.]") then
            elseif string.match(character, "%d") then
                r = (function ()
                    for _, cell in ipairs(findCells(cells, x, y)) do
                        if cell.cell == Cell.Box then
                            return cell.region
                        end
                    end
                end)()
                table.insert(cells, {
                    cell = Cell.Origin,
                    x = x,
                    y = y,
                    region = r
                })
                table.insert(cells, {
                    cell = Cell.Timer,
                    x = x,
                    y = y,
                    region = r,
                    val = tonumber(character)
                })
            end
            x = x + 1
        end
        y = y + 1
    end

    -- sort of finished
    return Level.new(y, x, cells)
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
            print(cell.region, string.byte(cell.region), (string.byte(cell.region) * 10.2 - 663))
            love.graphics.setColor((string.byte(cell.region) - 65) * 42.5 / 255, (string.byte(cell.region) - 65) * 42.5 / 255, (6 - (string.byte(cell.region) - 65)) * 42.5 / 255)
        end

        if cell.cell == Cell.Wall or cell.cell == Cell.Player or cell.cell == Cell.Box then
            love.graphics.rectangle("fill", cell.x * cellSize + (width - level.width * cellSize) / 2,
            cell.y * cellSize + (height - level.height * cellSize) / 2, cellSize, cellSize)
        elseif cell.cell == Cell.Timer then
            love.graphics.setColor(0.1, 0.1, 0.1)
            fwidth = godoMaum:getWidth(cell.val)
            fheight = godoMaum:getHeight(cell.val) / 1.75 -- look it works for now okay don't question it
            love.graphics.print(cell.val, godoMaum, cell.x * cellSize + (width - level.width * cellSize + (cellSize - fwidth)) / 2,
            cell.y * cellSize + (height - level.height * cellSize - (cellSize - fheight)) / 2)
        elseif cell.cell == Cell.Origin then
            love.graphics.setColor(211 / 255, 188 / 255, 141 / 255)
            love.graphics.rectangle("fill", (cell.x + 0.25) * cellSize + (width - level.width * cellSize) / 2,
            (cell.y + 0.25) * cellSize + (height - level.height * cellSize) / 2, cellSize / 2, cellSize / 2)
        end
    end

    love.graphics.setColor(1, 1, 1)
end

-- modified so that it returns nil when out of bounds instead of saturating
local function applyDirection(level, cell, direction)
    if direction == Direction.Up then
        if cell.y <= 0 then return nil, nil end
        return cell.x, cell.y - 1
    elseif direction == Direction.Down then
        if cell.y >= level.height - 1 then return nil, nil end
        return cell.x, cell.y + 1
    elseif direction == Direction.Left then
        if cell.x <= 0 then return nil, nil end
        return cell.x - 1, cell.y
    elseif direction == Direction.Right then
        if cell.x >= level.width - 1 then return nil, nil end
        return cell.x + 1, cell.y
    end
end

local function moveCells(level, agentRegion, direction)
    local pending = movableWithRegion(level.cells, agentRegion)
    local addedregions = { agentRegion }
    local events = {}

    print(#pending)
    while #pending ~= 0 do
        c = table.remove(pending)
        print(c.cell, c.x, c.y, c.region)
        nx, ny = applyDirection(level, c, direction)
        if not (nx and ny) then
            print("what")
            return
        end -- something moved out of bounds, abort
        local ncells = findCells(level.cells, nx, ny)
        for _, ncell in ipairs(ncells) do
            if ncell.cell == Cell.Wall then
                print("what2")
                return -- something moved into a wall, abort
            elseif ncell.cell == Cell.Box or ncell.cell == Cell.Timer then
                if not elem(addedregions, ncell.region) then
                    append(pending, movableWithRegion(level.cells, ncell.region))
                    table.insert(addedregions, ncell.region)
                end
            end
        end

        table.insert(events, {
            type = Event.Move,
            from_x = c.x,
            from_y = c.y,
            to_x = nx,
            to_y = ny,
            cell = c
        })
    end
    return events
end
-- deprecated
local function moveCell(level, cell, direction)
    local nx, ny = applyDirection(level, cell, direction)
    local events = {}

    if nx == cell.x and ny == cell.y then
        return
    end

    local ncells = findCells(level.cells, nx, ny)
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

    local events = {}
    local move_events = moveCells(level, 'P', direction)
    if move_events then
        for _, event in ipairs(move_events) do
            table.insert(events, event)
        end
    end

    if #events ~= 0 then
        table.insert(level.eventLog, events)
        for _, event in ipairs(events) do
            runEvent(level, event)
        end
    end
end
