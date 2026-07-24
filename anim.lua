Animation = {}
animations = {}

-- `duration` is the duration in seconds
-- `draw` is the function that draws the animation, takes the animation itself and progess from 0 to 1
-- `onStart` is called when the animation is first run
-- `finalCallback` is called when the animation is done running
-- `chain` is another animation run when the animation is done running
function Animation.new(duration, draw, onStart, finalCallback, chain)
    return {
        startTime = nil,
        duration = duration,
        draw = draw or function() end,
        finalCallback = finalCallback or function() end,
        onStart = onStart or function() end,
        progress = 0,
        dt = 0,
        chain = chain,
        stop = false
    }
end

function Animation.start(animation)
    animation.startTime = love.timer.getTime()
    table.insert(animations, animation)

    animation:onStart()
end

function Animation.chainLoop(...)
    local chain = {...}
    for i, animation in ipairs(chain) do
        if i < #chain then
            animation.chain = chain[i + 1]
        elseif i == #chain then
            animation.chain = chain[1]
        end
    end

    return chain[1]
end

function Animation.chained(...)
    local chain = {...}
    for i, animation in ipairs(chain) do
        if i < #chain then
            animation.chain = chain[i + 1]
        end
    end

    return chain[1]
end

function updateAnimations(dt)
    local deleteAnimations = {}
    for i, animation in ipairs(animations) do
        if animation then
            animation.progress = (love.timer.getTime() - animation.startTime) / animation.duration
            animation.dt = dt
            if animation.progress >= 1 or animation.stop then
                animation:finalCallback()
                table.insert(deleteAnimations, animation)

                if animation.chain then
                    Animation.start(animation.chain)
                end
            end
        end
    end

    local newAnimations = {}
    for _, animation in ipairs(animations) do
        if not elem(deleteAnimations, animation) then
            table.insert(newAnimations, animation)
        end
    end

    animations = newAnimations
end

function drawAnimations()
    for i, animation in ipairs(animations) do
        if animation then
            animation:draw(animation.progress)
        end
    end
end

-- EASING FUNCTIONS

function easeInOutCubic(t)
    if t < 0.5 then
        return 4 * t ^ 3
    else
        return 1 - (-2 * t + 2) ^ 3 / 2
    end
end

function easeOutCubic(t)
    return 1 - (1 - t) ^ 3
end

function easeInBack(t)
    local c1 = 1.70158;
    local c3 = c1 + 1;

    return c3 * t ^ 3 - c1 * t * t;
end
