local Color = require "color"
if Palette ~= nil then return Palette end

-- PALETTE HANDLING

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
        [Cell.Wall] = col255(43, 39, 81),
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
        background = col255(71, 38, 57),
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

return Palette
