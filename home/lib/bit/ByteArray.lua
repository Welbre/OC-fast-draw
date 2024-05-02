---@class ByteArray
---@field size integer
---@field v_size integer
---@field memmory number[]
---@field pointer integer
---@field mask integer
local bArray = {}

---@param self ByteArray
---@param initial number
local function initialize_memmory(self, initial)
    local total_memmory_chunk = math.ceil(self.size * self.v_size / 64)
    for i = 0, total_memmory_chunk do
        self.memmory[i] = initial
    end
end

---@param size integer
---@param valueSize integer
---@param initial number?
function bArray:new(size, valueSize, initial)
    if size == 0 then error("size can't be zero!", 2) end

    ---@type ByteArray
    local obj = {
        pointer = 0,
        size = size,
        v_size = valueSize,
        memmory = {},
        mask = (1 << valueSize) - 1
    }

    setmetatable(obj, bArray)
    self.__index = bArray

    initialize_memmory(obj, initial or 0)

    return obj
end

---@param value number
---@param index integer
function bArray:set(value, index)
    if value > ((1 << self.v_size) - 1) then error("value need to be equal or less that ".. (1 << self.v_size) - 1 .. "!", 2) end
    if index == nil then error("index can't be nil!", 2) end
    if index < 0 or index >= self.size then error("Index ".. tostring(index) .. " out of range(" .. self.size - 1 .. ")!", 2) end

    local chuck_index = math.floor(index * self.v_size / 64)
    local bit_local_pos = (index * self.v_size) % 64
    local chunk = self.memmory[chuck_index]

    local shiftAmount = 64 - self.v_size - bit_local_pos
    chunk = (chunk & ~(self.mask << shiftAmount)) | (value << shiftAmount)

    self.memmory[chuck_index] = chunk
end

function bArray:put(value)
    self:set(value, self.pointer)
    self.pointer = self.pointer + 1
end

---@param index number
function bArray:get(index)
    if index < 0 or index >= self.size then error("Index ".. tostring(index) .. " out of range(" .. self.size - 1 .. ")!", 2) end

    local chunk_index = math.floor(index * self.v_size / 64)
    local bit_local_index = (index * self.v_size) % 64
    local chunk = self.memmory[chunk_index]

    return (chunk >> (64 - self.v_size - bit_local_index)) & self.mask
end

---@param value number
function bArray:clear(value)
    for key, _ in pairs(self.memmory) do
        self.memmory[key] = value
    end
end

---@return number
function bArray:getByteMemmory()
    return #self.memmory * self.v_size
end

---@return fun():number|nil , number|nil
function bArray:interator()
    local pointer = -1
    return function()
        pointer = pointer + 1
        if pointer >= self.size then return nil,nil end
        return pointer, self:get(pointer)
    end
end

return bArray