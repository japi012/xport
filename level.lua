local love = require "love"
local Cell = require "cell"
local Sounds = require "sounds"
local Palette = require "palette"
local Animation = require "anim"
local Particle = require "particles"

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
    Teleport = {}, -- (i think this could just be part of Move but also maybe it might be useful to separate it)
    -- future miney here: yeah it's definitely better to separate it
    OriginMove = {},
    Reset = {}
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

function Level.new(height, width, cells, palette, title, text)
    local result = {
        height = height,
        width = width,
        cells = cells,
        palette = palette or Palette.defaultList(),
        winning = false,
        animationTime = 0,
        layers = {},
        eventLog = {},
        goalPlaying = false,
        title = title,
        text = text
    }

    table.sort(result.cells, function(a, b)
        return a.cell.layer < b.cell.layer
    end)

    return result
end

function Level.fromGrid(grid, paletteIndex)
    local layer1, layer2, layer3, title, text = grid[1], grid[2], grid[3], grid[4], grid[5]
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
    return Level.new(y, x, cells, globals.paletteLists[paletteIndex], title, text)
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

    if level.title then
        local padding = state.cellSize / 2
        love.graphics.print(level.title, globals.levelFont, padding, padding)
    end

    if level.text then
        local padding = state.cellSize / 2
        local fontWidth = globals.tutorialFont:getWidth(level.text)
        local fontHeight = globals.tutorialFont:getHeight()
        love.graphics.print(level.text, globals.tutorialFont, state.width / 2 - fontWidth / 2, state.height - padding - fontHeight)
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
                local origin = allWithPredicate(level.cells, function (cell)
                    return cell.cell == Cell.Origin and cell.region == timer.region
                end)[1] -- if this ever throws an index error then we quit gamedev forever

                local nx, ny = applyDirection(level, origin, direction)
                if not (nx and ny) then movable = false end
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

    local zerotimers = allWithPredicate(level.cells, function(cell)
        return cell.cell == Cell.Timer and cell.val == 0 and cell.default_val ~= 0
    end)
    for _, timer in ipairs(zerotimers) do
        -- print("here", timer.region)
        local origin = allWithPredicate(level.cells, function (cell)
            return cell.cell == Cell.Origin and cell.region == timer.region
        end)[1] -- if this ever throws an index error then we quit gamedev forever
        local boxes = allWithPredicate(level.cells, function (cell)
            return (cell.cell == Cell.Box or cell.cell == Cell.Player) and cell.region == timer.region
        end)
        local blocked = false
        for _, box in ipairs(boxes) do
            if not isInBounds(level, box.x - timer.x + origin.x, box.y - timer.y + origin.y) then
                -- print("oops out of bounds")
                blocked = true
                break -- this one is my fault though
            end

            local targets = findCells(level.cells, box.x - timer.x + origin.x, box.y - timer.y + origin.y)
            local shouldBreak = false
            for _, target in ipairs(targets) do
                if target.cell == Cell.Player or target.cell == Cell.Wall or (target.cell == Cell.Box and target.region ~= timer.region) then
                    blocked = true
                    shouldBreak = true
                    break
                end
            end

            if shouldBreak then
                break
            end
        end

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
        else
            for _, box in ipairs(boxes) do
                Animation.start(Particle.teleFailParticle(box.x - timer.x + origin.x, box.y - timer.y + origin.y, level, box))
            end
        end
    end
	return events
end

local function secondPassEvents(level, teleports)
    local occupied = {}
    local bannedregions = {}
    for _, event in ipairs(teleports) do
        if occupied[tostring(event.to_x) .. tostring(event.to_y)] and occupied[tostring(event.to_x) .. tostring(event.to_y)] ~= event.timer.region then
            bannedregions[event.timer.region] = true
            bannedregions[occupied[tostring(event.to_x) .. tostring(event.to_y)]] = true
        else
            occupied[tostring(event.to_x) .. tostring(event.to_y)] = event.timer.region
        end
    end

    local unbannedevents = {}
    for _, event in ipairs(teleports) do
        if not bannedregions[event.timer.region] then
            table.insert(unbannedevents, event)
        end
    end
    return unbannedevents
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

    Sounds.undo:play()
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
        elseif event.type == Event.Reset then
            event.cell.x = event.from_x
            event.cell.y = event.from_y
            event.cell.val = event.from_val
        end
    end

    return level.eventLog
