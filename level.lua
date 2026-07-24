local love = require "love"
local Cell = require "cell"

Level = {}

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
    -- Reset = {},
    Teleport = {} -- (i think this could just be part of Move but also maybe it might be useful to separate it)
    -- future miney here: yeah it's definitely better to separate it
}

-- maybe move these three to a "util.lua"?
-- answer: only one goes (wee)
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

function Level.new(height, width, cells, palette)
    local result = {
        height = height,
        width = width,
        cells = cells,
        palette = palette or Palette.defaultList(),
        winning = false,
        animationTime = 0,
        eventLog = {}
    }

    table.sort(result.cells, function(a, b)
        return a.cell.layer < b.cell.layer
    end)
    return result
end

function Level.fromGrid(grid, palette)
    local layer1, layer2, layer3 = grid[1], grid[2], grid[3]
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
            if character ~= "." then
                table.insert(cells, Cell.fromChar(x, y, #cells + 1, character))
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
                    if cell.region ~= nil then
                        r = cell.region
                    end
                end
                table.insert(cells, Cell.new(x, y, #cells + 1, Cell.Origin, r))
                table.insert(cells, Cell.new(x, y, #cells + 1, Cell.Timer, r, tonumber(character)))
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
                table.insert(cells, Cell.new(x, y, #cells + 1, Cell.Goal))
            end
            x = x + 1
        end
        y = y + 1
    end

    -- sort of finished
    return Level.new(y, x, cells, palette)
end

function Level.update(level, dt)
    -- level.animationTime = math.min(1, level.animationTime + dt / DEBUG.AnimationTime)

    for _, cell in ipairs(level.cells) do
        if cell.animTime < 1 then
            cell.animTime = math.min(1, cell.animTime + dt / DEBUG.AnimationTime)
        end
    end
end

function Level.draw(level)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", (state.width - level.width * state.cellSize) / 2, (state.height - level.height * state.cellSize) / 2,
        state.cellSize * level.width, state.cellSize * level.height)

    for _, cell in ipairs(level.cells) do
        cell:draw(level, state.cellSize);
    end
end

-- modified so that it returns nil when out of bounds instead of saturating
local function applyDirection(level, cell, direction)
    Cell.startMoveAnim(cell)
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
    local timers = {}
    local moves = {}

    while #pending ~= 0 do
        local c = table.remove(pending)

        if c.cell == Cell.Timer then
            table.insert(timers, c)
        end

        local nx, ny = applyDirection(level, c, direction)

        if not (nx and ny) then
            return {}
        end -- something moved out of bounds, abort
        local ncells = findCells(level.cells, nx, ny)
        for _, ncell in ipairs(ncells) do
            if ncell.cell == Cell.Wall then
                return {} -- something moved into a wall, abort
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

        table.insert(moves, {
            type = Event.Move,
            from_x = c.x,
            from_y = c.y,
            to_x = nx,
            to_y = ny,
            cell = c,
            move_origin = false,
        })
        -- table.insert(events, move)

    end

    local teleportTimers = {}
    if #moves > 0 then
        for _, timer in ipairs(timers) do
            if timer.val <= 1 then
                local origin = allWithPredicate(level.cells, function(cell)
                    return cell.cell == Cell.Origin and cell.region == timer.region
                end)[1]
                table.insert(teleportTimers, timer)
                if timer.val > 0 then
                    local timer_change = {
                        type = Event.TimerChange,
                        cell = timer,
                        from_val = timer.val,
                        to_val = timer.val - 1
                    }
                    table.insert(events, timer_change)
                end
                -- for i, move in ipairs(moves) do
                --     if move.cell.region == timer.region then
                --         local timerEvent = {
                --             type = Event.Teleport,
                --             from_x = move.cell.x,
                --             from_y = move.cell.y,
                --             to_x = -(timer.x - move.cell.x) + origin.x,
                --             to_y = -(timer.y - move.cell.y) + origin.y,
                --             region = timer.region,
                --             cell = move.cell,
                --             timer = timer,
                --         }
                --         table.insert(events, timerEvent)
                --         if #moves == i then
                --             timerEvent.move_origin_event = move
                --             move.move_origin = true
                --         end
                --     end
                -- end
            else
                for _, timer in ipairs(timers) do
                    if not elem(teleportTimers, timer) then
                        local timer_change = {
                            type = Event.TimerChange,
                            cell = timer,
                            from_val = timer.val,
                            to_val = timer.val - 1
                        }
                        table.insert(events, timer_change)
                    end
                end
            end
        end
    end

    append(events, moves)

    return events
end

-- local function secondPassEvents(level, events)
--     local cells = level.cells
--     local newCells = {}

--     for i, cell in ipairs(cells) do
--         newCells[cell.id] = cloneUnitTables(cell)
--     end

--     for _, event in ipairs(events) do
--         if event.type == Event.Move then
--             newCells[event.cell.id].x = event.to_x
--             newCells[event.cell.id].y = event.to_y
--         elseif event.type == Event.TimerChange then
--             newCells[event.cell.id].var = event.to_var
--         elseif event.type == Event.Teleport then
--             newCells[event.cell.id].x = event.to_x
--             newCells[event.cell.id].y = event.to_y
--         end
--     end

--     local newEvents = {}
--     local disabledTeleportRegions = {}
--     for _, event in ipairs(events) do
--         if event.type == Event.Teleport then
--             if not elem(disabledTeleportRegions, event.region) then
--                 local ncells = findCells(newCells, event.to_x, event.to_y)
--                 local canTeleport = true
--                 for _, ncell in ipairs(ncells) do
--                     if ncell.region ~= event.cell.region then
--                         if ncell.cell == Cell.Wall or ncell.cell == Cell.Box or ncell.cell == Cell.Player then
--                             canTeleport = false
--                         end
--                     end
--                 end
--                 print(canTeleport)
--                 if canTeleport then
--                     if event.to_x < 0 or event.to_x > level.width + 1 or event.to_y < 0 or event.to_y > level.height + 1 then
--                         table.insert(disabledTeleportRegions, event.region)
--                     else
--                         table.insert(newEvents, event)
--                     end
--                 else
--                     table.insert(disabledTeleportRegions, event.region)
--                 end
--             end
--         else
--             table.insert(newEvents, event)
--         end
--     end

--     print(#disabledTeleportRegions)

--     local finalEvents = {}

--     for _, event in ipairs(newEvents) do
--         if event.type == Event.Move then
--             table.insert(finalEvents, event)
--         end
--     end

--     for _, event in ipairs(newEvents) do
--         if not elem(finalEvents, event) then
--             if event.type == Event.Teleport then
--                 if not elem(disabledTeleportRegions, event.region) then
--                     table.insert(finalEvents, event)
--                     if event.move_origin_event then
--                         event.move_origin_event.move_origin = false
--                     end
--                 end
--             else
--                 table.insert(finalEvents, event)
--             end
--         end
--     end

--     return finalEvents
-- end

local function isWinning(level)
    for _, cell in ipairs(level.cells) do
        if cell.cell == Cell.Goal then
            local ncells = findCells(level.cells, cell.x, cell.y)
            local boxes = allWithPredicate(ncells, function(cell)
                return cell.cell == Cell.Box
            end)

            if #boxes > 0 then
                level.winning = true
            end
        end
    end
end

local function runUndo(level)
    level.animationTime = 0

    local events = table.remove(level.eventLog)
    if events == nil then
        return
    end

    for _, event in ipairs(events) do
        if event.type == Event.Move then
            Cell.startMoveAnim(event.cell)
            event.cell.x = event.from_x
            event.cell.y = event.from_y

            if event.move_origin then
                local dirX = event.from_x - event.to_x
                local dirY = event.from_y - event.to_y
                local origin = allWithPredicate(level.cells, function(cell)
                    return cell.cell == Cell.Origin and cell.region == event.cell.region
                end)[1]
                if origin then
                    origin.x = origin.x + dirX
                    origin.y = origin.y + dirY
                end
            end
        elseif event.type == Event.TimerChange then
            event.cell.val = event.from_val
        -- elseif event.type == Event.Teleport then
        --     event.cell.x = event.from_x
        --     event.cell.y = event.from_y
        --     event.timer.val = 1
        end
    end
end

local function runEvent(level, event)
    if event.type == Event.Move then
        event.cell.x = event.to_x
        event.cell.y = event.to_y

        if event.move_origin then
            local dirX = event.to_x - event.from_x
            local dirY = event.to_y - event.from_y
            local origin = allWithPredicate(level.cells, function(cell)
                return cell.cell == Cell.Origin and cell.region == event.cell.region
            end)[1]
            if origin then
                origin.x = origin.x + dirX
                origin.y = origin.y + dirY
            end
        end
    elseif event.type == Event.TimerChange then
        event.cell.val = event.to_val
    -- elseif event.type == Event.Teleport then
    --     event.cell.x = event.to_x
    --     event.cell.y = event.to_y
    --     event.timer.val = event.timer.startVal
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

    local events = moveCells(level, 'P', direction)
    if events == nil then events = {} end
    -- events = secondPassEvents(level, events)

    if #events ~= 0 then
        table.insert(level.eventLog, events)
        for _, event in ipairs(events) do
            runEvent(level, event)
        end
    end
end
