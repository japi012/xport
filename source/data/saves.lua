if Save ~= nil then return Save end

local love = require "love"
require "source.data.json"
Save = {
    prototype = {}
}

function Save.writeFile(data, path)
    love.filesystem.write(path, JSONEncoder.encode(data, '  '))
end

function Save.readFile(path, default)
    local thing = love.filesystem.read(path)
    local parsed, success = JSONParser.parse(thing)
    if success then
        return parsed
    else
        -- if default ~= nil then
        --     Save.writeFile(default, path)
        -- end
        return default
    end
end

return Save
