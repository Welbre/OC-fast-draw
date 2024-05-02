---@type Gpu
local gpu = require("component").gpu

gpu.setBackground(0xffffff)

gpu.set(1,1, " ")
for x=1, 15 do
    for y=1, 15 do
        gpu.setBackground(x*y*0xffffff / 0xff)
        gpu.set(x,y, " ")
    end
end