local rx = require("lib/reactivex")
local Vector = require("vector")
local LoveUtils = require("love-utils")
local Roulette = require("roulette")

---@type Vector
local win

---@type Roulette
local roulette

function love.load()
    win = LoveUtils.get_win_shape()
    love.window.setMode(win.x, win.y, {
        resizable = true,
        fullscreen = false
    })
    roulette = Roulette.new()
    roulette.roll_finished:subscribe(function(n)
        print(n)
        roulette:throw_ball()
    end)

    roulette:throw_ball()
end

function love.update(dt)
    --for _ = 1, 100000 do
    --end
    roulette:update(dt)
end

function love.resize()
    win = LoveUtils.get_win_shape()
end

function love.draw()
    love.graphics.translate(win.x / 2, win.y / 2)
    roulette:draw()
end
