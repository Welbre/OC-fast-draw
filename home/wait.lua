local t = setmetatable({}, {__call = function(self, key)
    while true do
        local _, _, char, code, pl = require"event".pull("key_down")
        if not key then break end
        if char == key then break end
    end
end})

return t