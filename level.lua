local love = require "love"
local Cell = require "cell"
local Animation = require "anim"

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
    -- Reset = {},
    Teleport = {}, -- (i think this could just be part of Move but also maybe it might be useful to separate it)
    -- future miney here: yeah it's definitely better to separate it
    OriginMove = {}
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

local function isInBounds(level, x, y)
    return x >= 0 and y >= 0 and x < level.width and y < level.height
end

function Level.new(height, width, cells, palette)
    local result = {
        height = height,
        width = width,
        cells = cells,
        palette = palette or Palette.defaultList(),
        winning = false,
        animationTime = 0,
        layers = {},
        eventLog = {},
        goalPlaying = false
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

function Level.onResize(level)
    for i = 1, 5 do
        if level.layers[i] ~= nil then level.layers[i]:release() end
        level.layers[i] = love.graphics.newCanvas()
    end
end

function Level.update(level, dt)
    -- level.animationTime = math.min(1, level.animationTime + dt / DEBUG.AnimationTime)

    for _, cell in ipairs(level.cells) do
        if cell.animTime < 1 then
            cell.animTime = math.min(1, cell.animTime + dt / DEBUG.AnimationTime)
        elseif cell.cell == Cell.Origin then
            cell.animTime = cell.animTime + dt / (DEBUG.AnimationTime * 25)
            if cell.animTime >= 2 then cell.animTime = cell.animTime - 1 end
            -- checking if >=2 here cause for some reason it becomes 10x slower if it's >=1 ??? either way this animation works modulo 1 so it doesn't matter
        end
    end
end

function Level.draw(level)
    love.graphics.setBackgroundColor(level.palette.background())
    love.graphics.setColor(level.palette.levelStroke())
    love.graphics.setLineWidth(5)
    love.graphics.rectangle("line", (state.width - level.width * state.cellSize) / 2, (state.height - level.height * state.cellSize) / 2,
        state.cellSize * level.width, state.cellSize * level.height)
    love.graphics.setLineWidth(1)

    love.graphics.setColor(level.palette.levelFill())
    love.graphics.rectangle("fill", (state.width - level.width * state.cellSize) / 2, (state.height - level.height * state.cellSize) / 2,
        state.cellSize * level.width, state.cellSize * level.height)
    love.graphics.setColor(1, 1, 1)

    for _, cell in ipairs(level.cells) do
        cell:draw(level, state.cellSize)
    end

    love.graphics.setCanvas()
    love.graphics.setBlendMode("alpha", "premultiplied")

    for i, layer in ipairs(level.layers) do
        -- love.graphics.setColor(0, 0, 0, 0.5)
        -- love.graphics.rectangle("fill", 0, 0, state.width, state.height)
        local layer = level.layers[i]
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(layer)

        love.graphics.setCanvas(layer)
        love.graphics.clear()
        love.graphics.setCanvas()
    end

    love.graphics.setBlendMode("alpha") -- Default blend mode.
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
            cell = c
        })

    end

    if #moves > 0 then
        for _, timer in ipairs(timers) do
            if timer.val > 0 then
                local timer_change = {
                    type = Event.TimerChange,
                    cell = timer,
                    from_val = timer.val,
                    to_val = timer.val - 1
                }
                table.insert(events, timer_change)
            else
                local movable = true
                local nx, ny = applyDirection(level, origin, direction)
                if not (nx and ny) then movable = false end
                targets = findCells(level.cells, nx, ny)
                if movable then
                    -- origin moves moved here
                    local origin_move = {
                        type = Event.OriginMove,
                        from_x = origin.x,
                        from_y = origin.y,
                        to_x = nx,
                        to_y = ny,
                        cell = origin
                    }
                    table.insert(events, origin_move)
                end
            end
        end
    end

    append(events, moves)

    return events
end

local function handleTeleports(level, direction)
    local events = {}

    local zerotimers = allWithPredicate(level.cells, function (cell)
        return cell.cell == Cell.Timer and cell.val == 0
    end)
    for _, timer in ipairs(zerotimers) do
        -- print("here", timer.region)
        origin = allWithPredicate(level.cells, function (cell)
            return cell.cell == Cell.Origin and cell.region == timer.region
        end)[1] -- if this ever throws an index error then we quit gamedev forever
        boxes = allWithPredicate(level.cells, function (cell)
            return cell.cell == Cell.Box and cell.region == timer.region
        end)
        blocked = false
        for _, box in ipairs(boxes) do
            if not isInBounds(level, box.x - timer.x + origin.x, box.y - timer.y + origin.y) then
                -- print("oops out of bounds")
                blocked = true
                goto isBlocked -- this one is my fault though
            end
            targets = findCells(level.cells, box.x - timer.x + origin.x, box.y - timer.y + origin.y)
            for _, target in ipairs(targets) do
                if target.cell == Cell.Player or target.cell == Cell.Wall or (target.cell == Cell.Box and target.region ~= timer.region) then
                    blocked = true
                    goto isBlocked -- i had to. it was the only way...
                end
            end
        end
        ::isBlocked::

        -- if blocked then
        --
        --     local movable = true
        --     local nx, ny = applyDirection(level, origin, direction)
        --     if not (nx and ny) then movable = false end
        --     targets = findCells(level.cells, nx, ny)
        --     for _, target in ipairs(targets) do
        --         if target.cell == Cell.Wall then movable = false end
        --     end
        --     if movable then
        --         ok the origin move used to be added here but now it's handled along with the other move logic
        --         local origin_move = {
        --             type = Event.OriginMove,
        --             from_x = origin.x,
        --             from_y = origin.y,
        --             to_x = nx,
        --             to_y = ny,
        --             cell = origin
        --         }
        --         table.insert(events, origin_move)
        --     end
        if not blocked then
            for _, box in ipairs(boxes) do
                local teleport = {
                    type = Event.Teleport,
                    from_x = box.x,
                    from_y = box.y,
                    to_x = box.x - timer.x + origin.x,
                    to_y = box.y - timer.y + origin.y,
                    cell = box,
                    timer = timer
                }
                table.insert(events, teleport)
            end
            local teleport = {
                type = Event.Teleport,
                from_x = timer.x,
                from_y = timer.y,
                to_x = origin.x,
                to_y = origin.y,
                cell = timer,
                timer = timer
            }
            table.insert(events, teleport)
        end
    end
	return events
