local love = require "love"
if Sounds ~= nil then return Sounds end

Sounds = {}

local function playSound(sound, isMusic, loop)
    sound.audio:stop()
    sound.audio:setPitch(math.random() * (sound.variation * 2) + (1 - sound.variation))
    sound.audio:setVolume(sound.volume * (isMusic and state.musicVolume or state.sfxVolume))
    sound.audio:setLooping((loop ~= nil) and loop or (sound.loop))
    sound.audio:play()
end

local function newSound(filename, volume, variation, loop)
    return {
        audio = love.audio.newSource("sounds/" .. filename, "stream"),
        variation = variation or 0.1,
        volume = volume or 0.25,
        loop = (loop ~= nil) and loop or false,
        play = playSound
    }
end

Sounds.move = newSound("sfx_move.wav")
Sounds.moveFail = newSound("sfx_move-fail.wav")
Sounds.undo = newSound("sfx_undo.wav", 0.2, 0.2)
Sounds.hoverUI = newSound("sfx_menu-hover.wav")
Sounds.teleport = newSound("sfx_teleport.wav", 0.4, 0.05)
Sounds.levelStart = newSound("sfx_level-start.wav", nil, 0.25)
Sounds.levelRestart = newSound("sfx_level-restart.wav", nil, 0.05)
Sounds.levelComplete = newSound("sfx_level-complete.wav", nil, 0)

return Sounds
