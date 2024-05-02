require"package".loaded.canvas = nil
require"package".loaded.alphaCanvas = nil
local canvas = require"canvas"
local alphaCanvas = require"alphaCanvas"
local vector = require"vector"

local ammounts = {}
local names = {}
local stop_count = true
---@type Gpu
local raw_gpu = require("component").gpu

---@type Gpu
local fake_gpu = {}


---remake the fake gpu

local make_warper = function(name, data)
    return function(...)
        ammounts[name] = (ammounts[name] or 0) + 1
        return data(...)
    end
end

for i,v in pairs(raw_gpu) do
    fake_gpu[i] = make_warper(i,v)
end

local function print_all_calls()
    local tp = ""
    local total = 0
    for key, value in pairs(ammounts) do
        tp = tp .. string.format("%s -> %d\n", key,value)
        total = total + value
    end
    print(tp.. "total ->" .. tostring(total) .. "\n")
end
raw_gpu.freeAllBuffers()


local back_ground = canvas:new(vector(160,50), fake_gpu)
local obj = alphaCanvas:new(vector(160, 50), 8, fake_gpu)
obj:addAlphaChannel(0)

back_ground:begin()
back_ground:setBackground(0xff0000)
back_ground:fill(1,1, 160, 50, " ")
back_ground:done()


-- goto ends


obj:begin()
obj:setBackgroundRGBA(0xff0044)
obj:fill(1, 1, 160, 50, " ")
obj:setBackgroundRGBA(0)
obj:drawCircle(vector(80,25), 10, 3.1415926535/36)
obj:drawCircle(vector(11,11), 10, 3.1415926535/36)
obj:drawCircle(vector(100,13), 12, 3.1415926535/36)
obj:drawCircle(vector(80,8), 5, 3.1415926535/36)
obj:drawCircle(vector(40,33), 5, 3.1415926535/36)
obj:done()


stop_count = false

obj:displayToCanvas(vector(1,1), back_ground)

back_ground:display(vector(1,1))

stop_count = true

obj:free()

io.read()


raw_gpu.setForeground(0xffffff)
raw_gpu.setBackground(0)
require("term").clear()
print_all_calls()


::ends::