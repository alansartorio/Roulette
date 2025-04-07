local rx = require("lib/reactivex")
local Vector = require("vector")

---@class Split
---@field text string
---@field angle number
---@field split_angle number
---@field fixture love.Fixture

---@class Roulette
---@field world love.World
---@field ball love.Fixture
---@field center love.Fixture
---@field roulette love.Fixture
---@field splits Split[]
---@field ball_center_collisions Subject
---@field roll_finished Observable
---@field scheduler CooperativeScheduler
---@field roulette_angle number
local Roulette = {}
Roulette.__index = Roulette

function Roulette.new()
    local new = setmetatable({}, Roulette)

    new.scheduler = rx.CooperativeScheduler.create()


    new.world = love.physics.newWorld(0, 0, true)
    new.world:setCallbacks(
        function(a, b, coll)
            local a_data = a:getUserData()
            local b_data = b:getUserData()
            if (a_data == "Ball" and b_data == "Center") or
                (b_data == "Ball" and a_data == "Center") then
                new.ball_center_collisions(new:get_position())
            end
        end,
        function(a, b, coll)
            local a_data = a:getUserData()
            local b_data = b:getUserData()
            if (a_data == "Ball" and b_data == "Center") or
                (b_data == "Ball" and a_data == "Center") then
                new.ball_center_collisions(nil)
            end
        end
    )

    local function create_roulette()
        local circleShape = love.physics.newCircleShape(1)
        local circleBody = love.physics.newBody(new.world, 0, 0, "static")
        new.roulette = love.physics.newFixture(circleBody, circleShape)

        local centerRadius = 30

        local centerShape = love.physics.newCircleShape(centerRadius)
        local centerBody = love.physics.newBody(new.world, 0, 0, "static")
        new.center = love.physics.newFixture(centerBody, centerShape)
        new.center:setRestitution(0.5)
        new.center:setUserData("Center")

        new.splits = {}

        ---@param text string
        ---@param position integer
        ---@param total integer
        local function add_split(text, position, total)
            local split_angle = ((position + 1) / total) * math.pi * 2
            local angle = ((position + 0.5) / total) * math.pi * 2
            local size = Vector.new(5, 2)
            local start = Vector.new(centerRadius + size.x / 2, 0):rotate(split_angle)

            local shape = love.physics.newPolygonShape(-size.x / 2, size.y / 2, size.x / 2, 0, -size.x / 2, -size.y / 2)
            --local shape = love.physics.newRectangleShape(0, 0, size.x, size.y)
            local body = love.physics.newBody(new.world, start.x, start.y, "static")
            body:setAngle(split_angle)
            local fixture = love.physics.newFixture(body, shape)
            table.insert(new.splits, {
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

        local ballBody = new.ball:getBody()

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
        local ballBody = love.physics.newBody(new.world, 40, 0, "dynamic")

        ballBody:setLinearDamping(0.1)

        new.ball = love.physics.newFixture(ballBody, ballShape)
        new.ball:setRestitution(0.5)
        new.ball:setUserData("Ball")
    end

    create_ball()
    create_roulette()

    new.roulette_angle = 0

    new.ball_center_collisions = rx.Subject.create()

    new.roll_finished = new.ball_center_collisions
        :distinctUntilChanged()
        :debounce(1, new.scheduler)
        :filter(function(v) return v ~= nil end)

    return new
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

function Roulette:throw_ball()
    local speed = love.math.random(2000, 3000)
    local angle = love.math.random(0, math.pi * 2)
    local position = Vector.new_polar(40, angle)
    local velocity = Vector.new_polar(speed, angle + math.pi / 2)
    self.ball:getBody():setLinearVelocity(velocity:unpack())
    self.ball:getBody():setPosition(position:unpack())
end

function Roulette:update(dt)
    self.roulette_angle = self.roulette_angle + dt
    self.scheduler:update(dt)

    local function apply_force()
        ---@type Vector
        local pos = Vector.zero - Vector.new(self.ball:getBody():getPosition()):normalized() * 0.5

        self.ball:getBody():applyForce(pos:unpack())
    end

    apply_force()
    self.world:update(dt)
end

function Roulette:draw()
    local meter_to_pix = 7
    love.graphics.scale(meter_to_pix, meter_to_pix)
    --love.graphics.rotate(roulette_angle)
    love.graphics.setLineWidth(0.1)
    love.graphics.setColor(255, 255, 255)

    -- roulette
    love.graphics.circle("line", 0, 0, 50)

    love.graphics.setColor(255, 0, 0)
    physic_draw.draw_circle(self.ball, "fill")

    love.graphics.setColor(0, 255, 255)
    for i, split in ipairs(self.splits) do
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

function Roulette:get_position()
    local ball_angle = Vector.new(self.ball:getBody():getPosition()):angle() % (math.pi * 2)
    for i, slit in ipairs(self.splits) do
        if ball_angle < slit.split_angle then
            --print(slit.text)
            return slit.text
        end
    end
end

return Roulette
