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

function love.load()
    win = LoveUtils.get_win_shape()
    love.window.setMode(win.x, win.y, {
        resizable = true,
        fullscreen = false
    })
    roulette = Roulette.new()
    roulette.roll_finished
        :startWith(nil)
        :delay(5, scheduler)
        :subscribe(function(n)
            roulette_table:start()
            for _, bid in ipairs(roulette_table.data.bids) do
                print(bid.amount, #bid.numbers)
            end
            roulette:throw_ball()
        end)
    roulette.roll_finished
        :subscribe(function(n)
            money = money + roulette_table.data:get_return(n)
            roulette_table:clear_bids()
            money = money - 10
            roulette_table:add_bid({ "even", 1 }, 10)
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

local hover_pos = Vector.new_zero()

function love.update(dt)
    local positioning = get_positioning()

    scheduler:update(dt)

    --for _ = 1, 100000 do
    --end
    roulette:update(dt)
    local cell = roulette_table:get_cell(Vector.new(love.mouse.getPosition()) - positioning.roulette_table)
    if cell ~= nil then
        print(unpack(cell))
        hover_pos = roulette_table:get_cell_center(cell)
    else
        print(cell)
    end
end

function love.resize()
    win = LoveUtils.get_win_shape()
end

function love.draw()
    local positioning = get_positioning()
    love.graphics.print(money, 0, 0)

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
    love.graphics.circle("fill", hover_pos.x, hover_pos.y, 20)
    love.graphics.pop()
end
