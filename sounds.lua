local love = require "love"
if Sounds ~= nil then return Sounds end

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
        audio = love.audio.newSource("sounds/" .. filename, "stream"),
        variation = variation or 0.1,
        volume = volume or 0.25,
        loop = (loop ~= nil) and loop or false,
        play = playSound
    }
end

local function newMusic(filename, volume)
    return {
        filename = filename,
        audio = love.audio.newSource("music/" .. filename, "stream"),
        variation = 0,
        volume = volume or 0.25,
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
        print(state.currentMusic.filename)
        print(music.filename)
        state.currentMusic.fading = true
        local startingVolume = state.musicVolume
        local currentMusic = state.currentMusic
        local fadeOutAnim = Animation.new(
            duration, function(self, progress)
                local progress = easeOutCubic(progress)
                currentMusic.audio:setVolume((1 - progress) * startingVolume)
            end, nil, function()
                currentMusic.audio:setVolume(0)
                currentMusic.audio:stop()
            end
        )
        state.currentMusic = music
        local fadeInAnim = Animation.new(
            duration, function(self, progress)
                local progress = easeOutCubic(progress)
                music.audio:setVolume(progress * state.musicVolume)
            end, function()
                playSound(music, true, true)
                music.fading = true
                currentMusic.fading = false
                music.audio:setVolume(0.0)
            end, function()
                music.audio:setVolume(state.musicVolume)
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
                music.audio:setVolume(progress * state.musicVolume)
            end, function()
                playSound(music, true, true)
                music.fading = true
                music.audio:setVolume(0.0)
            end, function()
                music.audio:setVolume(state.musicVolume)
                state.currentMusic = music
                music.fading = false
            end
        )
        Animation.start(fadeInAnim)
    end
end

function Music.update(dt)
    if state.currentMusic and not state.currentMusic.fading
        and state.currentMusic.audio:getVolume() ~= state.musicVolume then
        state.currentMusic.audio:setVolume(state.musicVolume)
    end
end

Sounds.move = newSound("sfx_move.wav")
Sounds.moveFail = newSound("sfx_move-fail.wav")
Sounds.undo = newSound("sfx_undo.wav", 0.2, 0.2)
Sounds.hoverUI = newSound("sfx_menu-hover.wav")
Sounds.selectUI = newSound("sfx_menu-select.wav")
Sounds.teleport = newSound("sfx_teleport.wav", 0.4, 0.05)
Sounds.levelStart = newSound("sfx_level-start.wav", nil, 0.01)
Sounds.levelRestart = newSound("sfx_level-restart.wav", nil, 0.05)
Sounds.levelComplete = newSound("sfx_level-complete.wav", nil, 0)

Music.menu = newMusic("mus_menu.ogg", nil, 0, true)
Music.secret = newMusic("mus_secret.ogg", nil, 0, true)
Music.level1 = newMusic("mus_level1.ogg", nil, 0, true)
Music.level2 = newMusic("mus_level2.ogg", nil, 0, true)
Music.level3 = newMusic("mus_level3.ogg", nil, 0, true)
Music.level4 = newMusic("mus_level4.ogg", nil, 0, true)
Music.level5 = newMusic("mus_level5.ogg", nil, 0, true)
Music.challenge1 = newMusic("mus_challenge1.ogg", nil, 0, true)
Music.challenge2 = newMusic("mus_challenge2.ogg", nil, 0, true)
Music.challenge3 = newMusic("mus_challenge3.ogg", nil, 0, true)

return Sounds
