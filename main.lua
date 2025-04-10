local rx = require("lib/reactivex")
local Vector = require("vector")
local LoveUtils = require("love-utils")
local Tracker = require("tracker")
local Roulette = require("roulette")
local RouletteTable = require("roulette-table")

---@type Vector
local win

---@type Roulette
local roulette
---@type RouletteTable
local roulette_table

local fast_debug = true
local interaction_timeout = fast_debug and 0.1 or 5

local scheduler = rx.CooperativeScheduler.create()
local money = 1000
local total_bid = 0
local transaction_log = {}
local user_bidded = rx.Subject.create()
local log_font
---@type Tracker
local tracker

local function add_to_log(transaction)
    table.insert(transaction_log, tostring(transaction))
end

function love.load()
    win = LoveUtils.get_win_shape()
    love.window.setMode(win.x, win.y, {
        resizable = true,
        fullscreen = false
    })
    tracker = Tracker.new()
    local positioning = get_positioning()
    roulette = Roulette.new()
    roulette.roll_finished
        :startWith(nil)
        :merge(user_bidded)
        :debounce(interaction_timeout, scheduler)
        :map(function()
            return nil
        end)
        :subscribe(function(n)
            roulette_table:start()
            for _, bid in ipairs(roulette_table.data.bids) do
                print(bid.amount, #bid.numbers)
            end
            add_to_log("-" .. total_bid)
            roulette:throw_ball()
        end)
    roulette.roll_finished
        :subscribe(function(n)
            local win_amount = roulette_table.data:get_return(n)
            money = money + win_amount
            total_bid = 0
            roulette_table:clear_bids()
            add_to_log("+" .. win_amount)
            tracker:register(n)
        end)

    roulette_table = RouletteTable.new()
    roulette_table:resize(positioning.roulette_table.cell_size)

    log_font = love.graphics.newFont(20)
end

---@class Box
---@field pos Vector
---@field size Vector

---@param box_size Vector
---@param space Box
---@return Box
local function center_box_in_space(box_size, space)
    return {
        pos = (space.pos + space.size / 2) - box_size / 2,
        size = box_size
    }
end

---@param available_size Vector
---@param aspect_ratio Vector
---@return Vector
local function find_size_for_aspect_ratio(available_size, aspect_ratio)
    local ar = aspect_ratio.y / aspect_ratio.x
    local width = available_size.x
    local estimated_height = width * ar
    if estimated_height > available_size.y then
        return Vector.new(available_size.y / ar, available_size.y)
    else
        return Vector.new(width, estimated_height)
    end
end

function get_positioning()
    local roulette_start = 0
    local split = 0.3
    local table_start = win.x * split

    local table_space_box = {
        pos = Vector.new(table_start, 0),
        size = Vector.new(win.x - table_start, win.y),
    }
    local table_cell_size = Vector.new(14, 5)
    local table_size = find_size_for_aspect_ratio(table_space_box.size, table_cell_size)
    local table_box = center_box_in_space(table_size, table_space_box)
    local cell_size = (table_size / table_cell_size).x

    return {
        roulette = Vector.new((table_start - roulette_start) / 2, win.y / 2),
        roulette_table = {
            cell_size = cell_size,
            pos = table_box.pos
        }
    }
end

---@type nil|Vector
local hover_pos = nil

function love.mousereleased(x, y, button)
    local positioning = get_positioning()
    local mouse = Vector.new(x, y)
    if button == 1 then
        local cell = roulette_table:get_cell(mouse - positioning.roulette_table.pos)
        if roulette.rolling then
            return
        end
        if cell == nil then
            return
        end
        local bid_size = 10
        if money >= bid_size then
            roulette_table:add_bid(cell, bid_size)
            money = money - bid_size
            total_bid = total_bid + bid_size
            user_bidded(nil)
        end
    end
end

function love.mousemoved()
    local positioning = get_positioning()

    local cell = roulette_table:get_cell(Vector.new(love.mouse.getPosition()) - positioning.roulette_table.pos)
    if cell ~= nil then
        --print(unpack(cell))
        hover_pos = roulette_table:get_cell_center(cell)
    else
        --print(cell)
        hover_pos = nil
    end
end

function love.touchreleased()
    hover_pos = nil
end

function love.update(dt)
    scheduler:update(dt)

    if fast_debug then
        for _ = 1, 1000 do
            roulette:update(0.016)
        end
    else
        roulette:update(dt)
    end
    local number = roulette:get_position()
    roulette_table:set_highlight(number)
end

function love.resize()
    win = LoveUtils.get_win_shape()

    local positioning = get_positioning()
    roulette_table:resize(positioning.roulette_table.cell_size)
end

function love.draw()
    local positioning = get_positioning()

    love.graphics.push()
    love.graphics.translate(positioning.roulette:unpack())
    local meter_to_pix = win.x / 400
    love.graphics.scale(meter_to_pix, meter_to_pix)
    roulette:draw()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(positioning.roulette_table.pos:unpack())
    roulette_table:draw()
    love.graphics.setColor(1, 1, 1, 0.3)
    if hover_pos ~= nil then
        love.graphics.circle("fill", hover_pos.x, hover_pos.y, 20)
    end
    love.graphics.pop()

    local transaction_log_str = "money: $" .. money .. "\n" .. "log: \n"
    for i = math.max(1, #transaction_log - 10), #transaction_log do
        local transaction = transaction_log[i]
        transaction_log_str = transaction_log_str .. transaction .. "\n"
    end

    love.graphics.setFont(log_font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(transaction_log_str)

    love.graphics.push()
    love.graphics.translate(win.x / 4, 0)
    tracker:draw()
    love.graphics.pop()
end
