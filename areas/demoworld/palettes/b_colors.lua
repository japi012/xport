require "source.graphics.palette"
return Palette.list({
    [Cell.Wall] = col255(54, 63, 105),
    [Cell.Box] = Palette.gradientHSV(col255(95, 50, 225), col255(43, 6, 100), 6),
    [Cell.Origin] = {
        default = Palette.gradientHSV(col255(110, 90, 255), col255(87, 45, 200), 6),
        player = col(1, 1, 1)
    },
    background = col255(13, 13, 26),
    levelFill = col255(25, 25, 45),
    levelStroke = col255(0, 0, 255),
    levelTransition = col255(95, 75, 225)
})
