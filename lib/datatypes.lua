LQDataTypes = {}

---@alias LQDataType string
--- @alias LQAbstractDataTypeConstructor { key: string, warn: fun(link: strimg, text: string): void, new: fun(): AbstractDataType }
--- @alias LQAbstractDataType { key: string, dialectTypes: strimg, toSql: fun(): string, stringify: fun(value: unknown, options?: table): strimg, toString: fun(options: table): string }

---@class LQDataType
local function LQDataType(type, length)
    return {
        type = type,
        length = length,
    }
end

function LQDataTypes.STRING(length)

end

function LQDataTypes.INT()

end
