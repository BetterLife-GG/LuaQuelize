-- https://github.dev/sequelize/sequelize/blob/main/src/dialects/mysql/query.js
function doesNotWantLeadingSpace(str)
    return string.match(str, "^[),;]") ~= nil
end

function doesNotWantTrailingSpace(str)
    return string.sub(str, -1) == '('
end

local function singleSpaceJoinHelper(parts, sepearator)
    local result = ''
    local skipNextLeadingSpace = true

    for i = 1, #parts do
        local part = parts[i]

        if (skipNextLeadingSpace or doesNotWantLeadingSpace(part)) then
            result = result .. part
        else
            result = result .. ' ' .. part
        end

        if sepearator and i < #parts then
            result = result .. sepearator
        end

        skipNextLeadingSpace = doesNotWantTrailingSpace(part)
    end

    return result
end

function LQInternal.joinSQLFragments(array, separator)
    if (#array) == 0 then return '' end

    local truthyArray = tableext.filter(array, function(x)
        return x ~= nil and x ~= ''
    end)

    local flatternedArray = tableext.map(truthyArray, function(fragment)
        if (type(fragment) == 'table' and tableext.isArray(fragment)) then
            return LQInternal.joinSQLFragments(fragment)
        end

        return fragment
    end)

    for _, fragment in pairs(flatternedArray) do
        if fragment and type(fragment) ~= 'string' then
            error(string.format('Tried to construct a SQL string with a non-string, non-falsy fragment (%s).', fragment))
        end
    end

    local trimmedArray = tableext.map(flatternedArray, function(fragment)
        return string.gsub(fragment, '^%s+', ''):gsub('%s+$', '')
    end)

    local nonEmptyStringArray = tableext.filter(trimmedArray, function(fragment)
        return fragment ~= ''
    end)

    return singleSpaceJoinHelper(nonEmptyStringArray, separator)
end

---comment
---@generic T
---@param ... T
function LQInternal.merge(...)
    local args = table.pack(...)
    local result = {}

    print(Debug.DumpTable(args))

    for _, obj in pairs(args) do
        if (type(_) == 'number') then
            for key, value in pairs(obj) do
                print(key, value)
                if (value ~= nil) then
                    if (not result[key]) then
                        result[key] = value
                    else
                        if (type(result[key]) == 'table' and type(value) == 'table') then
                            result[key] = LQInternal.merge(result[key], value)
                        elseif (tableext.isArray(value) and tableext.isArray(result[key])) then
                            result[key] = tableext.merge(value, result[key])
                        end
                    end
                end
            end
        end
    end

    return result
end
