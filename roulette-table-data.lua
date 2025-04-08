---@class Bid
---@field amount number
---@field numbers string[]

---@class RouletteTableData
---@field bids Bid[]
local RouletteTableData = {}
RouletteTableData.__index = RouletteTableData

---@alias Color "black"|"red"

---@class GridPosition
---@field x integer
---@field y integer
---@field third integer

---@class NumberProps
---@field grid_pos nil|GridPosition
---@field color nil|Color
---@field parity nil|0|1
---@field number integer

---@param t table
---@param v any
local function table_contains(t, v)
    for _, value in ipairs(t) do
        if value == v then
            return true
        end
    end

    return false
end

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

function RouletteTableData.new()
    local new = setmetatable({}, RouletteTableData)
    new.bids = {}

    return new
end

---@param numbers string[]
function RouletteTableData:bid_numbers(bid, numbers)
    table.insert(self.bids, {
        amount = bid,
        numbers = numbers
    })
end

---@param number string
function RouletteTableData:bid_number(bid, number)
    self:bid_numbers(bid, { number })
end

---@param filter function
function RouletteTableData:bid_filter(bid, filter)
    local numbers = {}
    for number, props in pairs(number_props) do
        if filter(props) then
            table.insert(numbers, number)
        end
    end

    self:bid_numbers(bid, numbers)
end

---@param row 1|2|3
function RouletteTableData:bid_row(bid, row)
    self:bid_filter(bid, function(props)
        return props.grid_pos ~= nil and props.grid_pos.y == row - 1
    end)
end

---@param third 1|2|3
function RouletteTableData:bid_third(bid, third)
    self:bid_filter(bid, function(props)
        return props.grid_pos ~= nil and props.grid_pos.third == third - 1
    end)
end

---@param column 1|2|3|4|5|6
function RouletteTableData:bid_column(bid, column)
    self:bid_filter(bid, function(props)
        return props.grid_pos ~= nil and props.grid_pos.x == column - 1
    end)
end

---@param color "black"|"red"
function RouletteTableData:bid_color(bid, color)
    self:bid_filter(bid, function(props)
        return props.color ~= nil and props.color == color
    end)
end

function RouletteTableData:bid_black(bid)
    self:bid_color(bid, "black")
end

function RouletteTableData:bid_red(bid)
    self:bid_color(bid, "red")
end

---@param parity 0|1
function RouletteTableData:bid_parity(bid, parity)
    self:bid_filter(bid, function(props)
        return props.parity ~= nil and props.parity == parity
    end)
end

function RouletteTableData:bid_odd(bid)
    self:bid_parity(bid, 1)
end

function RouletteTableData:bid_even(bid)
    self:bid_parity(bid, 0)
end

function RouletteTableData:bid_range(bid, low, high)
    self:bid_filter(bid, function(props)
        return props.number >= low and props.number <= high
    end)
end

function RouletteTableData:bid_low(bid)
    self:bid_range(bid, 1, 18)
end

function RouletteTableData:bid_high(bid)
    self:bid_range(bid, 19, 36)
end

---@param number string
---@return number
function RouletteTableData:get_return(number)
    local bid_for_number = 0
    for _, bid in ipairs(self.bids) do
        if table_contains(bid.numbers, number) then
            bid_for_number = bid_for_number + (bid.amount / #bid.numbers)
        end
    end
    return bid_for_number * 36
end

function RouletteTableData:reset_bid()
    self.bids = {}
end

return RouletteTableData