end

local function runEvent(level, event)
    if event.type == Event.Move then
        if event.cell.cell == Cell.Player then
            Animation.start(Particle.playerParticle(event.cell.x, event.cell.y, level))
        end
        event.cell.x = event.to_x
        event.cell.y = event.to_y
    elseif event.type == Event.TimerChange then
        event.cell.val = event.to_val
    elseif event.type == Event.Teleport then
        Animation.start(Particle.teleParticle(event.cell.x, event.cell.y, level, event.cell))
        event.cell.x = event.to_x
        event.cell.y = event.to_y
        event.timer.val = event.timer.default_val
    elseif event.type == Event.OriginMove then
        event.cell.x = event.to_x
        event.cell.y = event.to_y
    elseif event.type == Event.Reset then
        Cell.startMoveAnim(event.cell)
        event.cell.x = event.cell.initial_x
        event.cell.y = event.cell.initial_y
        event.cell.val = event.cell.default_val
    end
end

function Level.turn(level, key)
    if level.goalPlaying then return end

    if key == "escape" then
        if (globals.entered_level_six ~= 6) then
            state.mode = Mode.Menu
            Animation.start(Level.fadeFromBlack(2))
            Music.play(Music.menu, 0.2)
        else
            state.levelIndex = -6
            globals.entered_level_six = 6.66
            state.level = Level.fromGrid(globals.man, state.levelIndex)
            Animation.start(Level.fadeFromBlack(1))
            Music.play(Music.secret, 1)
        end
        Sounds.levelRestart:play()
        forceUpdateGraphics()
        return
    end

    local direction
    if key == "up"          or key == "w" then
        direction = Direction.Up
    elseif key == "down"    or key == "s" then
        direction = Direction.Down
    elseif key == "left"    or key == "a" then
        direction = Direction.Left
    elseif key == "right"   or key == "d" then
        direction = Direction.Right
    else
        if key == "z" then
            runUndo(level)
        elseif key == "r" then
            if (#level.eventLog == 0) or (level.eventLog[#level.eventLog][1].type == Event.Reset) then return end

            Sounds.levelRestart:play()
            local events = {}

            for _, cell in ipairs(level.cells) do
                local reset = {
                    type = Event.Reset,
                    cell = cell,
                    from_x = cell.x,
                    from_y = cell.y,
                    from_val = cell.val
                }

                runEvent(level, reset)
                table.insert(events, reset)
            end

            table.insert(level.eventLog, events)
        end
        return
    end

    local events = moveCells(level, 'P', direction)
    if #events > 0 then
        Sounds.move:play()
    else
        Sounds.moveFail:play()
    end

    for _, event in ipairs(events) do
        runEvent(level, event)
    end

    local teleports = {}
    while true do
        local teleportbatch = handleTeleports(level, direction) -- also includes origin moves
        teleportbatch = secondPassEvents(level, teleportbatch)

        if #teleportbatch == 0 then break end
        for _, teleport in ipairs(teleportbatch) do
            runEvent(level, teleport)
        end
        append(teleports, teleportbatch)
    end

    if #teleports > 0 then Sounds.teleport:play() end

    append(teleports, events) -- very important that teleports get undone before moves
    if #teleports > 0 then table.insert(level.eventLog, teleports) end

    if isWinning(level) then
        Sounds.levelComplete:play()
        state.levelClears[state.levelIndex] = true

        -- print("-----")
        -- print(state.currentMusic.filename)
        -- print("-----")

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
        love.graphics.setColor(255 / 255, 193 / 255, 247 / 255)
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
        love.graphics.setColor(255 / 255, 193 / 255, 247 / 255, 1 - progress)
        drawRotatedRectangle("fill", state.width / 2, state.height / 2, scale, scale, 0)
        love.graphics.setColor(1, 1, 1)
    end, function()
        state.mode = Mode.Menu
        forceUpdateGraphics()
        Music.play(Music.menu, 0.5)
    end)
end

function Level.fadeFromBlack(duration)
    return Animation.new(duration, function(self, progress)
        love.graphics.setColor(0, 0, 0, 1 - easeOutExpo(progress))
        drawRotatedRectangle("fill", state.width / 2, state.height / 2, state.width, state.height, 0)
        love.graphics.setColor(1, 1, 1)
    end)
end
