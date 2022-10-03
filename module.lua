LuaQuelize = {}
-- abstact
LuaQuelize.config = {
    schema = '',
}

LuaQuelize.Model = LQModel
LuaQuelize.Types = LQDataTypes

exports('LuaQuelize', function(schema)
    local instance = LuaQuelize
    instance.config.schema = schema

    setmetatable(instance, {
        __index = LuaQuelize,
    })

    return instance
end)
