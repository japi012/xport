require "source.graphics.palette"
return Palette.list({
    [Cell.Wall] = col255(0, 0, 0),
    [Cell.Box] = Palette.gradientHSV(col255(230, 17, 47), col255(153, 6, 20), 6),
    [Cell.Origin] = {
        default = Palette.gradientHSV(col255(130, 27, 51), col255(70, 7, 20), 6),
        player = col(1, 1, 1)
    },
    background = col255(29, 1, 6),
    levelFill = col255(51, 3, 8),
    levelStroke = col255(255, 0, 0),
})
