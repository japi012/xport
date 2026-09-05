local utf8 = require "utf8"

JSONParser = {}

local ESCAPES = {
    ["n"] = "\n",
    ["t"] = "\t",
    ["\\"] = "\\",
    ["\""] = "\"",
    ["\'"] = "\'",
}

function JSONParser.new(source)
    return {
        source = source,
        byte = 1,
        error = "",
    }
end

function JSONParser.char(parser)
    if parser.byte <= #parser.source then
        local rest = string.sub(parser.source, parser.byte)
        local offset = utf8.offset(rest, 2) - 1
        local character = string.sub(parser.source, parser.byte, parser.byte + offset - 1)
        return character, offset
    end
end

function JSONParser.next(parser)
    local c, offset = JSONParser.char(parser)
    if c == nil then return nil end

    parser.byte = parser.byte + offset
    return c
end

function JSONParser.skipWhitespace(parser)
    while (JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%s") do
        JSONParser.next(parser)
    end

    while string.sub(parser.source, parser.byte, parser.byte + 1) == "//" do
        JSONParser.next(parser)
        JSONParser.next(parser)
        while (JSONParser.char(parser)) ~= nil and (JSONParser.char(parser)) ~= "\n" do
            JSONParser.next(parser)
        end
        while (JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%s") do
            JSONParser.next(parser)
        end
    end
end

function JSONParser.error(parser, message)
    local line = 1
    local column = 1
    local pos = 1
    while pos < parser.byte do
        if string.sub(parser.source, pos, pos) == "\n" then
            line = line + 1
            column = 0
        end
        column = column + 1
        pos = pos + 1
    end
    parser.error = "[error at line " .. tostring(line) .. ", column " .. tostring(column) .. "]: " .. message
end

function JSONParser.peek(parser)
    JSONParser.skipWhitespace(parser)
    return JSONParser.char(parser)
end

function JSONParser.advance(parser)
    JSONParser.skipWhitespace(parser)
    return JSONParser.next(parser)
end

function JSONParser.onlyAdvanceIf(parser, c)
    local found = JSONParser.peek(parser)
    if found == nil then
        JSONParser.error(parser, "found end of file")
        return false
    end
    if found == c then
        JSONParser.next(parser)
        return true, true
    else
        return true, false
    end
end

function JSONParser.expectCharacter(parser, expect)
    local c = JSONParser.advance(parser)
    if c == expect then
        return true
    else
        local found = c or "end of file"
        JSONParser.error(parser, "expected " .. expect .. ", but found " .. found)
        return false
    end
end

function JSONParser.parse(source)
    local parser = JSONParser.new(source)
    local success, value = JSONParser.parseValue(parser)
    if success == false then
        value = parser.error
    end
    return value, success
end

function JSONParser.parseValue(parser)
    local c = JSONParser.advance(parser)
    if c == nil then
        JSONParser.error(parser, "expected value, but found end of file")
        return false
    end

    if string.match(c, "%a") then
        local success, value = JSONParser.parseAlphabeticLiteral(parser, c)
        return success, value
    elseif string.match(c, "[%d%.]") then
        local success, value = JSONParser.parseNumber(parser, c)
        return success, value
    elseif c == "\"" then
        local success, value = JSONParser.parseString(parser)
        return success, value
    elseif c == "{" then
        local success, value = JSONParser.parseObject(parser)
        return success, value
    elseif c == "[" then
        local success, value = JSONParser.parseArray(parser)
        return success, value
    end

    JSONParser.error(parser, "expected value, but found " .. c)
    return false
end

function JSONParser.parseNumber(parser, start)
    local s = start == "." and "0." or start

    while (JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%d") do
        local c = JSONParser.next(parser)
        s = s .. c
    end

    local _, dot = JSONParser.onlyAdvanceIf(parser, ".")

    if dot then
        s = s .. "."
        while (JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%d") do
            local c = JSONParser.next(parser)
            s = s .. c
        end
        if string.sub(s, #s, #s) == "." then
            s = s .. "0"
        end
    end

    return true, tonumber(s)
end

function JSONParser.parseAlphabeticLiteral(parser, start)
    local s = start

    while(JSONParser.char(parser)) ~= nil and string.match((JSONParser.char(parser)), "%a") do
        local c = JSONParser.next(parser)
        s = s .. c
    end

    if s == "null" then
        return true, nil
    elseif s == "true" then
        return true, true
    elseif s == "false" then
        return true, false
    end

    JSONParser.error(parser, "invalid alphabetic literal `" .. s .. "`")
    return false
end

function JSONParser.parseString(parser)
    local s = ""

    while (JSONParser.char(parser)) ~= nil and (JSONParser.char(parser)) ~= "\"" do
        local c = JSONParser.next(parser)
        if c == "\\" then
            local escape = JSONParser.next(parser)
            if escape == nil then
                JSONParser.error(parser, "no escape character")
                return false
            end

            c = ESCAPES[escape]
        end
        s = s .. c
    end

    JSONParser.next(parser)
    return true, s
end

function JSONParser.parseArray(parser)
    local array = {}
    local position = 1

    while true do
        local success, final = JSONParser.onlyAdvanceIf(parser, "]")
        if success == false then
            JSONParser.error(parser, "unclosed array")
            return false
        end
        if final then break end

        local success, value = JSONParser.parseValue(parser)
        if success == false then return false end

        if value ~= nil then
            array[position] = value
        end
        position = position + 1

        local success, comma = JSONParser.onlyAdvanceIf(parser, ",")
        if not comma then
            local success = JSONParser.expectCharacter(parser, "]")
            if success == false then
                JSONParser.error(parser, "unclosed array")
                return false
            end
            break
        end
    end
    return true, array
end

function JSONParser.parseObject(parser)
    local dict = {}

    while true do
        local success, finalBrace = JSONParser.onlyAdvanceIf(parser, "}")
        if success == false then
            JSONParser.error(parser, "unclosed object")
            return false
        end
        if finalBrace then break end

        local success, key = JSONParser.parseValue(parser)
        if success == false then return false end

        local success = JSONParser.expectCharacter(parser, ":")
        if success == false then return false end

        local success, value = JSONParser.parseValue(parser)
        if success == false then return false end

        if key ~= nil then
            dict[key] = value
        else
            JSONParser.error(parser, "attempt to use `null` as a object key")
            return false
        end

        local success, comma = JSONParser.onlyAdvanceIf(parser, ",")
        if not comma then
            local success = JSONParser.expectCharacter(parser, "}")
            if success == false then
                JSONParser.error(parser, "unclosed object")
                return false
            end
            break
        end
    end
    return true, dict
end
