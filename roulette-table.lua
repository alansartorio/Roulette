local Vector = require("vector")
local RouletteTableData = require("roulette-table-data")

---@class Button
---@field pos Vector
---@field size Vector
---@field text string
---@field cell CompleteBidKey

---@class RouletteTable
---@field bids table<BidKey, (0)[]>
---@field data RouletteTableData
---@field highlight string
---@field buttons Button[]
local RouletteTable = {
    cell_size = 50,
}
RouletteTable.__index = RouletteTable

---@param count integer
---@return 0[]
local function zeros(count)
    local t = {}
    for i = 1, count do
        table.insert(t, 0)
    end
    return t
end

local function single_zero()
    return zeros(1)
end

---@alias BidKey
---| "columns_single"
---| "columns_double"
---| "rows"
---| "thirds"
---| "numbers_single"
---| "numbers_double_vertical"
---| "numbers_double_horizontal"
---| "numbers_quad"
---| "zero"
---| "double_zero"
---| "black"
---| "red"
---| "even"
---| "odd"
---| "high"
---| "low"

---@alias CompleteBidKey [BidKey, integer]

---@param self CompleteBidKey
---@param other CompleteBidKey
local function same_bidkey(self, other)
    return self[1] == other[1] and self[2] == other[2]
end

function RouletteTable.new()
    local new = setmetatable({}, RouletteTable)

    new.buttons = {
        {
            pos = Vector.new(0, 0),
            size = Vector.new(1, 1.5),
            text = "00",
            cell = { "double_zero", 1 }
        },
        {
            pos = Vector.new(0, 1.5),
            size = Vector.new(1, 1.5),
            text = "0",
            cell = { "zero", 1 }
        },
    }

    -- first row after numbers
    local thirds = {
        "1 to 12",
        "13 to 24",
        "25 to 36",
    }
    for i, third in ipairs(thirds) do
        table.insert(new.buttons, {
            pos = Vector.new(1 + (i - 1) * 4, 3),
            size = Vector.new(4, 1),
            text = third,
            cell = { "thirds", i }
        })
    end

    -- second row after numbers
    local halves = {
        {
            text = "1 to 18",
            cell = { "low", 1 }
        },
        {
            text = "even",
            cell = { "even", 1 }
        },
        {
            text = "red",
            cell = { "red", 1 }
        },
        {
            text = "black",
            cell = { "black", 1 }
        },
        {
            text = "odd",
            cell = { "odd", 1 }
        },
        {
            text = "19 to 36",
            cell = { "high", 1 }
        },
    }
    for i, half in ipairs(halves) do
        table.insert(new.buttons, {
            pos = Vector.new(1 + (i - 1) * 2, 4),
            size = Vector.new(2, 1),
            text = half.text,
            cell = half.cell,
        })
    end

    new.data = RouletteTableData.new()
    new.bids = {
        columns_single = zeros(12),
        columns_double = zeros(12),
        rows = zeros(3),
        thirds = zeros(3),
        numbers_single = zeros(36),
        -- down
        numbers_double_vertical = zeros(2 * 12),
        -- right
        numbers_double_horizontal = zeros(3 * 11),
        -- down right
        numbers_quad = zeros(2 * 11),
        zero = single_zero(),
        double_zero = single_zero(),
        -- color
        black = single_zero(),
        red = single_zero(),
        -- parity
        even = single_zero(),
        odd = single_zero(),

        low = single_zero(),
        high = single_zero(),
    }

    return new
end

