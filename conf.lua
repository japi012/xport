local love = require "love"

function love.conf(t)
    t.version = "11.5"
    t.title = "XPORT"
    t.console = true

    t.window.width = 1024
    t.window.height = 768
    t.window.resizable = true
    t.window.minwidth = 400
    t.window.minheight = 300
end
