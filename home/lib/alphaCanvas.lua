local Canvas = require("canvas")

---@class AlphaCanvas : Canvas
---@field deep number
---@field protected a BiByteArray
---@field protected f_a BiByteArray
local AlphaCanvas = setmetatable({}, {__index = Canvas})

---@param size Vector
---@param deep integer
---@param gpu Gpu?
function AlphaCanvas:new(size, deep, gpu)
    deep = deep or 8
    if math.floor(deep) ~= deep then error("the #2 arg must be a integer!", 2) end
    if deep % 2 ~= 0 then error("Deep need be a power of 2!", 2) end

    local obj = Canvas:new(size, gpu)
    ---@cast obj AlphaCanvas

    obj.deep = deep

    setmetatable(obj, self)
    self.__index = self

    obj:addAlphaChannel()
    obj:setForeground(0xffffff)
    obj:setBackground(0)

    return obj
end

function AlphaCanvas:begin()
    Canvas.begin(self)
end

---@param color number
function AlphaCanvas:setBackground(color)
    local r, g, b = (color & (0xff << 16)) >> 16, (color & (0xff << 8)) >> 8, color & 0xff
    self.background = require("vector")(r,g,b,(1 << self.deep) - 1)
end

---@param color number
function AlphaCanvas:setForeground(color)
    local r, g, b = (color & (0xff << 16)) >> 16, (color & (0xff << 8)) >> 8, color & 0xff
    self.foreground = require("vector")(r,g,b,(1 << self.deep) - 1)
end

---@param color number
function AlphaCanvas:setBackgroundRGBA(color)
    local r, g, b, a = (color & (0xff << 24)) >> 24, (color & (0xff << 16)) >> 16, (color & (0xff << 8)) >> 8, math.floor((color & 0xff) * (((1 << self.deep) - 1) / 0xff))
    self.background = require("vector")(r,g,b,a)
end

---@param color number
function AlphaCanvas:setForegroundRGBA(color)
    local r, g, b, a = (color & (0xff << 24)) >> 24, (color & (0xff << 16)) >> 16, (color & (0xff << 8)) >> 8, math.floor((color & 0xff) * (((1 << self.deep) - 1) / 0xff))
    self.foreground = require("vector")(r,g,b,a)
end


---@param x number
---@param y number
---@param char string
function AlphaCanvas:set(x, y, char)
    Canvas.set(self, x, y, char)
    self.a:set(self.background[4], x-1, y-1)
    self.f_a:set(self.foreground[4], x-1, y-1)
end

---@param x number
---@param y number
---@param size_x number
---@param size_y number
---@param char string
function AlphaCanvas:fill(x, y, size_x, size_y, char)
    Canvas.fill(self, x, y, size_x, size_y, char)
    for _y = y, (y + size_y - 1) do
        for _x = x, (x + size_x - 1) do
            self.a:set(self.background[4], _x-1, _y-1)
            self.f_a:set(self.foreground[4], _x-1, _y-1)
        end
    end
end

function AlphaCanvas:done()
    Canvas.done(self)
end

local function number_to_rgb_component_8(number)
    return (number & 0xff0000)>>16, (number & 0xff00)>>8, number & 0xff
end

local function rgb24_to_rgb9(r,g,b)
    local gray = 0
    if r == g and g == b and r ~= 0 and r ~= 0xff then gray = math.floor(r / 255 * 17 + 0.5) end
    r = math.floor(r / 255 * 5 + 0.5)
    g = math.floor(g / 255 * 7 + 0.5)
    b = math.floor(b / 255 * 4 + 0.5)

    return gray << 9 | r << 6 | g << 3 | b
end

local function rgb9_to_rgb24(rgb9)
    local gray, r, g, b = (rgb9 & 0x1E00) >> 9,(rgb9 & 448) >> 6, ((rgb9 & 56) >> 3), (rgb9 & 7)
    if gray ~= 0 then local _gray = math.floor(gray * 255 / 17 + 0.5) return _gray << 16 | _gray << 8 | _gray end
    r = math.floor(r * 255 / 5 + 0.5)
    g = math.floor(g * 255 / 7 + 0.5)
    b = math.floor(b * 255 / 4 + 0.5)

    return r << 16 | g << 8 | b
