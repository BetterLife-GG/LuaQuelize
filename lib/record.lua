---@class LQRecord
LQRecord = {
    ---@type number
    __id = 0,
    dataValues = {},
    __isNewRecord = false,
    ---@type LQModel
    model = nil,
}

local _id = 0

-- because data are not changing reactively, we need to store data in a separate global variable
local _LQRecord = {
    dataValues = {},
    newDataValues = {},
    __isNewRecord = {},
}

---@param values table<string, any>
---@param data { isNew?: boolean }
---@param model LQModel
---@return LQRecord
function LQRecord.__createInstance(values, data, model)
    local self = {}

    -- fivem does not support metatable binding in cross resource exports
    for k, v in pairs(LQRecord) do
        self[k] = v
    end

    self.__id = _id
    _id = _id + 1

    _LQRecord.dataValues[self.__id] = values
    _LQRecord.newDataValues[self.__id] = {}
    _LQRecord.__isNewRecord[self.__id] = data.isNew or false

    self.model = model

    setmetatable(self, {
        __index = LQRecord,
        __gc = function(self)
            local id = self.__id

            -- sometimes lua calls __gc too early
            -- Citizen.SetTimeout(500, function()
            --     _LQRecord.dataValues[id] = nil
            --     _LQRecord.newDataValues[id] = nil
            --     _LQRecord.__isNewRecord[id] = nil
            -- end)
        end
    })

    return self
end

---@param options { cached?: boolean }
---@return table
function LQRecord:get(options)
    options = options or {}

    if (not options.cached and not _LQRecord.__isNewRecord[self.__id]) then
        local result = MySQL:query(
            LQInternal.joinSQLFragments({
                'SELECT * FROM',
                '`' .. self.model.schema .. '`.`' .. self.model.modelName .. '`',
                'WHERE ' .. self.model.primaryKey .. ' = ' .. _LQRecord.dataValues[self.__id][self.model.primaryKey] .. '',
                'LIMIT 1'
            })
        )

        _LQRecord.dataValues[self.__id] = result[1]
    end


    return LQInternal.mergeDataValues(_LQRecord.dataValues[self.__id], _LQRecord.newDataValues[self.__id])
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
        _LQRecord.newDataValues[self.__id][values] = value
    else
        for k, v in pairs(values) do
            _LQRecord.newDataValues[self.__id][k] = v
        end
    end
end

function LQRecord:save()
    if (_LQRecord.__isNewRecord[self.__id]) then
        local query = LQInternal.joinSQLFragments({
            'INSERT INTO',
            '`' .. self.model.schema .. '`.`' .. self.model.modelName .. '`',
            '(' .. LQInternal.joinSQLFragments(tableext.map(LQInternal.objToArr(self:get()), function(v)
                return '`' .. v.key .. '`'
            end), ', ') .. ')',
            'VALUES',
            '(' .. LQInternal.joinSQLFragments(tableext.map(LQInternal.objToArr(self:get()), function(v)
                return '\'' .. v.value .. '\''
            end), ', ') .. ')'
        })

        local retval = MySQL:query(query)

        if (retval) then
            _LQRecord.__isNewRecord[self.__id] = false
            _LQRecord.dataValues[self.__id][self.model.primaryKey] = retval.insertId
        else
            print('Error while saving record, query: ' .. query)
        end
    else
        local query = LQInternal.joinSQLFragments({
            'UPDATE',
            '`' .. self.model.schema .. '`.`' .. self.model.modelName .. '`',
            'SET',
            LQInternal.joinSQLFragments(tableext.map(LQInternal.objToArr(_LQRecord.newDataValues[self.__id]), function(v)
                return '`' .. v.key .. '` = ' .. LQDataTypes.dataToSQL(v.value) .. ''
            end), ', '),
            'WHERE `' .. self.model.primaryKey .. '` = ' .. _LQRecord.dataValues[self.__id][self.model.primaryKey] .. '',
        })

        for k, v in pairs(_LQRecord.newDataValues[self.__id]) do
            _LQRecord.dataValues[self.__id][k] = v
        end

        _LQRecord.newDataValues[self.__id] = {}

        local retval = MySQL:query(query)
    end
end

function LQRecord:destroy()
    local query = LQInternal.joinSQLFragments({
        'DELETE FROM',
        '`' .. self.model.schema .. '`.`' .. self.model.modelName .. '`',
        'WHERE ' .. self.model.primaryKey .. ' = ' .. _LQRecord.dataValues[self.__id][self.model.primaryKey] .. '',
    })

    self = nil

    MySQL:query(query)
end

---@param values table<string, any>
---@param value any
---@overload fun(key: string, value: any)
function LQRecord:update(values, value)
    self:set(values, value)
    self:save()
end