end

local function secondPassEvents(level, teleports)
    local occupied = {}
    for _, event in ipairs(teleports) do
        occupied[event.to_x][event.to_y] = event.timer.region
end

local function isWinning(level)
    local winning = true
    for _, cell in ipairs(level.cells) do
        if cell.cell == Cell.Goal then
            local ncells = findCells(level.cells, cell.x, cell.y)
            local boxes = allWithPredicate(ncells, function(cell)
                return cell.cell == Cell.Box
            end)

            if #boxes == 0 then
                winning = false
            end
        end
    end
    return winning
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
        elseif event.type == Event.TimerChange then
            event.cell.val = event.from_val
        elseif event.type == Event.Teleport then
            event.cell.x = event.from_x
            event.cell.y = event.from_y
            event.timer.val = 0
        elseif event.type == Event.OriginMove then
            event.cell.x = event.from_x
            event.cell.y = event.from_y
        end
    end
end

local function runEvent(level, event)
    if event.type == Event.Move then
        event.cell.x = event.to_x
        event.cell.y = event.to_y
    elseif event.type == Event.TimerChange then
        event.cell.val = event.to_val
    elseif event.type == Event.Teleport then
        event.cell.x = event.to_x
        event.cell.y = event.to_y
        event.timer.val = event.timer.default_val
    elseif event.type == Event.OriginMove then
        event.cell.x = event.to_x
        event.cell.y = event.to_y
    end
end

function Level.turn(level, key)
    if level.goalPlaying then return end

    if key == "escape" then
        state.mode = Mode.Menu
        forceUpdateGraphics()
        return
    end

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

    for _, event in ipairs(events) do
        runEvent(level, event)
    end

    local teleports = {}
    while true do
        local teleportbatch = handleTeleports(level, direction) -- also includes origin moves

        if #teleportbatch == 0 then break end
        teleports = secondPassEvents(level, teleports)
        for _, teleport in ipairs(teleportbatch) do
            runEvent(level, teleport)
        end
        append(teleports, teleportbatch)
    end

    append(teleports, events) -- very important that teleports get undone before moves
    if #teleports > 0 then table.insert(level.eventLog, teleports) end

    if isWinning(level) then
        state.levelClears[state.levelIndex] = true

        local goals = allWithPredicate(level.cells, function(cell)
            return cell.cell == Cell.Goal
        end)
        local startDelay = 0.5
        local goalAnimTime = 2.0
        local endAnimTime = 1.0
        for _, goal in ipairs(goals) do
            Animation.delayedStart(startDelay, Level.levelClearAnim(goalAnimTime, level, goal))
        end
        Animation.delayedStart(startDelay + goalAnimTime, Level.levelEndAnim(endAnimTime))

        level.goalPlaying = true
    end
end

function Level.levelClearAnim(duration, level, goal)
    return Animation.new(duration, function(self, progress)
        local progress = easeInOutCubic(progress)
        local scale =
            math.max(state.width, state.height) * progress * 2
        local angle = progress * 2 * math.pi
        love.graphics.setColor(0.98, 0.875, 0.678)
        drawRotatedRectangle("fill",
            (goal.x + 0.5) * state.cellSize + (state.width - level.width * state.cellSize) / 2,
            (goal.y + 0.5) * state.cellSize + (state.height - level.height * state.cellSize) / 2,
            scale, scale, angle)
        love.graphics.setColor(1, 1, 1)
    end)
end

function Level.levelEndAnim(duration)
    return Animation.new(duration, function(self, progress)
        local progress = easeOutCubic(progress)
        local scale = math.max(state.width, state.height)
        love.graphics.setColor(0.98, 0.875, 0.678, 1 - progress)
        drawRotatedRectangle("fill", state.width / 2, state.height / 2, scale, scale, 0)
        love.graphics.setColor(1, 1, 1)
    end, function()
        state.mode = Mode.Menu
        forceUpdateGraphics()
    end)
end
