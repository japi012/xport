local love = require "love"

-- BASIC UTIL FUNCTIONS

function elem(t, item)
    for _, i in ipairs(t) do
        if i == item then return true end
    end
    return false
end

function append(t1, t2)
    for _, i in ipairs(t2) do
        table.insert(t1, i)
    end
end

function lerp(from, to, i)
    return from + (to - from) * i
end

function clone(value)
    if type(value) == "table" then
        local newTable = {}
        for k, v in pairs(value) do
            newTable[k] = clone(v)
        end
        return newTable
    else
        return value
    end
end

function cloneUnitTables(value)
    if type(value) == "table" then
        local newTable = {}
        local isEmpty = true
        for k, v in pairs(value) do
            isEmpty = false
            newTable[k] = cloneUnitTables(v)
        end

        if isEmpty then
            return value
        else
            return newTable
        end
    else
        return value
    end
end

function easeOutExpo(x)
    return (x == 1) and 1 or (1 - 2^(-10 * x));
end

function allWithPredicate(list, predicate)
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

-- SPECIAL ENUM FUNCTIONS
Enum = {}

function Enum.withID(enumID)
    return { id=enumID }
end

-- COLOR FUNCTIONS

Color = {}

function Color.new(r, g, b)
    local result = setmetatable({r=r, g=g, b=b}, {
        __index = function (t, k)
            if k == 0 then return t.r end
            if k == 1 then return t.g end
            if k == 2 then return t.b end
            return nil
        end,
        __newindex = function (t, k, v)
                if k == 0 then t.r = v
            elseif k == 1 then t.g = v
            elseif k == 2 then t.b = v end
        end,
        __call = function (t)
            return t.r, t.g, t.b
        end
    })

    return result
end

function Color.from255(r, g, b)
    return Color.new(r / 255, g / 255, b / 255)
end

function Color.lerp(from, to, i)
    return Color.new(lerp(from.r, to.r, i), lerp(from.g, to.g, i), lerp(from.b, to.b, i))
end

col = Color.new
col255 = Color.from255

-- PALETTE HANDLING

Palette = {}

function Palette.gradient(color1, color2, steps)
    local result = {}
    for i=0, steps - 1 do
        table.insert(result, Color.lerp(color1, color2, i / steps))
    end

    return result
end

function Palette.manual(...)
    return {...}
end

function Palette.defaultList()
    return {
        [Cell.Player] = col(1, 1, 1),
        [Cell.Wall] = col(0.3, 0.3, 0.3),
        -- [Cell.Box] = Palette.gradient(col255(42.5, 42.5, 255), col255(255, 255, 42.5), 6),
        [Cell.Box] = Palette.gradient(col255(255, 117, 247), col255(153, 16, 128), 6),
        [Cell.Timer] = col(0.1, 0.1, 0.1),
        -- [Cell.Origin] = Palette.gradient(col255(42.5, 42.5, 255), col255(255, 255, 42.5), 6),
        [Cell.Origin] = Palette.gradient(col255(218, 80, 195), col255(103, 10, 80), 6),
        [Cell.Goal] = col(0.5, 0.5, 0.5),
        background = col255(255, 208, 249),
        levelFill = col255(79, 42, 85),
        levelStroke = col255(127, 34, 153),
    }
end

function Palette.list(list)
    local result = Palette.defaultList()
    for key, value in pairs(list) do
        result[key] = value
    end

    return result
end

-- GRAPHICS

-- ripped from the wiki lmao (except now it draws and rotates about the center)
function drawRotatedRectangle(mode, x, y, width, height, angle)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    love.graphics.rectangle(mode, -width/2, -height/2, width, height)
    love.graphics.pop()
end

function cosh(x)
    return (math.exp(x) + math.exp(-x)) / 2
end