end

---@param self AlphaCanvas
---@param read_pos Vector
---@private
function AlphaCanvas:create_image_to_screen(read_pos)
    local dst_x, dst_y = self.gpu.getResolution()
    self.gpu.bitblt(self.buffer_index, 1, 1,
        (self.size[1] > dst_x) and self.size[1] or dst_x,
        (self.size[2] > dst_y) and self.size[2] or dst_y,
        0, read_pos[1], read_pos[2]
    )

    self.gpu.setActiveBuffer(self.buffer_index)
    local max_alpha = (1 << self.deep) - 1
    local fore, back = -1, -1
    for y=1, self.size[2] do
        for x=1, self.size[1] do
            local alpha = self.a:get(x-1, y-1) / max_alpha
            local i_alpha = 1 - alpha

            local char = self.c:get(x - 1, y - 1)
            local fR, fG, fB = self.f_r:get(x-1, y-1)*alpha, self.f_g:get(x-1, y-1)*alpha, self.f_b:get(x-1, y-1)*alpha
            local bR, bG, bB = self.r:get(x-1, y-1)*alpha, self.g:get(x-1, y-1)*alpha, self.b:get(x-1, y-1)*alpha

            local _char, _fore, _back = self.gpu.get(x,y)
            local _fR, _fG, _fB = ((_fore & 0xff0000)>>16)*i_alpha, ((_fore & 0xff00)>>8)*i_alpha, (_fore & 0xff)*i_alpha
            local _bR, _bG, _bB = ((_back & 0xff0000)>>16)*i_alpha, ((_back & 0xff00)>>8)*i_alpha, (_back & 0xff)*i_alpha

            local gpu_fb = (math.floor(fR+_fR) << 16) | (math.floor(fG+_fG) << 8) | math.floor(fB+_fB)
            local gpu_bg = (math.floor(bR+_bR) << 16) | (math.floor(bG+_bG) << 8) | math.floor(bB+_bB)

            if not (gpu_fb == fore) then self.gpu.setForeground(gpu_fb) fore = gpu_fb end
            if not (gpu_bg == back) then self.gpu.setBackground(gpu_bg) back = gpu_bg end
            if (char ~= string.byte(_char)) or (_fore ~= gpu_fb) or (_back ~= gpu_bg) then self.gpu.set(x, y, string.char(char)) end
        end
    end
end