---@param pos Vector
---@return nil | CompleteBidKey
function RouletteTable:get_cell(pos)
    local cell_size = self.cell_size
    local zero_height = cell_size * 3 / 2

    local index_real = pos / cell_size
    local index = index_real:floor()

    for _, button in ipairs(self.buttons) do
        if index_real.x >= button.pos.x and
            index_real.x < button.pos.x + button.size.x and
            index_real.y >= button.pos.y and
            index_real.y < button.pos.y + button.size.y then
            return button.cell
        end
    end

    if index.x < 1 or index.y < 0 then
        return nil
    end

    index.x = index.x - 1

    local border = 0.2
    local right = false
    local bottom = false

    if index_real.x % 1 < border and index.x > 0 then
        index.x = index.x - 1
        right = true
    elseif index_real.x % 1 > 1 - border then
        right = true
    end
    if index_real.y % 1 < border and index.y > 0 then
        index.y = index.y - 1
        bottom = true
    elseif index_real.y % 1 > 1 - border then
        bottom = true
    end

    local function get_index(h)
        return index.x * h + (h - index.y)
    end

    if index.x < 0 or index.x > 11 or
        index.y < 0 or index.y > 2 then
        return nil
    end

    if bottom and right then
        if index.x < 11 then
            if index.y < 2 then
                return {
                    "numbers_quad",
                    get_index(2)
                }
            elseif index.y == 2 then
                return {
                    "columns_double",
                    index.x + 1
                }
            end
        else
            return nil
        end
    elseif bottom then
        if index.y < 2 then
            return {
                "numbers_double_vertical",
                get_index(2)
            }
        elseif index.y == 2 then
            return {
                "columns_single",
                index.x + 1
            }
        else
            return nil
        end
    elseif right then
        if index.x < 11 then
            return {
                "numbers_double_horizontal",
                get_index(3)
            }
        else
            return nil
        end
    end

    return { "numbers_single", get_index(3) }
end

---@param cell CompleteBidKey
function RouletteTable:get_cell_center(cell)
    local cell_size = self.cell_size

    local name, index = unpack(cell)

    for _, button in ipairs(self.buttons) do
        if same_bidkey(button.cell, cell) then
            return (button.pos + button.size / 2) * cell_size
        end
    end

    index = index - 1

    if name == "columns_single" then
        return Vector.new(index + 1.5, 3) * cell_size
    elseif name == "columns_double" then
        return Vector.new(index + 2, 3) * cell_size
    end

    if name == "rows" then
        return Vector.new(13.5, index + 0.5) * cell_size
    end

    local function get_xy(h)
        local x = math.floor(index / h)
        local y = ((h - 1) - index) % h
        return Vector.new(x, y)
    end
    if name == "numbers_single" then
        return (get_xy(3) + Vector.new(1.5, 0.5)) * cell_size
    elseif name == "numbers_quad" then
        return (get_xy(2) + Vector.new(2, 1)) * cell_size
    elseif name == "numbers_double_vertical" then
        return (get_xy(2) + Vector.new(1.5, 1)) * cell_size
    elseif name == "numbers_double_horizontal" then
        return (get_xy(3) + Vector.new(2, 0.5)) * cell_size
    end
end

---@param cell CompleteBidKey
---@param amount number
function RouletteTable:add_bid(cell, amount)
    local name, index = unpack(cell)
    self.bids[name][index] = self.bids[name][index] + amount
end

---@param cell CompleteBidKey
function RouletteTable:clear_bid(cell)
    local name, index = unpack(cell)
    self.bids[name][index] = 0
end

function RouletteTable:clear_bids()
    for key, value in pairs(self.bids) do
        for i, value in ipairs(value) do
            self.bids[key][i] = 0
        end
    end
end

---@param number string
function RouletteTable:set_highlight(number)
    self.highlight = number
end

