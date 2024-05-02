---@class Vector : number[]
---@field dimention number
---@field len fun(self:Vector, other:Vector)
---@field dir fun(self:Vector, to:Vector)
---@field applyFun fun(...)
local vector = {}
local meta = {}
vector.__index = meta

---@param self Vector
---@param other Vector
function meta:len(other)
    if not self.dimention == other.dimention then return nil end
    local sqrtDifSun = 0
    for key, value in ipairs(self) do
        sqrtDifSun = sqrtDifSun + ((value - other[key]) ^ 2)
    end
    return sqrtDifSun ^ 0.5
end

---@param self Vector
---@param to Vector
function meta:dir(to)
    if not self.dimention == to.dimention then return nil end
    local len = self:len(to)
    local values = {}
    for key, value in ipairs(self) do
        table.insert(values, (to[key] - value) / len)
    end
    return vector(table.unpack(values))
end

function meta:applyFun(...)
    local funs = {...}
    local values = {}
    for key, value in ipairs(self) do
        local result = value
        for _, fun in ipairs(funs) do
            result = fun(result)
        end
        values[key] = result
    end
    return vector(table.unpack(values))
end

function vector.__mul(a, b)
    if (type(b) == "number") or (type(a) == "number") then
        local values = {}
        if type(a) == "table" then
            for key, value in ipairs(a) do values[key] = value * b end
        else
            for key, value in ipairs(b) do values[key] = value * a end
        end
        return vector(table.unpack(values))
    else
        local sum = 0
        for key, value in ipairs(a) do print(key,value, b[key]) sum = sum + (value * b[key]) end
        return sum
    end
end

function vector.__div(a, b)
    if type(a) == "table" and type(b) == "number" then
        return vector.__mul(a, 1/b)
    elseif type(a) == "number" and type(b) == "table" then
        return vector.__mul(b, 1/a)
    end
end

function vector.__add(a, b)
    local values = {}
    if type(a) == "table" then
        for key, value in ipairs(a) do values[key] = value + b[key] end
    else
        for key, value in ipairs(b) do values[key] = value + a[key] end
    end
    return vector(table.unpack(values))
end

function vector.__sub(a, b)
    local values = {}
    if (type(b) == "table") and (type(a) == "table") then
        for key, value in ipairs(a) do values[key] = value - b[key] end
    else
        error("file to subtract a vector and a number")
    end
    return vector(table.unpack(values))
end

function vector:__tostring()
    local st = "{" .. tostring(self[1])
    for i = 2, #self do
        st = st .. ", " .. tostring(self[2])
    end

    for key, value in pairs(self) do
        if type(key) ~= "number" then
            st = string.format("%s, %s: %s", st, key, tostring(value))
        end
    end
    st = st .. "}"
    return st
end

function vector:new(...)
    local args = {...}
    ---@type Vector
    local obj = setmetatable(args, vector)
    obj.dimention =  #args

    return obj
end

vector.__call = vector.new

return setmetatable(vector, vector)