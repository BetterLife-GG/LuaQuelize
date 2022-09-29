LQDataTypes = {}

--- @alias LQAbstractDataTypeConstructor { key: string, warn: fun(link: strimg, text: string): void, new: fun(): AbstractDataType }
--- @alias LQAbstractDataType { key: string, dialectTypes: strimg, toSql: fun(): string, stringify: fun(value: unknown, options?: table): strimg, toString: fun(options: table): string }


---@param dataType any
---@param length any
---@class LQDataType
local function LQDataType(dataType, length)
    local sqlType = {
        type = dataType,
        length = length
    }

    function sqlType.toSql()
        -- todo
        return 'VARCHAR(255)'
    end

    return sqlType
end

function LQDataTypes.STRING(length)
    return LQDataType("STRING", length)
end

function LQDataTypes.INT()
    return LQDataType("INT")
end
