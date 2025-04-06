local rx = require("lib/reactivex")
local Vector = require("vector")
local LoveUtils = require("love-utils")

---@type love.World
local world

---@type love.Fixture
local roulette
---@type love.Fixture
local ball

---@class Split
---@field text string
---@field angle number
---@field split_angle number
---@field fixture love.PolygonShape

---@type Split[]
local splits

---@type Vector
local win

local roulette_angle
local scheduler = rx.CooperativeScheduler.create()
---@type Subject
local ball_center_collisions = rx.Subject.create()
--ball_center_collisions:subscribe(
    --function(n)
        --print("v", n)
    --end
--)
---@type Observable
local roll_finished = ball_center_collisions
    :distinctUntilChanged()
    :debounce(1, scheduler)
    :filter(function(v) return v ~= nil end)
roll_finished:subscribe(function(n)
    print("finished", n)
    throw_ball()
end)

function get_position()
    local ball_angle = Vector.new(ball:getBody():getPosition()):angle()
    for i, slit in ipairs(splits) do
        if ball_angle < slit.split_angle then
            return slit.text
        end
    end
end

function throw_ball()
    local speed = love.math.random(1000, 2000)
    ball:getBody():setLinearVelocity(0, speed)
    ball:getBody():setPosition(40, 0)
end

function love.load()
    win = LoveUtils.get_win_shape()
    love.window.setMode(win.x, win.y, {
        resizable = true,
        fullscreen = false
    })
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(
        function(a, b, coll)
            local a_data = a:getUserData()
            local b_data = b:getUserData()
            if (a_data == "Ball" and b_data == "Center") or
                (b_data == "Ball" and a_data == "Center") then
                ball_center_collisions(get_position())
            end
        end,
        function(a, b, coll)
            local a_data = a:getUserData()
            local b_data = b:getUserData()
            if (a_data == "Ball" and b_data == "Center") or
                (b_data == "Ball" and a_data == "Center") then
                ball_center_collisions(nil)
            end
        end
    )

    ---@param ball love.Fixture
    local function create_roulette()
        local circleShape = love.physics.newCircleShape(1)
        local circleBody = love.physics.newBody(world, 0, 0, "static")
        roulette = love.physics.newFixture(circleBody, circleShape)

        local centerRadius = 30

        local centerShape = love.physics.newCircleShape(centerRadius)
        local centerBody = love.physics.newBody(world, 0, 0, "static")
        center = love.physics.newFixture(centerBody, centerShape)
        center:setRestitution(1)
        center:setUserData("Center")

        splits = {}

        ---@param text string
        ---@param position integer
        ---@param total integer
        local function add_split(text, position, total)
            print(text, position, total)
            local split_angle = ((position + 1) / total) * math.pi * 2
            local angle = ((position + 0.5) / total) * math.pi * 2
            local size = Vector.new(5, 1)
            local start = Vector.new(centerRadius + size.x / 2, 0):rotate(split_angle)

            --local shape = love.physics.newRectangleShape(start.x, start.y, 0.01, 0.001, angle)
            local shape = love.physics.newRectangleShape(0, 0, size.x, size.y)
            local body = love.physics.newBody(world, start.x, start.y, "static")
            body:setAngle(split_angle)
            local fixture = love.physics.newFixture(body, shape)
            table.insert(splits, {
                text = text,
                angle = angle,
                split_angle = split_angle,
                fixture = fixture
            })
        end

        local numbers = 36

        add_split("00", 0, numbers + 2)
        for i = 0, numbers do
            add_split(tostring(i), i + 1, numbers + 2)
        end

        local ballBody = ball:getBody()

        local joint = love.physics.newRopeJoint(
            circleBody,
            ballBody,
            circleBody:getX(),
            circleBody:getY(),
            ballBody:getX(),
            ballBody:getY(),
            50)
    end


    local function create_ball()
        local ballShape = love.physics.newCircleShape(1.3)
        local ballBody = love.physics.newBody(world, 40, 0, "dynamic")

        ballBody:setLinearDamping(0.1)

        ball = love.physics.newFixture(ballBody, ballShape)
        ball:setRestitution(1)
        ball:setUserData("Ball")
    end

    create_ball()
    create_roulette()

    roulette_angle = 0

    throw_ball()
end

function apply_force()
    ---@type Vector
    local pos = Vector.zero - Vector.new(ball:getBody():getPosition()):normalized() * 0.3

    ball:getBody():applyForce(pos:unpack())
end

function love.update(dt)
    scheduler:update(dt)
    roulette_angle = roulette_angle + dt
    apply_force()
    world:update(dt)
end

function love.resize()
    win = LoveUtils.get_win_shape()
end

local physic_draw = {}

---@param fixture love.Fixture
---@param mode "fill"|"line"
function physic_draw.draw_circle(fixture, mode)
    local x, y = fixture:getBody():getPosition()
    local r = fixture:getShape():getRadius()
    love.graphics.circle(mode, x, y, r)
end

---@param fixture love.Fixture
---@param mode "fill"|"line"
function physic_draw.draw_rect(fixture, mode)
    ---@type love.PolygonShape
    local shape = fixture:getShape()
    local pts = { shape:getPoints() }

    love.graphics.push()
    love.graphics.translate(fixture:getBody():getPosition())
    love.graphics.rotate(fixture:getBody():getAngle())
    love.graphics.polygon(mode, pts)
    love.graphics.pop()
end

function love.draw()
    love.graphics.translate(win.x / 2, win.y / 2)
    local meter_to_pix = 4
    love.graphics.scale(meter_to_pix, meter_to_pix)
    --love.graphics.rotate(roulette_angle)
    love.graphics.setLineWidth(0.1)
    love.graphics.setColor(255, 255, 255)

    -- roulette
    love.graphics.circle("line", 0, 0, 50)

    love.graphics.setColor(255, 0, 0)
    physic_draw.draw_circle(ball, "fill")

    love.graphics.setColor(0, 255, 255)
    for i, split in ipairs(splits) do
        local text_width = 50
        local text_scale = 0.2
        local text_height = love.graphics.getFont():getHeight()
        love.graphics.push()
        love.graphics.rotate(split.angle)
        love.graphics.translate(30, 0)
        love.graphics.rotate(math.pi / 2)
        --local pos = Vector.new(30, 0):rotate(split.angle) - Vector.new(text_width * text_scale / 2, 0)
        love.graphics.printf(split.text, 0, 0, text_width, "center", 0, 0.2, 0.2, text_width / 2, text_height / 2)
        --love.graphics.printf(split.text, pos.x, pos.y, text_width, "center", math.pi / 2, 0.2, 0.2, 0, text_height / 2)
        love.graphics.pop()
        physic_draw.draw_rect(split.fixture, "fill")
    end
end
