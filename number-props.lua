
---@type table<string, NumberProps>
local number_props = {
    ["0"] = { grid_pos = nil, color = nil, parity = nil, number = 0 },
    ["00"] = { grid_pos = nil, color = nil, parity = nil, number = 0 },
}

for i = 1, 36 do
    local x = math.floor((i - 1) / 3)
    local y = (i - 1) % 3
    local third = math.floor(x / 4)
    number_props[tostring(i)] = {
        grid_pos = { x = x, y = y, third = third },
        -- TODO: set
        color = "red",
        parity = i % 2,
        number = i
    }
end

local black_numbers = { 2, 4, 6, 8, 10, 11, 13, 15, 17, 20, 22, 24, 26, 28, 29, 31, 33, 35 }
for _, number in pairs(black_numbers) do
    number_props[tostring(number)].color = "black"
end


return number_props
