local rx = require("lib/reactivex")
local Vector = require("vector")
local LoveUtils = require("love-utils")
local Roulette = require("roulette")
local RouletteTable = require("roulette-table")

---@type Vector
local win

---@type Roulette
local roulette
---@type RouletteTable
local roulette_table

local scheduler = rx.CooperativeScheduler.create()
local money = 1000
local total_bid = 0
local transaction_log = {}
local user_bidded = rx.Subject.create()

local function add_to_log(transaction)
    table.insert(transaction_log, tostring(transaction))
end

function love.load()
    win = LoveUtils.get_win_shape()
    love.window.setMode(win.x, win.y, {
        resizable = true,
        fullscreen = false
    })
    roulette = Roulette.new()
    roulette.roll_finished
        :startWith(nil)
        :merge(user_bidded)
        :tap(function ()
            print("A")
        end)
        :debounce(5, scheduler)
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
        end)

    roulette_table = RouletteTable.new()
end

function get_positioning()
    local roulette_start = 0
    local split = 0.3
    local table_start = win.x * split

    return {
        roulette = Vector.new((table_start - roulette_start) / 2, win.y / 2),
        roulette_table = Vector.new(table_start, 0)
    }
end

---@type nil|Vector
local hover_pos = nil

function love.mousereleased(x, y, button)
    local positioning = get_positioning()
    local mouse = Vector.new(x, y)
    if button == 1 then
        local cell = roulette_table:get_cell(mouse - positioning.roulette_table)
        if roulette.rolling then
            return
        end
        if cell == nil then
            return
        end
        local bid_size = 10
        roulette_table:add_bid(cell, bid_size)
        money = money - bid_size
        total_bid = total_bid + bid_size
        user_bidded(nil)
    end
end

function love.update(dt)
    local positioning = get_positioning()

    scheduler:update(dt)

    --for _ = 1, 100000 do
    --end
    roulette:update(dt)
    local cell = roulette_table:get_cell(Vector.new(love.mouse.getPosition()) - positioning.roulette_table)
    if cell ~= nil then
        --print(unpack(cell))
        hover_pos = roulette_table:get_cell_center(cell)
    else
        --print(cell)
        hover_pos = nil
    end
    local number = roulette:get_position()
    roulette_table:set_highlight(number)
end

function love.resize()
    win = LoveUtils.get_win_shape()
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
    love.graphics.translate(positioning.roulette_table:unpack())
    roulette_table:draw()
    love.graphics.setColor(1, 1, 1, 0.3)
    if hover_pos ~= nil then
        love.graphics.circle("fill", hover_pos.x, hover_pos.y, 20)
    end
    love.graphics.pop()

    local transaction_log_str = "money: " .. money .. "\nlog: \n"
    for _, transaction in ipairs(transaction_log) do
        transaction_log_str = transaction_log_str .. transaction .. "\n"
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(transaction_log_str)
end
