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

---@alias LQModelOptions { force?: boolean }
---@alias LQModelValue { name: string, type: LQDataType, unique?: boolean, allowNull?: boolean, primaryKey?: boolean, defult?: any, autoIncrement?: boolean, references?: string }

---@param modelName string
---@param attributes LQModelValue[]
---@param options LQModelOptions
---@return LQModel
function LQModel.__newModel(modelName, attributes, options, registrant)
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

    MySQL:query(query)
end

function LQModel:__removeColumn(attrName)
    local query = LQInternal.joinSQLFragments({
        'ALTER TABLE',
        '`' .. self.schema .. '`.`' .. self.modelName .. '`',
        'DROP COLUMN',
        '`' .. attrName .. '`'
    })

    MySQL:query(query)
end

---Runs only inside coroutine, otherwise it will crash, call inside Citizen.CreateThread
---@param data { force?: boolean}
function LQModel:Sync(data)
    data = data or {}
    local exist = MySQL:query('SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = \'BASE TABLE\' AND TABLE_NAME = \'' .. self.modelName .. '\' AND TABLE_SCHEMA = \'' .. self.schema .. '\'')

    if #exist == 1 then
        -- check if table structure is the same
        local columns = MySQL:query('SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_KEY, COLUMN_DEFAULT, EXTRA FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = \'' .. self.modelName .. '\' AND TABLE_SCHEMA = \'' .. self.schema .. '\'')
        local foundCorrectColumns = {}

        -- todo removing columns
        local removedInfo = false

        for k, v in pairs(columns) do
            local existInSchema = tableext.find(self.attributes, function(attr)
                return attr.name == v.COLUMN_NAME
            end)

            if existInSchema then
                foundCorrectColumns[v.COLUMN_NAME] = true
            else
                print('Column ' .. v.COLUMN_NAME .. ' does not exist in schema, but exists in database')
                removedInfo = not data.force

                if (data.force) then
                    print('Force removing column ' .. v.COLUMN_NAME)
                    self:__removeColumn(v.COLUMN_NAME)
                end
            end
        end

        if removedInfo then
            print('Recommended to remove columns manually or (not recommended) :Sync({ force: true })')
        end

        -- creating new columns
        ---@type { attrName: string, insertAfter: string }[]
        local columnsToAdd = {}

        ---Returns name of attribute that should be added after
        local function getAttrBefore(attr)
            local attrBefore = self.attributes[1].name

            for k, v in pairs(self.attributes) do
                if v.name == attr.name then
                    break
                end

                attrBefore = v.name
            end

            return attrBefore
        end

        for k, v in pairs(self.attributes) do
            if not foundCorrectColumns[v.name] then
                print('Column ' .. v.name .. ' does not exist in database, but exists in schema')
                table.insert(columnsToAdd, {
                    name = v.name,
                    index = k,
                    insertAfter = getAttrBefore(v)
                })
            end
        end

        for k, v in pairs(columnsToAdd) do
            print('Adding column ' .. v.name .. ' after ' .. v.insertAfter)
            self:__alterTable(v.name, self.attributes[v.index], v.insertAfter)
        end
    else
        local primaryKey

        local attributes = tableext.map(self.attributes, function(attribute, key)
            local row = LQInternal.joinSQLFragments({
                attribute.name,
                _LQModel:__attrToSQL(attribute)
            })

            if (attribute.primaryKey) then
                primaryKey = attribute.name
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
    self = LQModel.__newModel(modelName, attributes, options, GetInvokingResource())

    -- thread is important cause it needs to be executed inside coroutine
    Citizen.CreateThread(function()
        self:Sync(options)
    end)

    return self
end

function LQModel:getAttirbutes()
    return self.attributes
end

-- Value management
function LQModel:create(values)
    -- create object
end
