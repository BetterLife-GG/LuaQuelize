---@class LQModel
LQModel = {}

---@alias LQModelOptions { }
---@alias LQModelValue { type: LQDataType, unique?: boolean, allowNull?: boolean, primaryKey?: boolean, defult?: any, autoIncrement?: boolean, references?: string }

---@param modelName string
---@param attributes table<string, LQModelValue>
---@param options LQModelOptions
---@return LQModel
function LQModel.new(modelName, attributes, options)
    attributes = attributes or {}
    ---@type LQModelOptions
    options = options or {}

    self = self or {}

    setmetatable(self, {
        __index = LQModel,
        __call = function(self, ...)
            return self:new(...)
        end
    })

    self.__ready = false
    self.modelName = modelName
    self.attributes = attributes
    self.options = options

    -- populate slef (cross resource does not support metatables)
    for k, v in pairs(LQModel) do
        self[k] = v
    end


    return self
end

function LQModel:__getDoesTableExist()
    -- return oxmysql:query('SHOW CREATE TABLE ' .. self.modelName, {}, nil, nil, false, false)
    return oxmysql:query('SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?', { self.modelName }, nil, nil, false, false)
end

function LQModel:Sync()
    -- local exist = pcall(, function()
    -- end)
    local exist = LQModel:__getDoesTableExist()

    if exist then

    else
        local attributes = tableext.map(self.attributes, function(attribute, key)
            local row = LQInternal.joinSQLFragments({
                key,
                attribute.type:toSql(),
                attribute.primaryKey and 'PRIMARY KEY' or nil,
                attribute.autoIncrement and 'AUTO_INCREMENT' or nil,
                attribute.unique and 'UNIQUE' or nil,
                attribute.allowNull and 'NULL' or 'NOT NULL',
                attribute.default and 'DEFAULT ' .. attribute.default or nil,
                attribute.references and 'REFERENCES ' .. attribute.references or nil
            })

            return row
        end)

        print('attr', Debug.DumpTable(attributes))

        local attributesSQL = LQInternal.joinSQLFragments(tableext.entries(attributes), ', ')

        print(attributesSQL)

        local tableSQL = LQInternal.joinSQLFragments({
            'CREATE TABLE @modelName',
            '(',
            attributesSQL,
            ')',
        })

        oxmysql:query(tableSQL, {
            modelName = self.modelName
        }, nil, nil, false, false)

    end
end

---@param modelName string
---@param attributes table<string, LQModelValue>
---@param options LQModelOptions
---@return LQModel
function LQModel.Define(modelName, attributes, options)
    self = LQModel.new(modelName, attributes, options)

    self:Sync()

    return self
end

function LQModel:getAttirbutes()
    return self.attributes
end
