local love = require "love"

Level = {}

Cell = {
    Wall = {},
    Player = {},
    Box = {},
    Timer = {},
    Origin = {},
    Goal = {}
}

-- Types of cells that draw a solid square
SolidDraw = {
    [Cell.Wall] = true,
    [Cell.Player] = true,
    [Cell.Box] = true
}

Direction = {
    Up = {},
    Down = {},
    Left = {},
    Right = {}
}

Event = {
    Move = {},
    TimerChange = {},
    -- Undo = {},
    Reset = {},
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

function Level.new(height, width, cells, palette)
    return {
        height = height,
        width = width,
        cells = cells,
        palette = palette or Palette.defaultList(),
        eventLog = {}
    }
end

function Level.fromGrid(layer1, layer2, layer3, palette)
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
                local r
                for _, cell in ipairs(findCells(cells, x, y)) do
                    if cell.cell == Cell.Box then
                        r = cell.region
                    end
                end
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

    y = 0
    for line in string.gmatch(layer3, "[^\n]+") do
        local trimmedLine = string.gsub(line, "%s+", "")
        if trimmedLine == "" then
            break
        end
        x = 0
        for character in string.gmatch(trimmedLine, ".") do
            if string.match(character, "[#.]") then
            elseif string.match(character, "G") then
                table.insert(cells, {
                    cell = Cell.Goal,
                    x = x,
                    y = y,
                })
            end
            x = x + 1
        end
        y = y + 1
    end

    -- sort of finished
    return Level.new(y, x, cells, palette)
end

local width = 0
local height = 0
local lastWidth = 0
local lastHeight = 0

local newFont = {}

function Level.draw(level)
    lastWidth = width
    lastHeight = height
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()

    local cellSize = math.min(width / level.width, height / level.height) * 0.5

    if lastWidth ~= width or lastHeight ~= height then
        newFont = love.graphics.newFont(globals.font, cellSize * 0.9)
    end

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", (width - level.width * cellSize) / 2, (height - level.height * cellSize) / 2,
        cellSize * level.width, cellSize * level.height)

    for _, cell in ipairs(level.cells) do
        if cell.cell == Cell.Goal then
            love.graphics.setLineWidth(5)
            love.graphics.setColor(level.palette[cell.cell]())
            love.graphics.rectangle("line", cell.x * cellSize + (width - level.width * cellSize) / 2,
            cell.y * cellSize + (height - level.height * cellSize) / 2, cellSize, cellSize)
            love.graphics.setLineWidth(1)
        end
    end

    for _, cell in ipairs(level.cells) do
        if SolidDraw[cell.cell] then
            if cell.cell == Cell.Box then
                love.graphics.setColor(level.palette[cell.cell][string.byte(cell.region) - 64]())
            else
                love.graphics.setColor(level.palette[cell.cell]())
            end

            love.graphics.rectangle("fill", cell.x * cellSize + (width - level.width * cellSize) / 2,
            cell.y * cellSize + (height - level.height * cellSize) / 2, cellSize, cellSize)
        end
    end

    for _, cell in ipairs(level.cells) do
        if cell.cell == Cell.Timer then
            love.graphics.setColor(level.palette[cell.cell]())

            local fwidth = newFont:getWidth(cell.val)
            local fheight = newFont:getHeight()

            love.graphics.print(cell.val, newFont, cell.x * cellSize + (width - level.width * cellSize + (cellSize - fwidth)) / 2,
            cell.y * cellSize + (height - level.height * cellSize - (cellSize - fheight)) / 2)
        elseif cell.cell == Cell.Origin then
            love.graphics.setColor(level.palette[cell.cell]())
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

    while #pending ~= 0 do
        local c = table.remove(pending)
        local nx, ny = applyDirection(level, c, direction)

        if not (nx and ny) then
            return
        end -- something moved out of bounds, abort
        local ncells = findCells(level.cells, nx, ny)
        for _, ncell in ipairs(ncells) do
            if ncell.cell == Cell.Wall then
                return -- something moved into a wall, abort
            elseif ncell.cell == Cell.Box or ncell.cell == Cell.Timer then
                -- if ncell.cell == Cell.Timer and ncell.cell.val == 0 then
                --     return -- something moved into a box with a timer of 0, abort
                -- end

                if not elem(addedregions, ncell.region) then
                    append(pending, movableWithRegion(level.cells, ncell.region))
                    table.insert(addedregions, ncell.region)
                end
            end
        end

        local move = {
            type = Event.Move,
            from_x = c.x,
            from_y = c.y,
            to_x = nx,
            to_y = ny,
            cell = c
        }
        table.insert(events, move)

        if c.cell == Cell.Timer then
            local timer_change = {
                type = Event.TimerChange,
                cell = c,
                from_val = c.val,
                to_val = c.val - 1
            }
            if c.val == 0 then
                timer_change.to_val = 0
            end
            table.insert(events, timer_change)
        end
    end
    return events
end

-- decapitated ...
-- local function moveCell(level, cell, direction)
--     local nx, ny = applyDirection(level, cell, direction)
--     local events = {}

--     if nx == cell.x and ny == cell.y then
--         return
--     end

--     local ncells = findCells(level.cells, nx, ny)
--     for _, ncell in ipairs(ncells) do
--         if ncell.cell == Cell.Wall then
--             return
--         elseif ncell.cell == Cell.Box then
--             local box_events = moveCell(level, ncell, direction)
--             if box_events == nil then
--                 return
--             end
--             events = box_events
--         end
--     end

--     table.insert(events, {
--         type = Event.Move,
--         from_x = cell.x,
--         from_y = cell.y,
--         to_x = nx,
--         to_y = ny,
--         cell = cell
--     })

--     return events
-- end

local function runUndo(level)
    local events = table.remove(level.eventLog)
    if events == nil then
        return
    end

    for _, event in ipairs(events) do
        if event.type == Event.Move then
            event.cell.x = event.from_x
            event.cell.y = event.from_y
        elseif event.type == Event.TimerChange then
            event.cell.val = event.from_val
        end
    end
end

local function runEvent(level, event)
    if event.type == Event.Move then
        event.cell.x = event.to_x
        event.cell.y = event.to_y
    elseif event.type == Event.TimerChange then
        event.cell.val = event.to_val
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