function RouletteTable:start()
    self.data:reset_bid()

    for index, amount in ipairs(self.bids.columns_single) do
        if amount > 0 then
            self.data:bid_column(amount, index)
        end
    end

    for index, amount in ipairs(self.bids.columns_double) do
        if amount > 0 then
            self.data:bid_column(amount / 2, index)
            self.data:bid_column(amount / 2, index + 1)
        end
    end

    for index, amount in ipairs(self.bids.rows) do
        if amount > 0 then
            self.data:bid_row(amount, index)
        end
    end

    for index, amount in ipairs(self.bids.thirds) do
        if amount > 0 then
            self.data:bid_third(amount, index)
        end
    end

    local function get_xy(h, index)
        local x = math.floor((index - 1) / h)
        local y = (h - index) % h
        return Vector.new(x, y)
    end
    local function get_number(pos)
        return pos.x * 3 + (3 - pos.y)
    end
    local right = Vector.new(1, 0)
    local bottom = Vector.new(0, 1)

    for index, amount in ipairs(self.bids.numbers_single) do
        if amount > 0 then
            self.data:bid_number(amount, tostring(index))
        end
    end

    for index, amount in ipairs(self.bids.numbers_double_vertical) do
        if amount > 0 then
            local pos = get_xy(2, index)
            self.data:bid_numbers(amount, {
                tostring(get_number(pos)),
                tostring(get_number(pos + bottom))
            })
        end
    end

    for index, amount in ipairs(self.bids.numbers_double_horizontal) do
        if amount > 0 then
            local pos = get_xy(3, index)
            self.data:bid_numbers(amount, {
                tostring(get_number(pos)),
                tostring(get_number(pos + right))
            })
        end
    end

    for index, amount in ipairs(self.bids.numbers_quad) do
        if amount > 0 then
            local pos = get_xy(2, index)
            print(get_number(pos))
            self.data:bid_numbers(amount, {
                tostring(get_number(pos)),
                tostring(get_number(pos + right)),
                tostring(get_number(pos + bottom)),
                tostring(get_number(pos + right + bottom)),
            })
        end
    end

    for _, amount in ipairs(self.bids.zero) do
        if amount > 0 then
            self.data:bid_number(amount, "0")
        end
    end

    for _, amount in ipairs(self.bids.double_zero) do
        if amount > 0 then
            self.data:bid_number(amount, "00")
        end
    end

    for _, amount in ipairs(self.bids.black) do
        if amount > 0 then
            self.data:bid_black(amount)
        end
    end

    for _, amount in ipairs(self.bids.red) do
        if amount > 0 then
            self.data:bid_red(amount)
        end
    end

    for _, amount in ipairs(self.bids.even) do
        if amount > 0 then
            self.data:bid_even(amount)
        end
    end

    for _, amount in ipairs(self.bids.odd) do
        if amount > 0 then
            self.data:bid_odd(amount)
        end
    end

    for _, amount in ipairs(self.bids.low) do
        if amount > 0 then
            self.data:bid_low(amount)
        end
    end

    for _, amount in ipairs(self.bids.high) do
        if amount > 0 then
            self.data:bid_high(amount)
        end
    end
end

function RouletteTable:draw()
    local cell_size = self.cell_size
    local font_height = love.graphics.getFont():getHeight()

    local function draw_cell_exact(text, pos, size)
        if text == self.highlight then
            love.graphics.setColor(255, 0, 0)
        else
            love.graphics.setColor(1, 1, 1)
        end
        pos = pos * cell_size
        size = size * cell_size
        local x, y = pos:unpack()
        local w, h = size:unpack()
        love.graphics.printf(text, x, y + size.y / 2, w, "center", 0, 1, 1, 0, font_height / 2)
        love.graphics.rectangle("line", x, y, w, h)
    end

    ---@param text string
    ---@param pos Vector
    local function draw_cell(text, pos)
        pos = pos + Vector.new(1, 0) -- add padding for 0 and 00
        draw_cell_exact(text, pos, Vector.new(1, 1))
    end

    local zero_height = cell_size * 3 / 2
    for _, button in ipairs(self.buttons) do
        draw_cell_exact(button.text, button.pos, button.size)
    end
    --draw_cell_exact("00", Vector.new(0, zero_height), Vector.new(cell_size, zero_height))
    for i = 1, 36 do
        local x = math.floor((i - 1) / 3)
        local y = (3 - i) % 3
        draw_cell(tostring(i), Vector.new(x, y))
    end

    local text_height = love.graphics.getFont():getHeight()
    for name, amounts in pairs(self.bids) do
        for index, amount in ipairs(amounts) do
            local pos = self:get_cell_center({ name, index })
            if pos == nil then
                goto continue
            end
            if amount <= 0 then
                goto continue
            end
            local r = 20
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.circle("fill", pos.x, pos.y, r)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(tostring(amount), pos.x - r, pos.y, r * 2, "center", 0, 1, 1, 0, text_height / 2)
            ::continue::
        end
    end
end

return RouletteTable
