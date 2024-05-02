---@class Canvas
---@field public size Vector
---@field public buffer_index number
---@field r BiByteArray
---@field g BiByteArray
---@field b BiByteArray
---@field f_r BiByteArray
---@field f_g BiByteArray
---@field f_b BiByteArray
---@field c BiByteArray
---@field change_buffer BiByteArray|nil
---@field background Vector
---@field foreground Vector
---@field public gpu Gpu
local canvas = {}

---@param gpu Gpu?
---@return Canvas
function canvas:new(size, gpu)
    gpu = gpu or require"component".gpu
    local index = gpu.allocateBuffer(size[1], size[2])

    if index == nil then error("fail at create a new vram buffer!") end

    local BiByteArray = require("bit.BiByteArray")
    local obj = {
        size = size,
        buffer_index = index,
        gpu = gpu,
        background = require("vector"):new(0,0,0),
        foreground = require("vector"):new(255,255,255),
        r = BiByteArray:new(size[1], size[2], 8, 0),
        g = BiByteArray:new(size[1], size[2], 8, 0),
        b = BiByteArray:new(size[1], size[2], 8, 0),
        f_r = BiByteArray:new(size[1], size[2], 8, 0xffffffffffffffff),
        f_g = BiByteArray:new(size[1], size[2], 8, 0xffffffffffffffff),
        f_b = BiByteArray:new(size[1], size[2], 8, 0xffffffffffffffff),
        c = BiByteArray:new(size[1], size[2], 8, 0x2020202020202020),
    }
    setmetatable(obj, self)
    self.__index = self

    return obj
end
---@param self Canvas
local function check_gpu(self)
    if self.gpu == nil then error("fail at try access the canvas gpu field!",3) end
end
---@param self Canvas
local function check_index(self)
    if self.buffer_index == nil then error("fail at try access a nil vram buffer!",3) end
end

function canvas:begin()
    check_index(self)
    check_gpu(self)
    self.gpu.setActiveBuffer(self.buffer_index)
    self.change_buffer = require("bit.BiByteArray"):new(self.size[1], self.size[2], 1, 0)
end

---@param color number
function canvas:setBackground(color)
    self.background = require("vector")(((color & 0xff0000)>>16), ((color & 0xff00)>>8), (color & 0xff))
end

---@param color number
function canvas:setForeground(color)
    self.foreground = require("vector")(((color & 0xff0000)>>16), ((color & 0xff00)>>8), (color & 0xff))
end

---@param x number
---@param y number
---@param char string
function canvas:set(x, y, char)
    local set, _x, _y = self.r.set, x-1, y-1
    set(self.r, self.background[1], _x, _y)
    set(self.g, self.background[2], _x, _y)
    set(self.b, self.background[3], _x, _y)
    set(self.f_r, self.foreground[1], _x, _y)
    set(self.f_g, self.foreground[2], _x, _y)
    set(self.f_b, self.foreground[3], _x, _y)
    set(self.c, string.byte(char), _x, _y)
    self.change_buffer:set(1, _x, _y)
end

---@param x number
---@param y number
---@param size_x number
---@param size_y number
---@param char string
function canvas:fill(x, y, size_x, size_y, char)
    local set = self.r.set
    for _y = y, (y + size_y -1) do
        for _x = x, (x + size_x -1) do
            local __x, __y = _x-1, _y-1
            set(self.r, self.background[1], __x, __y)
            set(self.g, self.background[2], __x, __y)
            set(self.b, self.background[3], __x, __y)
            set(self.f_r, self.foreground[1], __x, __y)
            set(self.f_g, self.foreground[2], __x, __y)
            set(self.f_b, self.foreground[3], __x, __y)
            set(self.c, string.byte(char), __x, __y)
        end
    end
    self.gpu.fill(x,y,size_x,size_y, char)
end

function canvas:done()
    check_gpu(self)
    local fore, back = nil, nil
    for x, y, v in self.change_buffer:interator() do
        if v == 1 then
            local _fore = (self.f_r:get(x-1, y-1) << 16) | (self.f_g:get(x-1, y-1) << 8) | self.f_b:get(x-1, y-1)
            local _back = (self.r:get(x-1, y-1) << 16) | (self.g:get(x-1, y-1) << 8) | self.b:get(x-1, y-1)
            if _fore ~= fore then self.gpu.setForeground(_fore) fore = _fore end
            if _back ~= back then self.gpu.setBackground(_back) back = _back end
            self.gpu.set(x, y, string.char(self.c:get(x-1, y-1)))
        end
    end
    self.change_buffer:clear(0)
    self.gpu.setActiveBuffer(0)
end

---@param pos Vector
function canvas:display(pos)
    check_index(self)
    check_gpu(self)
    self.gpu.bitblt(0, pos[1], pos[2], self.size[1], self.size[2], self.buffer_index, 1, 1)
end

---@param dst number
---@param pos Vector
function canvas:copy(dst, pos)
    check_index(self)
    check_gpu(self)
    self.gpu.bitblt(dst, pos[1], pos[2], self.size[1], self.size[2], self.buffer_index, 1, 1)
end

---@return boolean
function canvas:free()
    check_index(self)
    check_gpu(self)
    local result = self.gpu.freeBuffer(self.buffer_index)
    if result then self.buffer_index = nil end

    self.r = nil
    self.g = nil
    self.b = nil
    self.f_r = nil
    self.f_g = nil
    self.f_b = nil
    self.c = nil
    return result
end

---@param p0 Vector
---@param p1 Vector
function canvas:draw_line(p0, p1)
    local x0, y0, x1, y1 = p0[1], p0[2], p1[1],p1[2]
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx, sy
    if x0 < x1 then sx = 1 else sx = -1 end
    if y0 < y1 then sy = 1 else sy = -1 end
    local err = dx - dy

    while true do
        self:set(x0, y0, " ")
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end

function canvas:draw_polygon(...)
    local polygon = {...}

    for i = 1, #polygon do
        self:draw_line(polygon[i], polygon[i + 1] or polygon[1])
    end

    local minY, maxY = math.huge, -math.huge
    for _, vertex in ipairs(polygon) do
        if vertex[2] < minY then minY = vertex[2] end
        if vertex[2] > maxY then maxY = vertex[2] end
    end

    for y = minY, maxY do
        local intersections = {}
        for i = 1, #polygon do
            local nextIndex = i % #polygon + 1
            local x0, y0 = polygon[i][1], polygon[i][2]
            local x1, y1 = polygon[nextIndex][1], polygon[nextIndex][2]
            if (y0 <= y and y1 > y) or (y1 <= y and y0 > y) then
                local x = (y - y0) * (x1 - x0) / (y1 - y0) + x0
                table.insert(intersections, x)
            end
        end
        table.sort(intersections)
        for i = 1, #intersections - 1, 2 do
            local startX = math.ceil(intersections[i])
            local endX = math.floor(intersections[i + 1])
            for x = startX, endX do
                self:set(x, y, " ")
            end
        end
    end
end

function canvas:drawCircle(center, radius, stepSize)
    local cx, cy = center[1], center[2]

    local polygon = {}

    for theta = 0, 2 * math.pi, stepSize do
        table.insert(polygon, {math.floor(0.5 + cx + (math.cos(theta) * radius)),math.floor(0.5 + cy + (math.sin(theta) * radius * 0.63))})
    end

    self:draw_polygon(table.unpack(polygon))
end

return canvas