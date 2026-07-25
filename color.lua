if Color ~= nil then return Color end

Color = {}

local function hsvHelpers(r, g, b)
    local cmax = math.max(r, g, b)
    local cmin = math.min(r, g, b)
    return cmax, cmin, cmax - cmin
end

local RGB_METATABLE
local HSV_METATABLE

RGB_METATABLE = {
    __index = function (t, k)
        if k == 0 then return t.r end
        if k == 1 then return t.g end
        if k == 2 then return t.b end

        -- HUE
        if k == "h" then
            local cmax, _, diff = hsvHelpers(t.r, t.g, t.b);
            if cmax == t.r then return (60 * ((t.g - t.b) / diff) + 360) % 360 end
            if cmax == t.g then return (60 * ((t.b - t.r) / diff) + 120) % 360 end
            if cmax == t.b then return (60 * ((t.r - t.g) / diff) + 240) end
        end

        -- SATURATION
        if k == "s" then
            local cmax, _, diff = hsvHelpers(t.r, t.g, t.b);
            if cmax == 0 then return 0 end
            return (diff / cmax)
        end

        -- VALUE
        if k == "v" then
            return math.max(t.r, t.g, t.b)
        end

        return nil
    end,
    __newindex = function (t, k, v)
            if k == 0 then t.r = v
        elseif k == 1 then t.g = v
        elseif k == 2 then t.b = v
        elseif k == "h" or k == "s" or k == "v" then
            local h, s, v = t.h, t.s, t.v
            t.r, t.g, t.b = nil, nil, nil

            setmetatable(t, HSV_METATABLE)
            t.r, t.g, t.b = h, s, v
            t[k] = v
        end
    end,
    __tostring = function(t)
        return "rgb(" .. t.r .. "," .. t.g .. "," .. t.b .. ")"
    end,
    __call = function (t)
        return t.r, t.g, t.b
    end
}

HSV_METATABLE = {
    __index = function(t, k)
        if k == "r" or k == 0 then return table.pack(Color.convertFromHSV(t.h, t.s, t.v))[1] end
        if k == "g" or k == 1 then return table.pack(Color.convertFromHSV(t.h, t.s, t.v))[2] end
        if k == "b" or k == 2 then return table.pack(Color.convertFromHSV(t.h, t.s, t.v))[3] end

        return nil
    end,
    __newindex = function (t, k, v)
        if k == "r" or k == "g" or k == "b"
        or k == 0 or k == 1 or k == 2 then
            local r, g, b = t.r, t.g, t.b
            t.h, t.s, t.v = nil, nil, nil

            setmetatable(t, RGB_METATABLE)
            t.r, t.g, t.b = r, g, b
            t[k] = v
        end
    end,
    __tostring = function(t)
        return "hsv(" .. t.h .. "," .. t.s .. "," .. t.v .. ")"
    end,
    __call = function (t)
        return Color.convertFromHSV(t.h, t.s, t.v)
    end
}

function Color.new(r, g, b)
    local result = setmetatable({r=r, g=g, b=b}, RGB_METATABLE)

    return result
end

function Color.from255(r, g, b)
    return Color.new(r / 255, g / 255, b / 255)
end

-- shamelessly stolen from https://github.com/iskolbin/lhsx/blob/master/hsx.lua (thank you)
function Color.convertFromHSV(h, s, v)
    local C = v * s
    local m = v - C
    local r, g, b = m, m, m

	if h == h then
		local h_ = h / 60
		local X = C * (1 - math.abs(h_ % 2 - 1))
		if     h < 60  then r, g, b = C, X, 0
		elseif h < 120 then r, g, b = X, C, 0
		elseif h < 180 then r, g, b = 0, C, X
		elseif h < 240 then r, g, b = 0, X, C
		elseif h < 300 then r, g, b = X, 0, C
		else                r, g, b = C, 0, X
		end
	end
	return r + m, g + m, b + m
end

function Color.fromHSV(h, s, v)
    local result = setmetatable({h=h, s=s, v=v}, HSV_METATABLE)
    return result
end

function Color.inRGB(col)
    if (getmetatable(col) == RGB_METATABLE) then
        return Color.new(col())
    else
        return Color.new(Color.convertFromHSV(col.h, col.s, col.v))
    end
end

function Color.inHSV(col)
    return Color.fromHSV(col.h, col.s, col.v)
end

function Color.lerp(from, to, i)
    return Color.new(lerp(from.r, to.r, i), lerp(from.g, to.g, i), lerp(from.b, to.b, i))
end

function Color.lerpHSV(from, to, i)
    print ("  from " .. tostring(from) .. " " .. tostring(Color.fromHSV(from.h, from.s, from.v)))
    print ("  from " .. tostring(Color.new(Color.fromHSV(from.h, from.s, from.v)())))
    print ("    to " .. tostring(to) .. " " .. tostring(Color.fromHSV(to.h, to.s, to.v)))
    print ("    to " .. tostring(Color.new(Color.fromHSV(to.h, to.s, to.v)())))

    local result = Color.fromHSV(lerp(from.h, to.h, i), lerp(from.s, to.s, i), lerp(from.v, to.v, i))
    print ("result " .. tostring(Color.new(result())) .. " " .. tostring(result))
    return result
end

col = Color.new
col255 = Color.from255
hsv = Color.fromHSV

return Color
