local my_math = require("my-math")

---@class Vector
---@field x number
---@field y number
local Vector = {}
Vector.__index = Vector

---@param x number
---@param y number
---@return Vector
function Vector.new(x, y)
    local new = setmetatable({}, Vector)
    new.x = x
    new.y = y
    return new
end

---@param length number
---@param angle number
---@return Vector
function Vector.new_polar(length, angle)
    return Vector.from_angle(angle) * length
end

---@param angle number
---@return Vector
function Vector.from_angle(angle)
    return Vector.new(math.cos(angle), math.sin(angle))
end

function Vector.new_zero()
    return Vector.new(0, 0)
end

---@param other number|Vector
---@return Vector
function Vector:__add(other)
    if type(other) == "number" then
        return Vector.new(self.x + other, self.y + other)
    elseif type(other) == "table" and getmetatable(other) == Vector then
        return Vector.new(self.x + other.x, self.y + other.y)
    end
end

---@param other number|Vector
---@return Vector
function Vector:__sub(other)
    if type(other) == "number" then
        return Vector.new(self.x - other, self.y - other)
    elseif type(other) == "table" and getmetatable(other) == Vector then
        return Vector.new(self.x - other.x, self.y - other.y)
    end
end

---@param other number|Vector
---@return Vector
function Vector:__mul(other)
    if type(other) == "number" then
        return Vector.new(self.x * other, self.y * other)
    elseif type(other) == "table" and getmetatable(other) == Vector then
        return Vector.new(self.x * other.x, self.y * other.y)
    end
end

---@param other number|Vector
---@return Vector
function Vector:__div(other)
    if type(other) == "number" then
        return Vector.new(self.x / other, self.y / other)
    elseif type(other) == "table" and getmetatable(other) == Vector then
        return Vector.new(self.x / other.x, self.y / other.y)
    end
end

---@param other Vector
---@return number
function Vector:dot(other)
    assert(type(other) == "table" and getmetatable(other) == Vector)
    return self.x * other.x + self.y * other.y
end

---@return Vector
function Vector:rot_90_ccw()
    return Vector.new(self.y, -self.x)
end

---@return Vector
function Vector:rot_90_cw()
    return Vector.new(-self.y, self.x)
end

---@return number
function Vector:length_sq()
    return self.x * self.x + self.y * self.y
end

---@return number
function Vector:length()
    return math.sqrt(self:length_sq())
end

---@return Vector
function Vector:normalized()
    return self / self:length()
end

---@param fun function
---@return Vector
function Vector:map(fun)
    return Vector.new(fun(self.x), fun(self.y))
end

---@return Vector
function Vector:floor()
    return self:map(math.floor)
end

---@return Vector
function Vector:ceil()
    return self:map(math.ceil)
end

---@return number
function Vector:angle()
    return math.atan2(self.y, self.x)
    --return math.atan(self.y, self.x)
end

---@param angle number
---@return Vector
function Vector:rotate(angle)
    return Vector.new_polar(self:length(), self:angle() + angle)
end

---@return Vector
function Vector:round()
    return self:map(my_math.round)
end

---@param min Vector
---@param max Vector
---@return boolean
function Vector:is_inside_rect(min, max)
    return self.x > min.x and
            self.x <= max.x and
            self.y > min.y and
            self.y <= max.y
end

---@param other Vector
---@return Vector
function Vector:min(other)
    return Vector.new(math.min(self.x, other.x), math.min(self.y, other.y))
end

---@param other Vector
---@return Vector
function Vector:max(other)
    return Vector.new(math.max(self.x, other.x), math.max(self.y, other.y))
end

---@return string
function Vector:__tostring()
    return "(" .. self.x .. ", " .. self.y .. ")"
end

function Vector:unpack()
    return self.x, self.y
end

Vector.zero = Vector.new_zero()

return Vector
