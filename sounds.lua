local love = require "love"
if Sounds ~= nil then return Sounds end

Sounds = {}

function Sounds.play(sound, variation)
    variation = variation or 0.1
    sound:stop()
    sound:setPitch(math.random() * (variation * 2) + (1 - variation))
    sound:play()
end

Sounds.move = love.audio.newSource("sounds/sfx_move.wav", "stream")
Sounds.move:setVolume(0.25)

Sounds.moveFail = love.audio.newSource("sounds/sfx_move-fail.wav", "stream")
Sounds.moveFail:setVolume(0.25)

return Sounds
