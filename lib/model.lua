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

    self.modelName = modelName
    self.attributes = attributes
    self.options = options

    -- populate slef (cross resource does not support metatables)
    for k, v in pairs(LQModel) do
        self[k] = v
    end


    return self
end

function LQModel:Sync()
    local function checkTable()
        return SQL:query('SHOW CREATE TABLE test')
    end

    local test = pcall(function()
        print('pepega')
        checkTable()
    end, function()
        print('wont work')
    end)

    print(test)

    if 1 == 1 then return end

    if pcall(checkTable()) then

    else
        local tableSQL = LQInternal.joinSQLFragments({
            'CREATE TABLE IF NOT EXISTS',
            self.modelName,
            '(',
            LQInternal.joinSQLFragments(tableext.map(self.attributes, function(value, key)
                local dataType = value.type
                local allowNull = value.allowNull
                local primaryKey = value.primaryKey
                local autoIncrement = value.autoIncrement
                local unique = value.unique
                local defaultValue = value.defaultValue

                local dataTypeString = dataType.toSql()

                if (primaryKey) then
                    dataTypeString = dataTypeString .. ' PRIMARY KEY'
                end

                if (autoIncrement) then
                    dataTypeString = dataTypeString .. ' AUTO_INCREMENT'
                end

                if (unique) then
                    dataTypeString = dataTypeString .. ' UNIQUE'
                end

                if (allowNull == false) then
                    dataTypeString = dataTypeString .. ' NOT NULL'
                end

                if (defaultValue ~= nil) then
                    dataTypeString = dataTypeString .. ' DEFAULT ' .. dataType.stringify(defaultValue)
                end

                return key .. ' ' .. dataTypeString
            end), ', '),
            ')',
        })
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
