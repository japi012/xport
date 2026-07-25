Menu = {}

local Animation = require "anim"
require "level"

Menu.scrollBarWidth = 20

function Menu.new(size, levelRects, scrollBars, debugDraw)
    return {
        size = size,
        levelRects = levelRects,
        scrollBars = scrollBars,
        debugDraw = debugDraw,
        marginX = 0,
        marginY = 0,
        pixelSize = 0,
    }
end

function Menu.onResize(menu)
    menu.pixelSize = math.min(state.width, state.height)
    menu.marginX = (state.width - menu.pixelSize) / 2
    menu.marginY = (state.height - menu.pixelSize) / 2
end

local function pointInRect(x, y, rx, ry, rw, rh)
    return x >= rx and y >= ry and x <= rx + rw and y <= ry + rh
end

local function hover()
    local cursor = love.mouse.getCursor()
    if cursor == nil or cursor:getType() ~= "hand" then
        love.mouse.setCursor(globals.mouseCursors.hand)
    end
end

local function noHover()
    local cursor = love.mouse.getCursor()
    if cursor == nil or cursor:getType() ~= "arrow" then
        love.mouse.setCursor(globals.mouseCursors.arrow)
    end
end

function Menu.update(menu, dt)
    local mx, my = love.mouse.getPosition()
    -- for _, scrollBar in menu.scrollBars do

    -- end
    local hovering = false

    for _, scrollBar in ipairs(menu.scrollBars) do
        if not love.mouse.isDown(1) then scrollBar.sliding = false end

        local realX = menu.marginX + (scrollBar.x / menu.size) * menu.pixelSize
        local realY = menu.marginY + (scrollBar.y / menu.size) * menu.pixelSize
        local realW = (Menu.scrollBarWidth / menu.size) * menu.pixelSize
        local realH = (scrollBar.h / menu.size) * menu.pixelSize

        if pointInRect(mx, my, realX, realY, realW, realH) then
            hover()

            if love.mouse.isDown(1) then
                scrollBar.sliding = true
            end
        end

        if scrollBar.sliding then
            local value = 1 - math.max(math.min((my - realY) / realH, 1), 0)
            scrollBar.value = value
            hovering = true
            scrollBar.connect(value)
        else
            hovering = false
        end
    end

    for _, rect in ipairs(menu.levelRects) do
        local realX = menu.marginX + (rect.x / menu.size) * menu.pixelSize
        local realY = menu.marginY + (rect.y / menu.size) * menu.pixelSize
        local realW = (rect.w / menu.size) * menu.pixelSize
        local realH = (rect.h / menu.size) * menu.pixelSize

        if pointInRect(mx, my, realX, realY, realW, realH) then
            hover()
            hovering = true
            rect.hovering = true

            if love.mouse.isDown(1) and not rect.clicked then
                rect.clicked = true
                Animation.start(Menu.levelStartAnim(rect, realX, realY, realW, realH))
            end
        else
            rect.hovering = false
        end
    end

    if not hovering then noHover() end
end

function Menu.draw(menu)
    love.graphics.setBackgroundColor(0, 0, 0)
    if menu.debugDraw then
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", menu.marginX, menu.marginY, menu.pixelSize, menu.pixelSize)

        for _, rect in ipairs(menu.levelRects) do
            local realX = menu.marginX + (rect.x / menu.size) * menu.pixelSize
            local realY = menu.marginY + (rect.y / menu.size) * menu.pixelSize
            local realW = (rect.w / menu.size) * menu.pixelSize
            local realH = (rect.h / menu.size) * menu.pixelSize

            if rect.hovering and state.levelClears[rect.levelIndex] then
                love.graphics.setColor(0.5, 0, 0)
            elseif rect.hovering then
                love.graphics.setColor(1, 0, 0)
            elseif state.levelClears[rect.levelIndex] then
                love.graphics.setColor(0.5, 0.5, 0.5)
            else
                love.graphics.setColor(1, 1, 1)
            end

            love.graphics.rectangle("fill", realX, realY, realW, realH)
        end
        love.graphics.setColor(1, 1, 1)

        -- local padding = menu.pixelSize / 50
        -- local fontHeight = globals.titleFont:getHeight()
        -- love.graphics.print("XPORT by TEAM NOMCAT", globals.titleFont,
        --     padding + menu.marginX, state.height - padding + menu.marginY - fontHeight / 2)
    end

    for _, scrollBar in ipairs(menu.scrollBars) do
        local realX = menu.marginX + (scrollBar.x / menu.size) * menu.pixelSize
        local realY = menu.marginY + (scrollBar.y / menu.size) * menu.pixelSize
        local realW = (Menu.scrollBarWidth / menu.size) * menu.pixelSize
        local realH = (scrollBar.h / menu.size) * menu.pixelSize

        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.rectangle("fill", realX, realY, realW, realH)

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", realX, realY + (1 - scrollBar.value) * (realH- realW), realW, realW)
    end
    love.graphics.setColor(1, 1, 1)
end

function Menu.levelStartAnim(rect, realX, realY, realW, realH)
    return Animation.chained(
        Animation.new(
            1.5, function(self, progress)
                local progress = easeInOutCubic(progress)
                local scale =
                    math.max(state.width, state.height) * progress * 2
                local angle = progress * 2 * math.pi
                love.graphics.setColor(0.98, 0.875, 0.678)
                drawRotatedRectangle("fill",
                    realX + realW / 2, realY + realH / 2,
                    scale, scale, angle)
                love.graphics.setColor(1, 1, 1)
            end
        ),
        Animation.new(
            0.5, function(self, progress)
                local progress = easeOutCubic(progress)
                local scale = math.max(state.width, state.height)
                love.graphics.setColor(0.98, 0.875, 0.678, 1 - progress)
                drawRotatedRectangle("fill", state.width / 2, state.height / 2, scale, scale, 0)
                love.graphics.setColor(1, 1, 1)
            end, function()
                noHover()
                state.levelIndex = rect.levelIndex
                state.level = Level.fromGrid(globals.levels[state.levelIndex])
                state.mode = Mode.Gameplay
                rect.clicked = false
                rect.hovering = false
            end
        )
    )
end

return Menu
