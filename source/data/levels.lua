if Levels ~= nil then return Levels end

local love = require "love"
require "source.data.locale"

Levels = {
    order = {}, -- Levels flattened in order (globals.levels)
    plain = {}, -- Levels flattened e.g. 'demoworld/1-dejavu'
    areas = {}  -- Levels organized by areas e.g. 'demoworld.levels['1-dejavu']'
}

function Levels.getDimensionFromGrid(grid)
    local yesyes = string.split(grid, '\n')
    return #(yesyes[1]), #yesyes
end

function Levels.encodeLevelFromFile(id, content)
    local rawData = string.split(content, '\n\n')
    local thingy = string.find(rawData[1], '\n') -- well-named variable

    if #rawData < 2 then
        debugPrint("[LEVELS] Couldn't encode", id .. ", so we ignore it")
        return nil
    end

    -- debugPrint("[LEVELS] Decoding, with raw content: ", content)
    -- debugPrint("[LEVELS] Decoding, with raw data: ", rawData)
    local result = {
        title = string.sub(rawData[1], 0, thingy and (thingy - 1) or #rawData[1]),
        subtitle = thingy and string.sub(rawData[1], thingy + 1) or '',
        -- title = string.sub(rawData[1], 0, thingy or #rawData[1]),
        -- subtitle = thingy and string.sub(rawData[1], thingy + 1) or '',
        grid = {
            rawData[2]
        }
    }

    local curIndex = 3
    local cX, cY = Levels.getDimensionFromGrid(rawData[2])
    -- debugPrint("[LEVELS] Grid dimensions:", cX, cY);

    while true do
        if (curIndex) > #rawData then break end
        local gridCheck = rawData[curIndex]
        -- debugPrint("[LEVELS] Checking grid", curIndex);

        local cX2, cY2 = Levels.getDimensionFromGrid(gridCheck)
        -- debugPrint("[LEVELS] Comparing grid dimensions:", cX2, cY2);
        if cX ~= cX2 or cY ~= cY2 or #rawData[2] ~= #gridCheck then break end

        result.grid[#result.grid + 1] = gridCheck
        curIndex = curIndex + 1
    end

    if rawData[curIndex] ~= nil then
        local thingy2 = string.find(rawData[curIndex], '\n') -- well-named variable 2
        result.palette = string.sub(rawData[curIndex], 0, thingy2 - 1)
        result.musicID = string.sub(rawData[curIndex], thingy2 + 1)
    else
        result.musicID = 'undefined'
    end

    -- Insert save retrieval logic here. Someday.
    result.isCleared = false;

    -- debugPrint("[LEVELS] Decoding, with resultant: ", result)
    return result
end

function Levels.loadData()
    globals.levels = {}
    Levels.order = globals.levels

    for k, _ in pairs(Levels.order) do Levels.order[k] = nil end
    for k, _ in pairs(Levels.plain) do Levels.plain[k] = nil end
    for k, _ in pairs(Levels.areas) do Levels.areas[k] = nil end

    local areaFolders = love.filesystem.getDirectoryItems("areas")
    debugPrint("[LEVELS]", areaFolders)

    for _, areakey in ipairs(areaFolders) do
        local areadir = "areas/" .. areakey
        debugPrint('[LEVELS] Parsing lobby "' .. areakey .. '/lobby"')
        Levels.areas[areakey] = {
            lobby = Levels.encodeLevelFromFile('lobby', love.filesystem.read(areadir .. '/lobby.xlvl')),
            levels = {}
        }

        local levelfiles = love.filesystem.getDirectoryItems(areadir .. '/levels')
        table.sort(levelfiles, function(a, b)
            local numIndex1 = string.find(a, "([0-9]+)")
            local numIndex2 = string.find(b, "([0-9]+)")

            if numIndex1 ~= nil and numIndex2 ~= nil and numIndex1 ~= numIndex2 then
                return numIndex1 < numIndex2
            end

            local isNum1, isNum2 = tonumber(string.match(a, "([0-9]+)")), tonumber(string.match(b, "([0-9]+)"))
            if isNum1 ~= nil and isNum2 == nil then return true end
            if isNum2 ~= nil and isNum1 == nil then return false end
            if isNum1 ~= isNum2 then
                return isNum1 < isNum2
            end

            return a < b
        end)

        for _, levelfile in ipairs(levelfiles) do
            local levelID = string.gsub(levelfile, ".xlvl", "")
            local fileContents = love.filesystem.read(areadir .. '/levels/' .. levelfile);

            debugPrint('[LEVELS] Parsing level "'.. areakey .. '/' .. levelID .. '"')
            local resultLevel = Levels.encodeLevelFromFile(levelID, fileContents)

            Levels.order[#Levels.order + 1] = resultLevel;
            Levels.plain[areakey .. '/' .. levelID] = resultLevel;
            Levels.areas[areakey].levels[levelID] = resultLevel;
            Levels.areas[areakey].levels[#Levels.areas[areakey].levels + 1] = resultLevel;

            -- depthPrint(2, '[LEVELS] Result:', Levels.areas)
        end
    end
end

function Levels.localizeText(text)
end

return Levels
