---@class LQModel
LQModel = {}

---comment
---@generic T
---@param name any
---@param options T
---@return LQModel
function LQModel:new(name, options)
    local options = options or {}

    local self = {}

    self.__tablename = name

    setmetatable(self, {
        __index = LQModel,
        __call = function(self, ...)
            return self:new(...)
        end
    })

    return self
end

function LQModel:__tablename()
    return self.__tablename
end

function LQModel:FindByPK(pk)
    print(pk)
end
