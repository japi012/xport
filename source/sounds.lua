if Sounds ~= nil then return Sounds end
local love = require "love"

Sounds = {}
Music = {}

local function playSound(sound, isMusic, loop)
    sound.audio:stop()
    sound.audio:setPitch(math.random() * (sound.variation * 2) + (1 - sound.variation))
    sound.audio:setVolume(sound.volume * (isMusic and state.musicVolume or state.sfxVolume))
    sound.audio:setLooping((loop ~= nil) and loop or (sound.loop))
    sound.audio:play()
end

local function newSound(filename, volume, variation, loop)
    return {
        audio = love.audio.newSource("sounds/" .. filename, "static"),
        variation = variation or 0.1,
        volume = volume or 0.25,
        loop = (loop ~= nil) and loop or false,
        play = playSound
    }
end

local function newMusic(filename, volume)
    return {
        filename = filename,
        audio = love.audio.newSource("music/" .. filename, "static"),
        variation = 0,
        volume = volume or 1,
        loop = true,
        play = playSound
    }
end

function Music.play(music, duration)
    local duration = duration or 1
    for k, m in pairs(Music) do
        if type(m) == "table" and m.fading then
            m.audio:stop()
        end
    end
    if state.currentMusic then
        state.currentMusic.fading = true
        local startingVolume = state.musicVolume * state.currentMusic.volume
        local currentMusic = state.currentMusic
        local fadeOutAnim = Animation.new(
            duration, function(self, progress)
                local progress = easeOutCubic(progress)
                currentMusic.audio:setVolume((1 - progress) * startingVolume)
            end, nil, function()
                currentMusic.audio:setVolume(0.0)
                currentMusic.audio:stop()
            end
        )
        state.currentMusic = music
        local fadeInAnim = Animation.new(
            duration, function(self, progress)
                local progress = easeOutCubic(progress)
                music.audio:setVolume(progress * state.musicVolume * music.volume)
            end, function()
                playSound(music, true, true)
                music.fading = true
                currentMusic.fading = false
                music.audio:setVolume(0.0)
            end, function()
                music.audio:setVolume(state.musicVolume * music.volume)
                state.currentMusic = music
                music.fading = false
            end
        )
        Animation.start(fadeOutAnim)
        Animation.delayedStart(duration / 2, fadeInAnim)
    else
        state.currentMusic = music
        local fadeInAnim = Animation.new(
            duration * 2, function(self, progress)
                local progress = easeOutCubic(progress)
                music.audio:setVolume(progress * state.musicVolume * music.volume)
            end, function()
                playSound(music, true, true)
                music.fading = true
                music.audio:setVolume(0.0)
            end, function()
                music.audio:setVolume(state.musicVolume * music.volume)
                state.currentMusic = music
                music.fading = false
            end
        )
        Animation.start(fadeInAnim)
    end
end

function Music.update(dt)
    if state.currentMusic and not state.currentMusic.fading
        and state.currentMusic.audio:getVolume() ~= (state.musicVolume * state.currentMusic.volume) then
        state.currentMusic.audio:setVolume(state.musicVolume * state.currentMusic.volume)
    end
end

Sounds.move = newSound("sfx_move.wav")
Sounds.moveFail = newSound("sfx_move-fail.wav")
Sounds.undo = newSound("sfx_undo.wav", 0.2, 0.2)
Sounds.hoverUI = newSound("sfx_menu-hover.wav")
Sounds.selectUI = newSound("sfx_menu-select.wav")
Sounds.teleport = newSound("sfx_teleport.wav", 0.4, 0.05)
Sounds.originMove = newSound("sfx_spawnpoint-move.wav", 0.4, 0.05)
Sounds.levelStart = newSound("sfx_level-start.wav", nil, 0.01)
Sounds.levelRestart = newSound("sfx_level-restart.wav", nil, 0.05)
Sounds.levelComplete = newSound("sfx_level-complete.wav", nil, 0)

Music.menu = newMusic("mus_menu.ogg", nil)
Music.secret = newMusic("mus_secret.ogg", 0.5)
Music.level1 = newMusic("mus_level1.ogg", nil)
Music.level2 = newMusic("mus_level2.ogg", nil)
Music.level3 = newMusic("mus_level3.ogg", nil)
Music.level4 = newMusic("mus_level4.ogg", nil)
Music.level5 = newMusic("mus_level5.ogg", nil)
Music.challenge1 = newMusic("mus_challenge1.ogg", nil)
Music.challenge2 = newMusic("mus_challenge2.ogg", nil)
Music.challenge3 = newMusic("mus_challenge3.ogg", nil)

return Sounds
