local Vector = require("vector")

local LoveUtils = {}

function LoveUtils.get_win_shape()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    return Vector.new(w, h)
end


return LoveUtils