---@param self AlphaCanvas
---@param read_pos Vector
---@param canvas Canvas
---@private
function AlphaCanvas:create_image_to_canvas(read_pos, canvas)
    local dst_x, dst_y = self.gpu.getResolution()
    self.gpu.bitblt(self.buffer_index, 1, 1,
        (self.size[1] > dst_x) and self.size[1] or dst_x,
        (self.size[2] > dst_y) and self.size[2] or dst_y,
        canvas.buffer_index, read_pos[1], read_pos[2]
    )

    self.gpu.setActiveBuffer(self.buffer_index)
    local max_alpha = (1 << self.deep) - 1

    read_pos = read_pos - require("vector")(1,1)
    local color_hash_table = {}

    local get = self.c.get
    local a,c0,r0,g0,b0, fr0,fg0,fb0 = self.a, self.c, self.r, self.g, self.b, self.f_r, self.f_g, self.f_b
    local c1,r1,g1,b1, fr1,fg1,fb1 =  canvas.c, canvas.r, canvas.g, canvas.b, canvas.f_r, canvas.f_g, canvas.f_b

    for y=1, self.size[2] do
        for x=1, self.size[1] do
            local alpha = get(a, x-1, y-1) / max_alpha
            local i_alpha = 1 - alpha

            local char = get(c0, x - 1, y - 1)
            local fR, fG, fB = get(fr0, x-1, y-1)*alpha, get(fg0, x-1, y-1)*alpha, get(fb0, x-1, y-1)*alpha
            local bR, bG, bB = get(r0, x-1, y-1)*alpha, get(g0, x-1, y-1)*alpha, get(b0, x-1, y-1)*alpha

            local _x, _y = x - 1 + read_pos[1], y - 1 + read_pos[2]
            local _char = get(c1, _x, _y)
            local _fR, _fG, _fB = get(fr1, _x, _y), get(fg1, _x, _y), get(fb1, _x, _y)
            local _bR, _bG, _bB = get(r1, _x, _y), get(g1, _x, _y), get(b1, _x, _y)

            local _fore = rgb24_to_rgb9(_fR, _fG, _fB)
            local _back = rgb24_to_rgb9(_bR, _bG, _bB)
            local gpu_fb = rgb24_to_rgb9(_fR * i_alpha + fR, _fG * i_alpha + fG, _fB * i_alpha + fB)
            local gpu_bg = rgb24_to_rgb9(_bR * i_alpha + bR, _bG * i_alpha + bG, _bB * i_alpha + bB)

            local hash = char << 18 | gpu_fb << 9 | gpu_bg

            --check if the visible result color from merge is the different to original color in the canvas, if is equal avoid a gpu set call
            if (char ~= string.byte(_char)) or (_fore ~= gpu_fb) or (_back ~= gpu_bg) then
                --create a hast to use as index, this number have enough information to notice differencs between pixels
                hash = gpu_fb << 9 | gpu_bg

                local pixels = color_hash_table[hash]
                if not pixels then
                    color_hash_table[hash] = {{x,y, string.char(char)}}
                else
                    table.insert(pixels, {x,y, string.char(char)})
                end
            end
        end
    end

    local fore , back = -1, -1
    local setForeground,setBackground, set  = self.gpu.setForeground, self.gpu.setBackground, self.gpu.set

    for _hash, pixels in pairs(color_hash_table) do
        local _fore,_back = _hash >> 9 , _hash & 0x1ff
        if _fore ~= fore then setForeground(rgb9_to_rgb24(_fore)) fore = _fore end
        if _back ~= back then setBackground(rgb9_to_rgb24(_back)) back = _back end

        for _, pixel in pairs(pixels) do
            set(table.unpack(pixel))
        end
    end
end

---@param pos Vector
function AlphaCanvas:display(pos)
    if self.buffer_index == nil then error("fail at try free a nil vram buffer!",2) end
    if self.gpu == nil then error("fail at try access the canvas gpu field!",2) end

    self:create_image_to_screen(pos)
    Canvas.display(self, pos)
end

---@param pos Vector
---@param canvas Canvas
function AlphaCanvas:displayToCanvas(pos, canvas)
    if self.buffer_index == nil then error("fail at try free a nil vram buffer!",2) end
    if self.gpu == nil then error("fail at try access the canvas gpu field!",2) end

    self:create_image_to_canvas(pos, canvas)
    self.gpu.bitblt(canvas.buffer_index, pos[1], pos[2], self.size[1], self.size[2], self.buffer_index, 1, 1)
end

---@param default integer?
function AlphaCanvas:addAlphaChannel(default)
    local value = 0
    if default then
        if default == 0 then
            value = 0
        elseif default == ((1 << self.deep) - 1) then
            value = -1
        else
            local ammount_per_number = math.floor(64 / self.deep)
            for i=0, ammount_per_number-1 do
                value = value | (default << (self.deep * i))
            end
        end
    else
        value = -1
    end

    self.a = require("bit.BiByteArray"):new(self.size[1], self.size[2], self.deep, value)
    self.f_a = require("bit.BiByteArray"):new(self.size[1], self.size[2], self.deep, value)
end

function AlphaCanvas:plotalpha(pos)
    pos = pos - require("vector")(1,1)
    for y = 1, self.size[2] do
        for x = 1, self.size[1] do
            local alpha = self.a:get(x-1, y-1) / ((1 << self.deep) - 1)
            if alpha > 0 then
                self.gpu.set(x + pos[1], y + pos[2], "X")
            else
                self.gpu.set(x + pos[1], y + pos[2], "+")
            end
        end
    end
end

function AlphaCanvas:free()
    Canvas.free(self)
    self.a = nil
    self.f_a = nil
    self.change_buffer = nil
end

return AlphaCanvas