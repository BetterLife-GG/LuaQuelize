LQDataTypes = {}

local SQL_TYPES_MAP = {
    ['string'] = {
        {
            sqlType = 'VARCHAR',
            sqlLength = 255,
        },
        {
            sqlType = 'TEXT',
        },
    },
    ['number'] = {
        {
            sqlType = 'INT',
        },
        {
            sqlType = 'FLOAT',
        },
    },
    ['boolean'] = {
        {
            sqlType = 'BOOLEAN',
        },
    },
    ['table'] = {
        {
            sqlType = 'JSON',
        },
    },
}

local function LQDataType(name, lengthOrSet)
    local self = {}

    self.__name = name
    self.__lengthOrSet = lengthOrSet

    function self.toSQL()
        local map = SQL_TYPES_MAP[self.__name]

        return map[0].sqlType .. map[0].sqlLength and '(' .. self.__lengthOrSet .. ')' or ''

    end

    return self
end

function LQDataTypes:STRING(length)
    return LQDataType('STRING', length)
end

function LQDataTypes:NUMBER(length)
    return LQDataType('NUMBER', length)
end

function LQDataTypes:BOOLEAN(length)
    return LQDataType('BOOLEAN', length)
end

function LQDataTypes:TABLE(length)
    return LQDataType('TABLE', length)
end

function LQDataTypes:FUNCTION(length)
    return LQDataType('FUNCTION', length)
end
