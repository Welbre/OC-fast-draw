local bArray = require("bit.ByteArray")

---@class BiByteArray : ByteArray
---@field m_size integer[]
local bba = setmetatable({}, {__index = bArray})

---@param x_size integer
---@param y_size integer
---@param valueSize integer
---@param initial number?
function bba:new(x_size, y_size, valueSize, initial)
    if x_size == 0 then error("x can't be zero!", 2) end
    if y_size == 0 then error("y can't be zero!", 2) end

    local obj = bArray:new(x_size * y_size, valueSize, initial)
    ---@cast obj BiByteArray

    obj.m_size = {x_size, y_size}

    setmetatable(obj, self)
    self.__index = self

    return obj
end

---@param value number
---@param x integer
---@param y integer
function bba:set(value, x, y)
    if x >= self.m_size[1] then error(string.format("x(%d) is out of range(%d)", x, self.m_size[1]), 2) end
    if y >= self.m_size[2] then error(string.format("y(%d) is out of range(%d)", y, self.m_size[2]), 2) end
    local index = (x * self.m_size[2]) + y
    if index >= self.size then error(string.format("fail at try access addrress #%d (%d,%d), out of range(%d)", index, x, y, self.size - 1), 2) end

    bArray.set(self, value, index)
end

---@param x integer
---@param y integer
function bba:get(x, y)
    if (x >= self.m_size[1]) or (x < 0) then error(string.format("x(%d) is out of range(%d)", x, self.m_size[1]), 2) end
    if (y >= self.m_size[2]) or (y < 0) then error(string.format("x(%d) is out of range(%d)", y, self.m_size[2]), 2) end
    local index = (x * self.m_size[2]) + y
    if (index >= self.size) or (index < 0) then error(string.format("fail at try access addrress #%d (%d,%d), out of range(%d)", index, x, y, self.size - 1), 2) end

    return bArray.get(self, index)
end

---@return fun():number|nil, number|nil, number|nil
function bba:interator()
    local x = -1
    local y = 0
    return function()
        x = x + 1
        if x >= self.m_size[1] then
            x = 0
            y = y + 1
        end
        if y >= self.m_size[2] then return nil,nil,nil end
        --if ((x*self.m_size[1]) + y) >= self.m_size[1] * self.m_size[2] then return nil, nil, nil end
        return x, y, self:get(x, y)
    end
end

return bba