---@class LQModel
LQModel = {
    -- ABSTRACT VALUES
    __ready = false,
    modelName = '',
    ---@type table<string, LQModelValue>
    attributes = {},
    ---@type LQModelOptions
    options = {},
    resource = {},
    schema = '',
}

_LQModel = {}

---@alias LQModelOptions { }
---@alias LQModelValue { type: LQDataType, unique?: boolean, allowNull?: boolean, primaryKey?: boolean, defult?: any, autoIncrement?: boolean, references?: string }

---@param modelName string
---@param attributes table<string, LQModelValue>
---@param options LQModelOptions
---@return LQModel
function LQModel.new(modelName, attributes, options, registrant)
    registrant = registrant or GetInvokingResource()
    attributes = attributes or {}
    ---@type LQModelOptions
    options = options or {}

    local self = self or {}

    -- populate slef (cross resource does not support metatables)
    for k, v in pairs(LQModel) do
        self[k] = v
    end

    self.LuaQuelize = LuaQuelize
    self.__ready = false
    self.modelName = modelName
    self.attributes = attributes
    self.options = options
    self.resource = registrant
    self.schema = self.LuaQuelize.config.schema

    -- set metatable
    setmetatable(self, {
        __index = LQModel,
    })

    return self
end

---@param attribute LQModelValue
function _LQModel:__attrToSQL(attribute)
    local template = LQInternal.joinSQLFragments({
        attribute.type.toSql(),
        attribute.unique and 'UNIQUE' or nil,
        attribute.allowNull and 'NULL' or 'NOT NULL',
        attribute.default and 'DEFAULT ' .. attribute.default or nil,
        attribute.references and 'REFERENCES ' .. attribute.references or nil,
        attribute.autoIncrement and 'AUTO_INCREMENT' or nil,
    })

    return template
end

---@param attrName string
---@param attribute LQModelValue
function LQModel:__alterTable(attrName, attribute, after)
    local query = LQInternal.joinSQLFragments({
        'ALTER TABLE',
        '`' .. self.schema .. '`.`' .. self.modelName .. '`',
        'ADD',
        '`' .. attrName .. '`',
        _LQModel:__attrToSQL(attribute),
        'AFTER `' .. after .. '`'
    })

    print(query)
    MySQL:query(query)
end

---Runs only inside coroutine, otherwise it will crash, call inside Citizen.CreateThread
---@param data { force?: boolean}
function LQModel:Sync(data)
    local exist = MySQL:query('SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = \'BASE TABLE\' AND TABLE_NAME = \'' .. self.modelName .. '\' AND TABLE_SCHEMA = \'' .. self.schema .. '\'')

    if #exist == 1 then
        -- check if table structure is the same
        local columns = MySQL:query('SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_KEY, COLUMN_DEFAULT, EXTRA FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = \'' .. self.modelName .. '\' AND TABLE_SCHEMA = \'' .. self.schema .. '\'')
        local foundCorrectColumns = {}

        -- todo removing columns
        for k, v in pairs(columns) do
            local existInSchema = self.attributes[v.COLUMN_NAME]
        end

        -- creating new columns
        ---@type { attrName: string, insertAfter: string }[]
        local columnsToAdd = {}


        ---Returns name of attribute that should be added after
        local function getAttrBefore(attr)
            local attrBefore = nil
            for k, v in pairs(self.attributes) do
                if v == attr then
                    return attrBefore
                end
                attrBefore = k
            end
            return attrBefore
        end

        for k, v in pairs(self.attributes) do
            local found = false
            for k2, v2 in pairs(columns) do
                if v2.COLUMN_NAME == k then
                    found = true
                    break
                end
            end

            if not found then
                table.insert(columnsToAdd, {
                    attrName = k,
                    insertAfter = getAttrBefore(v)
                })
            end
        end

        for k, v in pairs(columnsToAdd) do
            self:__alterTable(v.attrName, self.attributes[v.attrName], v.insertAfter)
        end

    else
        local primaryKey

        local attributes = tableext.map(self.attributes, function(attribute, key)
            local row = LQInternal.joinSQLFragments({
                key,
                LQModel:__attrToSQL(attribute)
            })

            if (attribute.primaryKey) then
                primaryKey = key
            end

            return row
        end)

        local attributesSQL = LQInternal.joinSQLFragments(tableext.entries(attributes), ', ')

        local tableSQL = LQInternal.joinSQLFragments({
            'CREATE TABLE ' .. self.schema .. '.' .. self.modelName,
            '(',
            attributesSQL,
            primaryKey and ', PRIMARY KEY (' .. primaryKey .. ')' or nil,
            ')',
        })

        MySQL:query(tableSQL, nil, self.schema)

        print('LQ: Table ' .. self.modelName .. ' created')
    end
end

---@param modelName string
---@param attributes table<string, LQModelValue>
---@param options LQModelOptions
---@return LQModel
function LQModel.Define(modelName, attributes, options)
    self = LQModel.new(modelName, attributes, options, GetInvokingResource())

    -- thread is important cause it needs to be executed inside coroutine
    Citizen.CreateThread(function()
        self:Sync()
    end)

    return self
end

function LQModel:getAttirbutes()
    return self.attributes
end
