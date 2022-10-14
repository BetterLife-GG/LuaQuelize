LQDataTypes = {}

local TypeFormat = {
    number = '\'',
    string = '',
}

---@param dataType string
---@param length number?
---@class LQDataType
local function LQDataType(dataType, length)
    local self = {
        type = dataType,
        length = length,
    }

    self.toSql = function()
        return self.type .. (self.length and '(' .. self.length .. ')' or '')
    end

    self.formatValue = function(value)
        return TypeFormat[self.luaType] .. value .. TypeFormat[self.luaType]
    end

    return self
end

function LQDataTypes.dataToSQL(value)
    local typeOf = type(value)
    if (typeOf == 'string') then
        return '\'' .. value .. '\''
    elseif (typeOf == 'number') then
        return value
    elseif (typeOf == "table") then
        return '`' .. json.encode(value) .. '`'
    end
end

-- INTEGER
function LQDataTypes.TINYINT(length)
    return LQDataType("TINYINT", length)
end

function LQDataTypes.SMALLINT(length)
    return LQDataType("SMALLINT", length)
end

function LQDataTypes.MEDIUMINT(length)
    return LQDataType("MEDIUMINT", length)
end

function LQDataTypes.INT(length)
    return LQDataType("INT", length)
end

function LQDataTypes.BIGINT(length)
    return LQDataType("BIGINT", length)
end

function LQDataTypes.BIT(length)
    return LQDataType("BIT", length)
end

-- REAL
function LQDataTypes.FLOAT()
    return LQDataType("FLOAT")
end

function LQDataTypes.DOUBLE()
    return LQDataType("DOUBLE")
end

function LQDataTypes.DECIMAL()
    return LQDataType("DECIMAL")
end

-- TEXT
function LQDataTypes.STRING(length)
    return LQDataType("VARCHAR", length)
end

function LQDataTypes.VARCHAR(length)
    return LQDataType("VARCHAR", length)
end

function LQDataTypes.CHAR(length)
    return LQDataType("CHAR", length)
end

function LQDataTypes.TINYTEXT()
    return LQDataType("TINYTEXT")
end

function LQDataTypes.TEXT(length)
    return LQDataType("TEXT", length)
end

function LQDataTypes.JSON()
    return LQDataType("JSON")
end
