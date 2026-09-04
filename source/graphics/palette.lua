if Palette ~= nil then return Palette end
require "source.graphics.color"

Palette = {}

function Palette.gradientRGB(color1, color2, steps)
    local result = {}
    for i=0, steps - 1 do
        table.insert(result, Color.lerp(color1, color2, i / steps))
    end

    return result
end

function Palette.gradientHSV(color1, color2, steps)
    local result = {}
    for i=0, steps - 1 do
        table.insert(result, Color.new(Color.lerpHSV(color1, color2, i / steps)()))
    end

    return result
end

function Palette.defaultList()
    return {
        [Cell.Player] = col(1, 1, 1),
        [Cell.Wall] = col255(113, 39, 111),
        -- [Cell.Box] = Palette.gradient(col255(42.5, 42.5, 255), col255(255, 255, 42.5), 6),
        [Cell.Box] = Palette.gradientHSV(col255(255, 117, 247), col255(153, 16, 128), 6),
        [Cell.Timer] = {
            default = col(1, 1, 1),
            player = col(0, 0, 0)
        },
        -- [Cell.Origin] = Palette.gradient(col255(42.5, 42.5, 255), col255(255, 255, 42.5), 6),
        [Cell.Origin] = {
            default = Palette.gradientHSV(col255(218, 80, 195), col255(103, 10, 80), 6),
            player = col(1, 1, 1)
        },
        [Cell.Goal] = col(1, 1, 1),
        [Cell.Tree] = col(1, 1, 1),
        background = col255(51, 28, 47),
        levelFill = col255(69, 32, 75),
        levelStroke = col255(127, 34, 153),
        levelTransition = col255(255, 193, 247)
    }
end

-- function Palette.list(list)
--     local result = Palette.defaultList()
--     for key, value in pairs(list) do
--         if (type(value) == 'table') and (value.r == nil) and (value[1] == nil) then
--             for key2, value2 in pairs(list) do
--                 value[key2] = value2
--             end
--         else
--             result[key] = value
--         end
--     end
--
--     return result
-- end

-- "fixed" version compromised some things like gradients so we'll just use the old one for now

function Palette.list(list)
    local result = Palette.defaultList()
    for key, value in pairs(list) do
        result[key] = value
    end

    return result
end

return Palette
