---@class LQRecord
LQRecord = {
    dataValues = {}
    __isNewRecord = false,
}

---@param values table<string, any>
---@param data { isNew?: boolean }
---@return LQRecord
function LQRecord.__createInstance(values, data)
    local self = {}

    setmetatable(self, {
        __index = LQRecord,
    })

    self.dataValues = values
    self.__isNewRecord = data.isNew or false

    -- fivem does not support metatable binding in cross resource exports
    for k, v in pairs(LQRecord) do
        self[k] = v
    end

    return self
end

---@param options { cached?: boolean }
---@return table
function LQRecord:get(options)
    -- if not options.cached do reselect

    return self.dataValues
end

function LQRecord:getDataValue(key)
    -- get stored
    return self.dataValues[key]
end

---@param values table<string, any>
---@param value any
---@overload fun(key: string, value: any)
function LQRecord:set(values, value)
    if type(values) == 'string' then
        self.dataValues[values] = value
    else
        for k, v in pairs(values) do
            self.dataValues[k] = v
        end
    end
end

function LQRecord:save()
    if (self.__isNewRecord) then
        -- MySQL:query(LQInternal.joinSQLFragments({

        -- }))
    else
    end
end

function LQRecord:destroy()

end

function LQRecord:update(values)
    self:set(values)
    self:save()
end
