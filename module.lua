LuaQuelize = {}

function LuaQuelize:Model(name, options)
    return LQModel:new(name, options)
end

exports('LuaQuelize', function()
    return LuaQuelize
end)
