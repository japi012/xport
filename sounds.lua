local love = require "love"
if Sounds ~= nil then return Sounds end

Sounds = {}

local function playSound(sound)
    sound.audio:stop()
    sound.audio:setPitch(math.random() * (sound.variation * 2) + (1 - sound.variation))
    sound.audio:setVolume(sound.volume * state.sfxVolume)
    sound.audio:play()
end

local function newSound(filename, volume, variation)
    return {
        audio = love.audio.newSource("sounds/" .. filename, "stream"),
        variation = variation or 0.1,
        volume = volume or 0.25,
        play = playSound
    }
end

Sounds.move = newSound("sfx_move.wav")
Sounds.moveFail = newSound("sfx_move-fail.wav")
Sounds.undo = newSound("sfx_undo.wav", 0.2, 0.2)
Sounds.hoverUI = newSound("sfx_menu-hover.wav")
Sounds.teleport = newSound("sfx_teleport.wav", 0.4, 0.05)
Sounds.restart = newSound("sfx_restart.wav", nil, 0.05)
Sounds.complete = newSound("sfx_level-complete.wav")

return Sounds
