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
            local lines = string.split(line, " \\: ")
            if #lines == 2 then
                result[lines[1]] = lines[2]
            end
        end

        Locale.mappings[lang] = result
    end
end

function Locale.localizeText(text)
    for key, string in pairs(Locale.mappings[Locale.current]) do
        text = string.gsub(text, key, string)
    end

    for key, string in pairs(Locale.mappings[Locale.fallback]) do
        text = string.gsub(text, key, string)
    end

    return text
end

return Locale
