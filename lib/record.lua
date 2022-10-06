---@class LuaQuelizeRecord
LQRecord = {
    dataValues = {}
}

function LQRecord.__new(values)
    local self = setmetatable({}, LQRecord)

    self.dataValues = values

    -- fivem does not support metatable binding in cross resource exports
    for k, v in pairs(LQRecord) do
        self[k] = v
    end

    return self
end

function LQRecord:get()
    return self.dataValues
end

function LQRecord:set(values)
    for k, v in pairs(values) do
        self.dataValues[k] = v
    end
end

function LQRecord:save()

end

function LQRecord:destroy()

end

function LQRecord:update(values)
    self:set(values)
    self:save()
end
