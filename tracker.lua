local number_props = require("number-props")
local colors = require("colors")

---@class CountStats
---@field number string
---@field count integer
---@field normalized number

---@class Tracker
---@field throws string[]
---@field last_100_counts table<string, integer>
---@field last_100_counts_sorted CountStats[]
---@field last_100 string[]
---@field font love.Font
local Tracker = {}
Tracker.__index = Tracker


function Tracker.new()
    local new = setmetatable({}, Tracker)
    new.throws = {}
    new.last_100_counts = {}
    new.last_100_counts_sorted = {}
    new.last_100 = {}
    new.font = love.graphics.newFont(10)
    return new
end

function Tracker:refresh_last_100_count_sorted()
    local max = 0
    for _, count in pairs(self.last_100_counts) do
        max = math.max(max, count)
    end

    self.last_100_counts_sorted = {}
    for n, count in pairs(self.last_100_counts) do
        table.insert(self.last_100_counts_sorted, {
            number = n,
            count = count,
            normalized = count / max,
        })
    end
    table.sort(self.last_100_counts_sorted, function(a, b)
        return b.count < a.count
    end)
end

---@param n string
function Tracker:register(n)
    ---@param n string
    local function add_to_count(n)
        self.last_100_counts[n] = (self.last_100_counts[n] or 0) + 1
    end
    ---@param n string
    local function remove_from_count(n)
        local count = self.last_100_counts[n] - 1
        if count == 0 then
            count = nil
        end
        self.last_100_counts[n] = count
    end

    table.insert(self.throws, n)
    table.insert(self.last_100, n)
    if #self.last_100 > 100 then
        local removed = table.remove(self.last_100, 1)
        remove_from_count(removed)
    end

    add_to_count(n)

    self:refresh_last_100_count_sorted()
end

function Tracker:get_counts()
    return self.last_100_counts_sorted
end

function Tracker:draw_distribution()
    local font_height = self.font:getHeight()
    local width = 20
    local bar_height = 30
    local bar_width = width * 0.8

    for i, stat in ipairs(self.last_100_counts_sorted) do
        local height = stat.normalized * bar_height
        local x = (i - 1) * width

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", x + (width - bar_width) / 2, font_height, bar_width, height)
        love.graphics.printf(stat.number, x, 0, width, "center")
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(stat.count, x, font_height, width, "center")
    end
end

function Tracker:draw_last()
    local font_height = self.font:getHeight()
    local width = 20
    local number_height = 20
    local number_width = width * 0.8

    for i = 1, math.min(10, #self.last_100) do
        local n = self.last_100[#self.last_100 - (i - 1)]
        local x = (i - 1) * width

        love.graphics.setColor(colors[number_props[n].color or "green"])
        love.graphics.rectangle("fill", x + (width - number_width) / 2, font_height, number_width, number_height)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(n, x, 0, width, "center")
    end
end

function Tracker:draw()
    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1)
    local font_height = self.font:getHeight()

    love.graphics.translate(0, 0)
    self:draw_last()
    love.graphics.translate(20 * 11, 0)
    self:draw_distribution()
end

return Tracker
