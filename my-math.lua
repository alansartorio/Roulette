local my_math = {}

function my_math.round(n)
    --local floor = math.floor(n)
    --local frac = n - floor
    --if frac < 0.5 then
        --return floor
    --else
        --return floor + 1
    --end
    return math.floor(n + 0.5)
end

function my_math.lerp(a, b, n)
    return a + (b - a) * n
end


return my_math
