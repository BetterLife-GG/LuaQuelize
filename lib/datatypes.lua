LQDataTypes = {}

---@param dataType string
---@param length number?
---@class LQDataType
local function LQDataType(dataType, length)
    local self = {
        type = dataType,
        length = length
    }

    self.toSql = function()
        return self.type .. (self.length and '(' .. self.length .. ')' or '')
    end

    return self
end

function LQDataTypes.STRING(length)
    return LQDataType("VARCHAR", length)
end

function LQDataTypes.INT()
    return LQDataType("INT")
end
