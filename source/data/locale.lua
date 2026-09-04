if Locale ~= nil then return Locale end

local love = require "love"
Locale = {
    fallback = "en-US",
    current = "en-US",

    mappings = {}
}

function Locale.loadMappings()
    for k, _ in pairs(Locale.mappings) do Locale.mappings[k] = nil end
    local translationFiles = love.filesystem.getDirectoryItems("translations")

    for _, transfile in ipairs(translationFiles) do
        local lang = string.gsub(transfile, ".xln", "")
        local result = {}

        for line in love.filesystem.lines("translations/" .. transfile) do
            if (string.sub(line, 1, 2) ~= '//') then
                local lines = string.split(line, " \\: ")
                if #lines <= 2 then
                    result[lines[1]] = lines[2] or ''
                end
            end
        end

        Locale.mappings[lang] = result
    end
end

-- We should make sure to clear this when switching languages
-- or when it starts to cache too much
local localizeCache = {}
function Locale.localizeText(text)
    if localizeCache[text] then return localizeCache[text] end

    for key, string in pairs(Locale.mappings[Locale.current]) do
        text = string.gsub(text, key, string)
    end

    for key, string in pairs(Locale.mappings[Locale.fallback]) do
        text = string.gsub(text, key, string)
    end

    localizeCache[text] = text
    return text
end

return Locale
