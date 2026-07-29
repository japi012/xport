local love = require "love"

-- BASIC UTIL FUNCTIONS

function elem(t, item)
    for _, i in ipairs(t) do
        if i == item then return true end
    end
    return false
end

function indexOf(t, item)
    for k, i in ipairs(t) do
        if i == item then return k end
    end
    return -1
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

-- borrowed from https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..dump(k)..'"' end
         s = s .. '['..dump(k)..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

-- SPECIAL ENUM FUNCTIONS
Enum = {}

function Enum.withID(enumID)
    return { id=enumID }
end

-- GRAPHICS

-- ripped from the wiki lmao (except now it draws and rotates about the center)
function drawRotatedRectangle(mode, x, y, width, height, angle)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle or 0)
    love.graphics.rectangle(mode, -width/2, -height/2, width, height)
    love.graphics.pop()
end

-- not ripped from the wiki lmao
function drawCenteredRectangle(mode, x, y, width, height)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rectangle(mode, -width/2, -height/2, width, height)
    love.graphics.pop()
end

function cosh(x)
    return (math.exp(x) + math.exp(-x)) / 2
end
